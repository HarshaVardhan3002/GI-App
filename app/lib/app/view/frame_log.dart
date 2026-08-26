import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// {@template frame_log}
/// Frame timings, printed, for the material's acceptance measurement.
///
/// `docs/MATERIAL-IMPLEMENTATION.md` section 6: the material ships only if the
/// feed holds the same frame times with it on as without it. **That is a
/// number, not an impression**, and on Impeller `dumpsys gfxinfo` reports
/// nothing at all, because Flutter does not draw through HWUI. Flutter's own
/// [SchedulerBinding.addTimingsCallback] is where the numbers actually are.
///
/// Off unless asked for: `--dart-define=GI_FRAME_LOG=true`. It is a
/// measurement harness rather than a feature, and it is deliberately in the
/// app rather than in a test, because the thing being measured is this app
/// scrolling on a real device.
/// {@endtemplate}
abstract final class FrameLog {
  /// Whether this build reports frame timings.
  static const bool enabled = bool.fromEnvironment('GI_FRAME_LOG');

  /// Frames counted since [start].
  static int _frames = 0;

  /// Frames whose raster crossed a 60Hz budget.
  static int _janky = 0;

  /// Every frame's build and raster time, so a percentile is a real one.
  ///
  /// **Not `totalSpan`.** The first pass measured that and reported 95% janky
  /// frames at a p50 of 31ms while build was 2ms and raster 4ms: `totalSpan`
  /// runs from vsync start to raster finish, so on an emulator with no real
  /// display clock it is mostly waiting. Build and raster are the two numbers
  /// the app is actually responsible for, and a backdrop filter can only ever
  /// show up in the second.
  static final List<int> _builds = <int>[];
  static final List<int> _rasters = <int>[];

  /// One 60Hz frame, in microseconds. The emulator runs at 60.
  static const int budget = 16667;

  /// Begins reporting. A no-op unless [enabled].
  static void start() {
    if (!enabled) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frames++;
      _builds.add(timing.buildDuration.inMicroseconds);
      _rasters.add(timing.rasterDuration.inMicroseconds);
      if (timing.rasterDuration.inMicroseconds > budget) _janky++;
    }
    if (_frames % 120 == 0) _report();
  }

  /// Prints the running summary. Called every 120 frames.
  static void _report() {
    String stats(List<int> values) {
      final sorted = List<int>.from(values)..sort();
      String at(double p) {
        final us = sorted[((sorted.length - 1) * p).round()];
        return (us / 1000).toStringAsFixed(1);
      }

      return 'p50=${at(.50)} p90=${at(.90)} p99=${at(.99)} '
          'max=${(sorted.last / 1000).toStringAsFixed(1)}';
    }

    debugPrint(
      '[GI_FRAME] n=$_frames rasterOverBudget=$_janky '
      '(${(_janky / _frames * 100).toStringAsFixed(1)}%) | '
      'build ${stats(_builds)} | raster ${stats(_rasters)} (ms)',
    );
  }
}
