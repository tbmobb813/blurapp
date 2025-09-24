import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Utilities for performance testing and memory management validation
class PerformanceTestUtils {
  /// Memory limits for different test scenarios (in bytes)
  static const int smallImageMemoryLimit = 50 * 1024 * 1024; // 50MB
  static const int mediumImageMemoryLimit = 100 * 1024 * 1024; // 100MB
  static const int largeImageMemoryLimit = 200 * 1024 * 1024; // 200MB
  static const int serviceMemoryLimit = 10 * 1024 * 1024; // 10MB

  /// Time limits for different operations (in milliseconds)
  static const int smallImageProcessingLimit = 1000; // 1 second
  static const int mediumImageProcessingLimit = 5000; // 5 seconds
  static const int largeImageProcessingLimit = 10000; // 10 seconds
  static const int serviceOperationLimit = 2000; // 2 seconds

  /// Get current process memory usage in bytes
  /// Returns -1 if memory information is not available
  static int getCurrentMemoryUsage() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      // Memory info not available on this platform
      return -1;
    }
  }

  /// Measure memory usage before and after an operation
  /// Returns MemoryMeasurement with before/after values and difference
  static MemoryMeasurement measureMemoryUsage(Function operation) {
    final memoryBefore = getCurrentMemoryUsage();
    operation();
    final memoryAfter = getCurrentMemoryUsage();

    return MemoryMeasurement(
      before: memoryBefore,
      after: memoryAfter,
      difference: memoryBefore > 0 && memoryAfter > 0
          ? memoryAfter - memoryBefore
          : 0,
    );
  }

  /// Measure async memory usage before and after an operation
  static Future<MemoryMeasurement> measureAsyncMemoryUsage(
    Future Function() operation,
  ) async {
    final memoryBefore = getCurrentMemoryUsage();
    await operation();
    final memoryAfter = getCurrentMemoryUsage();

    return MemoryMeasurement(
      before: memoryBefore,
      after: memoryAfter,
      difference: memoryBefore > 0 && memoryAfter > 0
          ? memoryAfter - memoryBefore
          : 0,
    );
  }

  /// Measure execution time of an operation
  static TimeMeasurement measureExecutionTime(Function operation) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();

    return TimeMeasurement(
      milliseconds: stopwatch.elapsedMilliseconds,
      microseconds: stopwatch.elapsedMicroseconds,
    );
  }

  /// Measure async execution time of an operation
  static Future<TimeMeasurement> measureAsyncExecutionTime(
    Future Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();

    return TimeMeasurement(
      milliseconds: stopwatch.elapsedMilliseconds,
      microseconds: stopwatch.elapsedMicroseconds,
    );
  }

  /// Validate that memory usage is within acceptable limits
  static void validateMemoryUsage(
    MemoryMeasurement measurement,
    int limitBytes, {
    String? context,
  }) {
    if (measurement.difference > 0) {
      expect(
        measurement.difference,
        lessThan(limitBytes),
        reason:
            'Memory usage exceeded limit${context != null ? ' for $context' : ''}: '
            '${_formatBytes(measurement.difference)} > ${_formatBytes(limitBytes)}',
      );
    }
  }

  /// Validate that execution time is within acceptable limits
  static void validateExecutionTime(
    TimeMeasurement measurement,
    int limitMilliseconds, {
    String? context,
  }) {
    expect(
      measurement.milliseconds,
      lessThan(limitMilliseconds),
      reason:
          'Execution time exceeded limit${context != null ? ' for $context' : ''}: '
          '${measurement.milliseconds}ms > ${limitMilliseconds}ms',
    );
  }

  /// Format bytes into human-readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Create a test image with specified characteristics for performance testing
  static Uint8List createPerformanceTestImage({
    required int width,
    required int height,
    PerformanceTestImageType type = PerformanceTestImageType.simple,
  }) {
    // This would integrate with the image creation logic from the main test file
    // For now, return empty data as placeholder
    return Uint8List(0);
  }

  /// Simulate high memory pressure to test app behavior under stress
  static List<Uint8List> createMemoryPressure({int sizeInMB = 100}) {
    final chunks = <Uint8List>[];
    const chunkSize = 1024 * 1024; // 1MB chunks

    for (int i = 0; i < sizeInMB; i++) {
      chunks.add(Uint8List(chunkSize));
    }

    return chunks;
  }

  /// Release memory pressure
  static void releaseMemoryPressure(List<Uint8List> chunks) {
    chunks.clear();
  }
}

/// Measurement result for memory usage
class MemoryMeasurement {
  final int before;
  final int after;
  final int difference;

  const MemoryMeasurement({
    required this.before,
    required this.after,
    required this.difference,
  });

  bool get isValid => before > 0 && after > 0;

  @override
  String toString() =>
      'MemoryMeasurement(before: ${PerformanceTestUtils._formatBytes(before)}, '
      'after: ${PerformanceTestUtils._formatBytes(after)}, '
      'diff: ${PerformanceTestUtils._formatBytes(difference)})';
}

/// Measurement result for execution time
class TimeMeasurement {
  final int milliseconds;
  final int microseconds;

  const TimeMeasurement({
    required this.milliseconds,
    required this.microseconds,
  });

  @override
  String toString() => 'TimeMeasurement(${milliseconds}ms, $microsecondsμs)';
}

/// Types of test images for different performance scenarios
enum PerformanceTestImageType {
  simple, // Solid color, minimal complexity
  complex, // Gradients and patterns, high complexity
  realistic, // Photo-like content
  pathological, // Worst-case scenario for memory/processing
}
