"""Codex CUDA Port: shared, non-numerical workflow and provenance helpers."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
from pathlib import Path
from typing import Any


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
PORT_ROOT = SCRIPT_DIRECTORY.parents[1]


def utc_now() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def locate_executable(explicit: Path | None = None) -> Path:
    candidates = []
    if explicit is not None:
        candidates.append(explicit)
    environment_value = os.environ.get("GPE1D_CUDA_EXE")
    if environment_value:
        candidates.append(Path(environment_value))
    candidates.extend(
        [
            PORT_ROOT / "build" / "bin" / "gpe1d_cuda.exe",
            SCRIPT_DIRECTORY / "gpe1d_cuda.exe",
        ]
    )
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if resolved.is_file():
            return resolved
    rendered = "\n".join(f"  - {candidate}" for candidate in candidates)
    raise FileNotFoundError(f"gpe1d_cuda.exe was not found. Checked:\n{rendered}")


def legacy_input_path(filename: str) -> Path:
    candidates = [SCRIPT_DIRECTORY / "in" / filename, SCRIPT_DIRECTORY / f"in\\{filename}"]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(f"Generated input {filename!r} was not found.")


def read_config(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", ";")) or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def update_config(path: Path, updates: dict[str, Any]) -> None:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    remaining = {key: str(value) for key, value in updates.items()}
    for index, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", ";")) or "=" not in stripped:
            continue
        key = stripped.split("=", 1)[0].strip()
        if key in remaining:
            newline = "\r\n" if line.endswith("\r\n") else "\n"
            lines[index] = f"{key}={remaining.pop(key)}{newline}"
    if remaining:
        if lines and not lines[-1].endswith(("\n", "\r")):
            lines[-1] += "\n"
        lines.extend(f"{key}={value}\n" for key, value in remaining.items())
    path.write_text("".join(lines), encoding="utf-8")


def write_json_atomic(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def query_json(executable: Path, *arguments: str) -> dict[str, Any]:
    completed = subprocess.run(
        [str(executable), *arguments],
        cwd=SCRIPT_DIRECTORY,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(completed.stdout)


def git_provenance(directory: Path) -> dict[str, Any]:
    def command(*arguments: str) -> str:
        completed = subprocess.run(
            ["git", *arguments], cwd=directory, capture_output=True, text=True, check=False
        )
        return completed.stdout.strip() if completed.returncode == 0 else "unavailable"

    commit = command("rev-parse", "HEAD")
    status = command("status", "--porcelain")
    return {"commit": commit, "dirty": status not in {"", "unavailable"}}


def run_logged(command: list[str], cwd: Path, log_path: Path) -> int:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8", newline="") as log:
        process = subprocess.Popen(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="")
            log.write(line)
            log.flush()
        return process.wait()

