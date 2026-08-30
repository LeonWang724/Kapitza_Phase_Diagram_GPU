@REM Codex CUDA Port: configure and build the native Windows CUDA executable.
@echo off
setlocal
cd /d "%~dp0"

call "%~dp0LOAD_CUDA_ENV.bat" --with-compiler
call :build %*
set "BUILD_RESULT=%ERRORLEVEL%"
echo.
if "%BUILD_RESULT%"=="0" (
  echo BUILD COMPLETED SUCCESSFULLY.
) else (
  echo BUILD FAILED with exit code %BUILD_RESULT%.
  echo If a dependency is missing, rerun SETUP_WINDOWS.bat.
)
if not defined GPE_NO_PAUSE pause
exit /b %BUILD_RESULT%

:build

where cmake >nul 2>nul || (echo ERROR: CMake is not on PATH.& exit /b 1)
where nvcc >nul 2>nul || (echo ERROR: CUDA nvcc is not on PATH.& exit /b 1)
where cl >nul 2>nul || (echo ERROR: Visual Studio 2022 C++ x64 tools are unavailable.& exit /b 1)
if not defined HDF5_ROOT (
  echo ERROR: HDF5_ROOT is unavailable.
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
