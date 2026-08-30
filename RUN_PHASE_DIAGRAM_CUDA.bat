@REM Codex CUDA Port: launch the isolated manifest-driven native CUDA grid.
@echo off
setlocal
cd /d "%~dp0"
if defined HDF5_ROOT set "PATH=%HDF5_ROOT%\bin;%PATH%"
python phase_diagram\simulation_core\run_phase_diagram_CUDA.py %*
exit /b %errorlevel%

