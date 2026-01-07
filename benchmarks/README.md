# Benchmarks

This folder contains notes and helper scripts for running basic benchmarks on Core ML models.

Approach
- Use MochiDiffusion or your Swift/Vapor backend to run end-to-end inference and measure wall-clock time for generation (recommended).
- Alternatively, measure model load and single inference time with a small Python helper if `coremltools` or Core ML runtime is available.

Runbook
1. Ensure model compiled (`*.mlmodelc`) is available under `models/`.
2. Start your backend or a small runner that loads the Core ML bundles and invokes inference.
3. Record timings for first run (includes ANE compile) and subsequent runs.

Example: manual benchmarking via MochiDiffusion app (recommended):
- Launch MochiDiffusion on the Mac and load the converted model; generate a 512x512 image and record time.
