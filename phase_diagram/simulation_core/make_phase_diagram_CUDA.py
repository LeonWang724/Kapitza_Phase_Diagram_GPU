"""Codex CUDA Port: reproduce the established metric using a saved run manifest."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import tables as tb


def iteration(path: Path) -> int:
    match = re.fullmatch(r"(\d{16})\.h5", path.name)
    return int(match.group(1)) if match else -1


def read_probability(path: Path) -> np.ndarray:
    with tb.open_file(path, "r") as handle:
        real = handle.root.REAL[:]
        imaginary = handle.root.IMAGINARY[:]
    return real * real + imaginary * imaginary


def analyze(manifest_path: Path) -> dict[str, Path]:
    manifest_path = manifest_path.resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("status") != "completed":
        raise RuntimeError("The manifest is not marked completed; refusing partial analysis.")
    root = manifest_path.parent
    grid = manifest["parameter_grid"]
    contract = manifest["analysis_contract"]
    alpha_values = np.asarray(grid["alpha_values"], dtype=np.float64)
    frequency_values = np.asarray(grid["drive_frequency_hz_values"], dtype=np.float64)
    metric = np.full((frequency_values.size, alpha_values.size), np.nan)

    final_count = int(contract["final_snapshot_count"])
    cut = int(contract["cut_points_each_edge"])
    rows = []
    for run in manifest["runs"]:
        if run.get("status") != "completed":
            raise RuntimeError(f"Run {run['run_index']} is incomplete.")
        output_directory = root / run["output_directory"]
        snapshots = sorted(
            (path for path in output_directory.glob("*.h5") if iteration(path) >= 0),
            key=iteration,
        )
        if not snapshots:
            raise FileNotFoundError(f"No snapshots in {output_directory}")
        selected = snapshots[-final_count:]
        values = []
        for snapshot in selected:
            probability = read_probability(snapshot)
            if probability.size <= 2 * cut:
                raise ValueError(f"Spatial cut removes all points from {snapshot}")
            cropped = probability[cut:-cut]
            # CUDA PORT: this is the quantity actually assigned by the latest
            # historical scripts after their standard-deviation value is overwritten.
            values.append(float(np.sum(cropped * cropped)))
        mean_metric = float(np.mean(values))
        alpha_index = int(run["alpha_index"])
        frequency_index = int(run["frequency_index"])
        metric[frequency_index, alpha_index] = mean_metric
        rows.append(
            {
                "run_index": run["run_index"],
                "alpha": run["alpha"],
                "drive_frequency_hz": run["drive_frequency_hz"],
                "snapshots_averaged": len(selected),
                "metric": mean_metric,
            }
        )
        print(
            f"out_{run['run_index']:03d}: alpha={run['alpha']:.10g}, "
            f"frequency={run['drive_frequency_hz']:.10g} Hz, metric={mean_metric:.10g}"
        )

    analysis_directory = root / "analysis"
    analysis_directory.mkdir(exist_ok=True)
    npz_path = analysis_directory / "phase_diagram_metric.npz"
    csv_path = analysis_directory / "phase_diagram_metric.csv"
    image_path = analysis_directory / "phase_diagram_CUDA.png"
    np.savez(
        npz_path,
        alpha_values=alpha_values,
        drive_frequency_hz_values=frequency_values,
        metric_matrix=metric,
    )
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    alpha_mesh, frequency_mesh = np.meshgrid(alpha_values, frequency_values)
    figure, axis = plt.subplots(figsize=(9, 7))
    image = axis.pcolormesh(
        alpha_mesh, frequency_mesh, metric, shading="nearest", cmap=contract["colormap"]
    )
    figure.colorbar(
        image,
        ax=axis,
        label=rf"Mean discrete $\sum_x |\psi(x)|^4$ (last {final_count} snapshots)",
    )
    axis.set_xlabel(r"$\alpha$")
    axis.set_ylabel(r"$\nu_{\mathrm{flo}}$ (Hz)")
    if contract["frequency_axis_inverted"]:
        axis.invert_yaxis()
    axis.set_title(
        rf"Native CUDA Floquet Phase Diagram, $V_0={grid['lattice_depth_v0_er']:g}E_R$"
    )
    figure.tight_layout()
    figure.savefig(image_path, dpi=300, bbox_inches="tight")
    print(f"Saved analysis to {analysis_directory}")
    return {"npz": npz_path, "csv": csv_path, "image": image_path}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="path to run_manifest.json")
    arguments = parser.parse_args()
    analyze(arguments.manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
