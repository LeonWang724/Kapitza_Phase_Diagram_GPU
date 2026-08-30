<!-- Codex CUDA Port: build, run, and validation instructions. -->
# Native CUDA `gpe1d_2` port

This tree contains a native C++/CUDA 1D solver named `gpe1d_cuda.exe`. Python only generates inputs, launches executables, records provenance, and analyzes saved data. The GPE evolution is compiled CUDA code using double-precision complex arithmetic and `cufftExecZ2Z`.

## Validation status

The source and workflow are prepared, but **not yet compiled or numerically validated**. The preparation machine is macOS without CMake, `nvcc`, an NVIDIA GPU, or `nvidia-smi`. Do not treat this README or a successful configure as evidence of numerical equivalence.

The validated delivery scope is the 1D phase-diagram path with `dynamic_potential=false`. Stochastic dynamic potential, 2D, and 3D stop with an explicit error or remain deferred; they are not silently run through a different implementation.

## Windows prerequisites

- 64-bit Windows 11 and the current NVIDIA driver for the RTX 5090.
- Visual Studio 2022 with **Desktop development with C++**, MSVC x64 tools, and a Windows SDK.
- NVIDIA CUDA Toolkit 13.3 or another toolkit explicitly supporting the installed driver, RTX 5090, and Visual Studio compiler. NVIDIA's current Windows guide lists Visual Studio 2022 as supported: https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/
- CMake 3.27 or newer. The preset uses `CMAKE_CUDA_ARCHITECTURES=native`, documented by CMake 3.24 and later: https://cmake.org/cmake/help/latest/prop_tgt/CUDA_ARCHITECTURES.html
- A 64-bit HDF5 development installation containing `include`, `lib`, and runtime `bin` directories. Set `HDF5_ROOT` to that installation.
- Python 3.12 and the packages in `phase_diagram/simulation_core/requirements_CUDA.txt`.
- Optional CPU-source reference: Intel oneAPI oneMKL with a discoverable `MKLConfig.cmake`.

## Build

Open an **x64 Native Tools Command Prompt for VS 2022**:

```bat
cd /d C:\path\to\timedependent_GPU_native
set HDF5_ROOT=C:\path\to\hdf5
python -m pip install -r phase_diagram\simulation_core\requirements_CUDA.txt
CHECK_CUDA.bat
BUILD_CUDA.bat
```

To also compile the untouched supplied source as `gpe1d_cpu_reference.exe`:

```bat
BUILD_CUDA.bat CPU_REFERENCE
```

The native executable is `build\bin\gpe1d_cuda.exe`. The build embeds its Git commit, dirty state, compilers, CUDA Toolkit, architecture selection, and UTC build time. No fast-math option is used; strict floating-point mode disables FMA by default for traceability.

## Single run

Make sure the config names an empty output directory, then run:

```bat
RUN_SINGLE_CUDA.bat phase_diagram\simulation_core\gpe1d.config --floquet-mode legacy
```

`legacy` cumulatively scales the working Floquet array as the supplied C++ source does. `physical` evaluates the unchanged base array times the current cosine. Legacy is a provisional source-compatibility default until the opaque executable comparison decides the workflow compatibility default.

## Validation before a full grid

```bat
VALIDATE_CUDA.bat
```

This runs the requested static, zero-alpha, driven, both-Floquet-mode, frequent-snapshot, and 3x3 grid checks. When present, both the source-built CPU executable and opaque workflow executable are used. Reports are written under `validation\results\validation_*`.

The default tolerances in `validation_cases.json` are initial acceptance hypotheses. They become documented evidence only after a completed Windows report. Capture `nvidia-smi` output during a CUDA run as external GPU-use evidence.

## Full phase diagram

Edit only the marked physical parameter section near the top of `run_phase_diagram_CUDA.py`, then:

```bat
RUN_PHASE_DIAGRAM_CUDA.bat --floquet-mode legacy
MAKE_PHASE_DIAGRAM_CUDA.bat phase_diagram\simulation_core\results_cuda\cuda_TIMESTAMP\run_manifest.json
```

Each grid creates a unique result root. Every run has isolated inputs, config, status, log, and `out_###` directory. The plotter reads parameter ordering exclusively from `run_manifest.json`.

## Numerical correspondence

Each real-time iteration performs:

1. Floquet potential update at the current time.
2. Density and nonlinear/potential half step.
3. Unnormalized forward cuFFT.
4. Explicit `1/N` scaling and kinetic propagator.
5. Unnormalized inverse cuFFT.
6. Recomputed density and the second nonlinear/potential half step.
7. Optional imaginary-time normalization.
8. Post-step snapshot and diagnostic output at the original iteration indices.

HDF5 remains CPU-side. Device-to-host transfers occur only for snapshots and reported diagnostic scalars.

