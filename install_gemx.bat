@echo off
setlocal enabledelayedexpansion
REM GEM-X install for Windows. Run from inside the cloned repo root.
REM Change CUDA_TAG to match your driver: cu126, cu128, cu130 ...
set CUDA_TAG=cu130

REM ---- 1. Fully leave any conda env ----
where conda >nul 2>&1
if not errorlevel 1 (
    for /l %%i in (1,1,5) do (
        if defined CONDA_DEFAULT_ENV (
            call conda deactivate
        )
    )
)
if defined CONDA_DEFAULT_ENV (
    echo [WARN] A conda env is still active: %CONDA_DEFAULT_ENV%
    echo        Open a fresh cmd window without conda auto-activation and retry.
)

REM ---- 2. Go to repo root (folder this script is in) and update submodules ----
cd /d "%~dp0" || goto :fail
git config core.longpaths true
git submodule update --init --recursive || goto :fail

REM ---- 3. venv ----
uv venv .venv --python 3.12 || goto :fail
call .venv\Scripts\activate.bat || goto :fail

REM ---- 4. PyTorch (CUDA index; the default Windows wheel is CPU-only) ----
uv pip install torch --index-url https://download.pytorch.org/whl/%CUDA_TAG% || goto :fail

REM ---- 5. GEM + extras ----
uv pip install -e ".[video,render]" huggingface_hub || goto :fail

REM ---- 6. Optional GPU person detector ----
uv pip uninstall onnxruntime
uv pip install onnxruntime-gpu || goto :fail

REM ---- 7. soma-retargeter ----
uv pip install -e third_party\soma-retargeter || goto :fail

REM ---- 8. ffmpeg for GEM-X's video normalization ----
REM protomotions_dev (video2physics worker, gemx_video_to_bvh.py) always runs
REM imageio-ffmpeg's static binary, never an ffmpeg from PATH: a PATH build can be
REM held minutes at launch by endpoint security. Same version Kit installs.
uv pip install imageio-ffmpeg==0.6.0 || goto :fail

REM ---- 9. Verify ----
uv pip check
python -c "import torch; print('torch', torch.__version__, 'cuda available:', torch.cuda.is_available())"
python -c "import imageio_ffmpeg; print('imageio-ffmpeg', imageio_ffmpeg.__version__, imageio_ffmpeg.get_ffmpeg_exe())" || goto :fail

echo.
echo Done. Activate later with: %CD%\.venv\Scripts\activate.bat
exit /b 0

:fail
echo.
echo [ERROR] Step failed (exit code %errorlevel%). See output above.
exit /b 1