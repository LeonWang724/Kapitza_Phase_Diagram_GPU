@REM Codex CUDA Port: configure and build the native Windows CUDA executable.
@echo off
setlocal
cd /d "%~dp0"

where cmake >nul 2>nul || (echo ERROR: CMake is not on PATH.& exit /b 1)
where nvcc >nul 2>nul || (echo ERROR: CUDA nvcc is not on PATH.& exit /b 1)
where cl >nul 2>nul || (echo ERROR: Run from a Visual Studio x64 Native Tools prompt.& exit /b 1)
if not defined HDF5_ROOT (
  echo ERROR: Set HDF5_ROOT to the HDF5 install containing include, lib, and bin.
  exit /b 1
)

set "CONFIGURE_PRESET=windows-vs2022"
set "BUILD_PRESET=windows-release"
if /I "%~1"=="CPU_REFERENCE" (
  set "CONFIGURE_PRESET=windows-vs2022-with-cpu-reference"
  set "BUILD_PRESET=windows-release-with-cpu-reference"
  echo Building the optional untouched oneMKL CPU reference too.
)

cmake --preset "%CONFIGURE_PRESET%" -DHDF5_ROOT="%HDF5_ROOT%"
if errorlevel 1 exit /b 1
cmake --build --preset "%BUILD_PRESET%" --parallel
if errorlevel 1 exit /b 1

echo.
echo Built: %~dp0build\bin\gpe1d_cuda.exe
"%~dp0build\bin\gpe1d_cuda.exe" --version-json
exit /b %errorlevel%

