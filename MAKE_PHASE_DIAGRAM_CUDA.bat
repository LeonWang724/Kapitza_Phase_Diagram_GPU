@REM Codex CUDA Port: analyze one completed manifest without a second parameter grid.
@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: MAKE_PHASE_DIAGRAM_CUDA.bat path\to\run_manifest.json
  exit /b 2
)
python phase_diagram\simulation_core\make_phase_diagram_CUDA.py "%~1"
exit /b %errorlevel%

