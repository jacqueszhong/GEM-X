@echo off
setlocal
cd /d "%~dp0"

set TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=0

.venv\Scripts\gem-infer.exe motion-video --task body ^
  --input assets\walk_3840_2160_60fps.mp4 ^
  --config docs\configs\body_video_native77.yaml ^
  --device cuda ^
  --camera-mode static ^
  --postprocess --soma-assets assets\soma ^
  --output outputs\walk_motion.pt

endlocal
