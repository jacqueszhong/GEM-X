# Fork notes: jacqueszhong/GEM-X

This fork tracks [NVlabs/GEM-X](https://github.com/NVlabs/GEM-X) and is used as the
video → SOMA motion stage of a ProtoMotions pipeline. This file records what the fork
changes, the environment it was tested in, and the upstream install issues the
README now works around.

**To install, follow the README's [Quick Start](README.md#quick-start), steps 1–2.**

## What differs from upstream

| change | why |
|---|---|
| `README.md` Quick Start, steps 1–2 and the Body Motion example | Rewritten into one tested uv command sequence that avoids install issues 1–7 below. Explicit `--camera-mode`. |
| `third_party/soma-retargeter` submodule → [jacqueszhong/soma-retargeter](https://github.com/jacqueszhong/soma-retargeter) `main` | Upstream dropped robot retargeting from the package, but the SOMA BVH export still uses soma-retargeter's skeleton/BVH classes. The fork is upstream v0.2.1 plus one commit that turns its exact dependency pins into lower bounds, so it installs into this env without downgrading anything (issue 8). |
| `gem/common/detectors/onnx_session.py` (shared by `yolox.py`, `hand.py`) | ONNX detectors asked for `cuda` fall back to CPU, with a printed message, when ONNXRuntime has no usable `CUDAExecutionProvider`. They call `onnxruntime.preload_dlls()` so cuDNN loads from the pip `nvidia-*` wheels. |
| `FORK.md` | this file |

Remotes: `origin` = this fork. Add `upstream` for official updates. Expect a README
conflict when upstream changes its Quick Start.
```bash
git remote add upstream https://github.com/NVlabs/GEM-X.git
git fetch upstream && git merge upstream/main && git submodule update --init
```

## Tested environment

Ubuntu 24.04, NVIDIA driver 580 (CUDA 13.0), RTX 4070 Ti SUPER 16 GB, uv 0.12, Python 3.12.
After the Quick Start: torch 2.15.0+cu132, py-soma-x 0.3.3, transformers 5.3.0,
onnxruntime-gpu 1.32.0, open3d 0.19.0, soma-retargeter 0.2.1, newton 1.8.0,
warp-lang 1.19.0, numpy 2.5.5, usd-core 26.11, scipy 1.18.1. `uv pip check` is clean.

On a 200-frame 720p clip with a fixed camera, `motion-video` took about 80 s (CPU detector),
Contact/IK (`motion-cache --postprocess`) 7 s, and `gem-render` 40 s per result.
The first soma-retargeter run in a fresh venv spends 70–100 s compiling warp kernels.

## Upstream install issues (NVlabs/GEM-X @ 4aef145)

Each issue is followed by how the README Quick Start in this fork handles it.

1. **No PyTorch install command.** The docs say to install PyTorch first but give no
   command or index URL. → `uv pip install torch`, with a note on `--index-url` for older drivers.
2. **`python -m pip` in a uv venv.** With the documented `uv venv` route, the later
   `python -m pip …` steps (SOMA section, PRETRAINED_MODELS) fail with
   `No module named pip`. → Every step uses `uv pip`.
3. **The SOMA step reinstalls `py-soma-x`,** which is already a dependency.
   `huggingface_hub`, which every download step needs for `hf`, isn't declared anywhere.
   → Install `huggingface_hub` with GEM, and drop the reinstall.
4. **`TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=0` is only documented for Docker/conda/NGC.**
   → Exported in the Quick Start.
5. **The YOLOX extraction step leaves the 368 MB zip behind.** → `rm weights/yolox_humanart.zip`.
6. **The Quick Start install omits `.[render]`** but then runs `gem-render`. → `.[video,render]`.
7. **The default camera mode is `background`.** Fixed-camera clips need
   `--camera-mode static`, which is only mentioned in passing. → The Body Motion example
   passes it and explains the choice.
8. **soma-retargeter's exact version pins silently downgrade GEM's packages** (numpy,
   warp-lang, usd-core, scipy and others). `uv pip check` then reports a typing-extensions
   conflict. The v0.1 pin `newton==1.0.0` doesn't even import on warp 1.19
   (`warp.config has no attribute 'verbose'`). → Fixed by the soma-retargeter fork's relaxed pins.
