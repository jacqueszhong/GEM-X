@echo off
setlocal
REM GEM-X asset download for Windows. Run from inside the cloned repo root.
REM Requires the venv from install_gemx.bat (provides the `hf` CLI) and curl (built into Windows 10+).

cd /d "%~dp0" || goto :fail

REM ---- Activate venv so `hf` and `python` are available ----
if exist ".venv\Scripts\activate.bat" (
    call .venv\Scripts\activate.bat || goto :fail
) else (
    echo [ERROR] .venv not found. Run install_gemx.bat first.
    exit /b 1
)

if not exist "assets\soma" mkdir "assets\soma"
if not exist "weights" mkdir "weights"

REM ---- SOMA v0.3.3 body assets (+ correctives for Body Pose and mesh rendering) ----
hf download nvidia/SOMA-X SOMA_neutral.npz SOMA_template_rig.usda SOMA_procedural_transforms.json --revision v0.3.3 --local-dir assets/soma || goto :fail
hf download nvidia/SOMA-X correctives_model.pt --revision v0.3.3 --local-dir assets/soma || goto :fail

REM ---- Body Pose + Body Motion (native77) checkpoints ----
hf download nvidia/GEM-X motion_native77_e774_s292175.ckpt motion_stats_raw.npz motion_native77.yaml --local-dir weights || goto :fail
hf download nvidia/GEM-X body_s240000.ckpt vitpose.pth body_video_native77.yaml --local-dir weights || goto :fail

REM ---- YOLOX person detector -> weights\yolox_humanart.onnx ----
curl.exe --fail --location "https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/onnx_sdk/yolox_x_8xb8-300e_humanart-a39d44ed.zip" --output "weights\yolox_humanart.zip" || goto :fail

REM Helper script lives in %TEMP%, not the repo, so Python never imports from a random cwd
set "HELPER=%TEMP%\extract_yolox_%RANDOM%.py"
> "%HELPER%" echo from pathlib import Path
>> "%HELPER%" echo from shutil import copyfileobj
>> "%HELPER%" echo from zipfile import ZipFile
>> "%HELPER%" echo with ZipFile("weights/yolox_humanart.zip") as archive:
>> "%HELPER%" echo     member = next(name for name in archive.namelist() if name.endswith("/end2end.onnx"))
>> "%HELPER%" echo     with archive.open(member) as source, Path("weights/yolox_humanart.onnx").open("wb") as target:
>> "%HELPER%" echo         copyfileobj(source, target)
python "%HELPER%"
set "RC=%errorlevel%"
del "%HELPER%" >nul 2>&1
if not "%RC%"=="0" goto :fail

del "weights\yolox_humanart.zip"

echo.
echo Done. Assets are in assets\soma and weights\.
exit /b 0

:fail
echo.
echo [ERROR] Step failed (exit code %errorlevel%). See output above.
exit /b 1
