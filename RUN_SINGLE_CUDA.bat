@REM Codex CUDA Port: run one config with the compiled CUDA executable.
@echo off
setlocal
cd /d "%~dp0"
if defined HDF5_ROOT set "PATH=%HDF5_ROOT%\bin;%PATH%"
python phase_diagram\simulation_core\run_single_CUDA.py %*
exit /b %errorlevel%

