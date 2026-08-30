@REM One-click Windows dependency bootstrap for the native CUDA solver.
@echo off
setlocal
cd /d "%~dp0"
title Native CUDA solver setup

echo This installs or repairs the required Windows build environment:
echo   Python 3.12, Git, CMake, Ninja, Visual Studio 2022 C++ tools,
echo   CUDA Toolkit 13.3.1, HDF5 2.1.1, and Python packages.
echo.
echo Windows may show an Administrator approval prompt.
echo CUDA and Visual Studio are large downloads, so setup can take a while.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_windows.ps1"
set "SETUP_RESULT=%ERRORLEVEL%"

echo.
if "%SETUP_RESULT%"=="0" (
  call "%~dp0LOAD_CUDA_ENV.bat" --with-compiler
  echo SETUP COMPLETED SUCCESSFULLY.
  echo.
  echo Dependency paths active in this window:
  where python.exe
  where cmake.exe
  where ninja.exe
  where nvcc.exe
  where cl.exe
  echo.
  echo Python and the project packages use: %~dp0.venv
  echo The paths were also saved for future VS Code terminals.
  echo You can now run CHECK_CUDA.bat and then BUILD_CUDA.bat.
) else (
  echo SETUP FAILED with exit code %SETUP_RESULT%.
  echo Read SETUP_WINDOWS.log in this folder for the exact failure.
)
echo.
pause
exit /b %SETUP_RESULT%
