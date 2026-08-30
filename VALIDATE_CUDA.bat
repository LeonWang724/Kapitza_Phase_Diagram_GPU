@REM Codex CUDA Port: run short-time checkpoint and 3x3 phase-diagram validation.
@echo off
setlocal
cd /d "%~dp0"
if defined HDF5_ROOT set "PATH=%HDF5_ROOT%\bin;%PATH%"
python validation\run_validation.py %*
exit /b %errorlevel%

