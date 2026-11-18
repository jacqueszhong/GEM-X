# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""ONNXRuntime session creation shared by the ONNX detectors."""

from __future__ import annotations


def create_session(onnx_path, device="cpu", name="ONNX detector"):
    """Create an ONNXRuntime session on ``cpu``, ``cuda`` or ``cuda:N``.

    A CUDA request falls back to CPU, with a printed message, when ONNXRuntime
    has no CUDAExecutionProvider (CPU-only wheel) or the provider does not
    activate (no usable GPU).
    """
    import onnxruntime as ort

    cpu = ["CPUExecutionProvider"]
    if device == "cpu":
        providers = cpu
    elif device == "cuda" or device.startswith("cuda:"):
        if "CUDAExecutionProvider" not in ort.get_available_providers():
            print(
                f"[{name}] CUDA requested but ONNXRuntime has no CUDAExecutionProvider; "
                "falling back to CPU",
                flush=True,
            )
            providers = cpu
        else:
            # Load CUDA/cuDNN from the pip nvidia-* packages; without this, cuDNN is
            # found only if something (e.g. torch) already loaded it.
            if hasattr(ort, "preload_dlls"):
                ort.preload_dlls(directory="")
            device_id = 0 if device == "cuda" else int(device.split(":")[1])
            providers = [("CUDAExecutionProvider", {"device_id": device_id}), *cpu]
    else:
        raise ValueError(f"{name} device must be cpu, cuda, or cuda:N")
    options = ort.SessionOptions()
    options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    session = ort.InferenceSession(str(onnx_path), sess_options=options, providers=providers)
    if providers is not cpu and "CUDAExecutionProvider" not in session.get_providers():
        print(f"[{name}] CUDA provider did not activate; falling back to CPU", flush=True)
    return session
