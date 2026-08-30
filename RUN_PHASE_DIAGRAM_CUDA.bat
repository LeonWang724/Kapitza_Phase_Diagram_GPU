@REM Codex CUDA Port: launch the isolated manifest-driven native CUDA grid.
@echo off
setlocal
cd /d "%~dp0"
call "%~dp0LOAD_CUDA_ENV.bat"
python phase_diagram\simulation_core\run_phase_diagram_CUDA.py %*
exit /b %errorlevel%
