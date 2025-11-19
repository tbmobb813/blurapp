# Performance Profiling Guide

This guide explains how to profile and optimize performance in BlurApp.

## Quick Reference

```bash
# Profile mode run (recommended for performance testing)
cd app && flutter run --profile

# Release mode run (production performance)
cd app && flutter run --release

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Memory Profiling

### Using Flutter DevTools

1. Run app in profile mode: `cd app && flutter run --profile`
2. Open DevTools (click link in terminal)
3. Navigate to Memory tab
4. Capture heap snapshot before/after operations
5. Compare snapshots to find memory leaks

### Expected Memory Usage

| Operation | Expected Memory | Notes |
|-----------|----------------|-------|
| App start | ~50-80MB | Base memory footprint |
| Image loaded (2048x2048) | +30-50MB | Depends on image size |
| Blur operation | +10-20MB | Temporary buffers |
| Image cache (3 images) | +50-90MB | LRU cache limit |

### Memory Optimizations (Already Implemented)

- ✅ 50MB memory bounds (editor_screen_mvp.dart:54)
- ✅ Automatic cache clearing on large images (editor_screen_mvp.dart:83-88)
- ✅ Image decode cache with LRU eviction (blur_engine_mvp.dart:20-32)
- ✅ Proper disposal in try-finally blocks (blur_engine_mvp.dart:126-134)

## CPU Profiling

### Using Flutter DevTools

1. Run in profile mode
2. Open DevTools → Performance tab
3. Click "Record", perform operations, click "Stop"
4. Analyze call tree for hot spots

### Current Performance Optimizations

| Area | Optimization | Location |
|------|-------------|----------|
| Brush strokes | In-place list updates (~90% faster) | editor_screen_mvp.dart:259 |
| Image decoding | LRU cache (up to 100% faster) | blur_engine_mvp.dart:56-76 |
| Mosaic effect | Center sampling (~70% faster) | blur_pipeline.dart:157-182 |
| File operations | Async streams (non-blocking) | image_saver_service.dart:227 |
| Canvas painting | Smart shouldRepaint logic | editor_screen_mvp.dart:721-728 |

## Frame Rate Analysis

### Targets
- **60 FPS** (16.67ms per frame) - Smooth
- **30 FPS** (33.33ms per frame) - Minimum
- **<30 FPS** - Investigate

### Enable Performance Overlay

```bash
flutter run --profile --trace-startup
```

### What to Look For

- Red bars in DevTools = dropped frames
- UI thread spikes during brush strokes
- Raster thread issues during blur operations

## Build Performance

### Measuring Build Times

```bash
# Use our build script (includes timing)
./scripts/build.sh debug

# Expected times:
# - Clean build: 3-5 minutes
# - Incremental: 30-60 seconds
```

### Build Optimizations (Already Configured)

| Setting | Value | Location |
|---------|-------|----------|
| JVM Heap | 8GB | app/android/gradle.properties:4 |
| Gradle workers | 2 | app/android/gradle.properties:9 |
| Parallel builds | Disabled (CI) | app/android/gradle.properties:7 |
| Jetifier | Disabled | app/android/gradle.properties:13 |

## Performance Benchmarks

### Current Performance

| Operation | Time | Target |
|-----------|------|--------|
| App cold start | ~2-3s | <3s |
| Load 2048x2048 image | ~500ms | <1s |
| Brush stroke (per frame) | ~1-3ms | <16ms |
| Blur preview (512x512) | ~200-300ms | <500ms |
| Export full resolution | ~1-2s | <3s |

### Memory Usage

| Scenario | Memory | Target |
|----------|--------|--------|
| Idle | ~60MB | <100MB |
| 1 image loaded | ~90MB | <150MB |
| 3 images cached | ~150MB | <200MB |
| During blur operation | ~170MB | <250MB |

## Common Issues & Solutions

### Slow brush strokes
- ✅ **Fixed:** In-place list updates implemented
- **Check:** Using profile mode (not debug)

### High memory usage
- ✅ **Fixed:** 50MB bounds + auto cache clearing
- **Check:** Image resolution reasonable

### Slow blur operations
- ✅ **Fixed:** Image decode cache implemented
- **Check:** Using preview resolution (512x512)

### UI freezing
- ✅ **Fixed:** Async file operations
- **Check:** No synchronous I/O on main thread

## Tools

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Android Studio Profiler
1. Run app in profile mode
2. View → Tool Windows → Profiler
3. Select CPU/Memory profiler

### Command-line
```bash
# Timeline trace
flutter run --profile --trace-startup

# Performance overlay
flutter run --profile --trace-skia
```

## Resources

- [Flutter Performance Docs](https://flutter.dev/docs/perf)
- [DevTools Guide](https://flutter.dev/docs/development/tools/devtools)
- Our optimizations: See commits 779c314, 0147f48

