<!-- Codex CUDA Port: validation workflow guide. -->
# Validation workflow

`run_validation.py` generates identical per-case HDF5 inputs and separate CPU/CUDA configuration files. It never writes CPU and CUDA snapshots into the same directory.

For legacy Floquet mode it compares every common checkpoint after removing one global complex phase. Reports include wavefunction and density errors, normalization, and all energy columns. The physical Floquet case is exercised separately because the supplied CPU source implements only cumulative legacy scaling.

The default CPU references are:

1. `build/bin/gpe1d_cpu_reference.exe`, when the untouched MKL source target was built.
2. The opaque `phase_diagram/simulation_core/gpe1d_2.exe`.

The optional 3x3 grid uses the established cropped, unnormalized `sum(|psi|^4)` metric over 30 final snapshots. Default tolerances are hypotheses to be tested on the Windows machine, not an advance claim of equivalence.

Run from the project root with `VALIDATE_CUDA.bat`.

