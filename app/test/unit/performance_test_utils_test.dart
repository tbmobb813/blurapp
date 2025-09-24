import 'package:flutter_test/flutter_test.dart';

import '../helpers/performance_test_utils.dart';

void main() {
  test('createMemoryPressure and releaseMemoryPressure behave as expected', () {
    // keep size small so tests don't use too much memory in CI
    final chunks = PerformanceTestUtils.createMemoryPressure(sizeInMB: 3);
    expect(chunks.length, 3);
    for (final chunk in chunks) {
      expect(chunk.length, 1024 * 1024);
    }

    PerformanceTestUtils.releaseMemoryPressure(chunks);
    expect(chunks.length, 0);
  });

  test('measureExecutionTime returns non-negative timings', () {
    final tm = PerformanceTestUtils.measureExecutionTime(() {
      // small CPU work
      var s = 0;
      for (var i = 0; i < 100000; i++) {
        s += i;
      }
      // use s so compiler doesn't optimize it away
      expect(s >= 0, isTrue);
    });

    expect(tm.milliseconds, greaterThanOrEqualTo(0));
    expect(tm.microseconds, greaterThanOrEqualTo(0));
  });

  test('measureAsyncExecutionTime measures a delayed async operation', () async {
    final tm = await PerformanceTestUtils.measureAsyncExecutionTime(() async {
      await Future.delayed(const Duration(milliseconds: 20));
    });

    // Should take at least part of the delay; allow some jitter
    expect(tm.milliseconds, greaterThanOrEqualTo(10));
  });

  test('MemoryMeasurement.toString contains formatted byte values', () {
    final mm = MemoryMeasurement(before: 1024, after: 2048, difference: 1024);
    final s = mm.toString();
    expect(s, contains('1.0KB'));
    expect(s, contains('2.0KB'));
  });

  test('getCurrentMemoryUsage returns an int and is >= -1', () {
    final mem = PerformanceTestUtils.getCurrentMemoryUsage();
    expect(mem, isA<int>());
    expect(mem, greaterThanOrEqualTo(-1));
  });
}
