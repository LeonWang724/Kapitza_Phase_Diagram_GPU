@REM Codex CUDA Port: verify the Windows CUDA, build, HDF5, and Python environment.
@echo off
setlocal
cd /d "%~dp0"

echo === NVIDIA driver and GPU ===
nvidia-smi
if errorlevel 1 exit /b 1
echo.
echo === CUDA compiler ===
nvcc --version
if errorlevel 1 exit /b 1
echo.
echo === CMake ===
cmake --version
if errorlevel 1 exit /b 1
echo.
echo === Python orchestration dependencies ===
python --version
python -c "import numpy, scipy, tables, matplotlib; print('Python dependencies: OK')"
if errorlevel 1 exit /b 1

if exist "%~dp0build\bin\gpe1d_cuda.exe" (
  if defined HDF5_ROOT set "PATH=%HDF5_ROOT%\bin;%PATH%"
  echo.
  echo === Native solver build ===
  "%~dp0build\bin\gpe1d_cuda.exe" --version-json
  if errorlevel 1 exit /b 1
  "%~dp0build\bin\gpe1d_cuda.exe" --device-info 0
  if errorlevel 1 exit /b 1
) else (
  echo WARNING: build\bin\gpe1d_cuda.exe does not exist yet.
)
exit /b 0

