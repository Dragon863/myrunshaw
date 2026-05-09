// 07/05/2026: This is related to the "eduroam" speed survey across campus.
//             It is purely opt-in and gathers data on wifi speeds for each
//             AP based on its BSSID. For reasons relating to permissions,
//             it is only available on Android, and user location is NEVER
//             accessed or collected.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

import 'package:runshaw/utils/http/http_client_factory.dart' as http_factory;
import 'package:runshaw/utils/logging.dart';

class WifiSpeedSurveyResult {
  final double downloadSpeedMbps;
  final double uploadSpeedMbps;
  final List<double> pingTimesMs;
  final double meanLatencyMs;
  final double jitterMs;

  const WifiSpeedSurveyResult({
    required this.downloadSpeedMbps,
    required this.uploadSpeedMbps,
    required this.pingTimesMs,
    required this.meanLatencyMs,
    required this.jitterMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'downloadSpeedMbps': downloadSpeedMbps,
      'uploadSpeedMbps': uploadSpeedMbps,
      'pingTimesMs': pingTimesMs,
      'meanLatencyMs': meanLatencyMs,
      'jitterMs': jitterMs,
    };
  }
}

class WifiSpeedSurvey {
  // Smaller payloads are generally enough for telemetry purposes while
  // reducing bandwidth/battery impact on users.
  static const int testSizeBytes = 8 * 1024 * 1024; // 8MB

  static final Uri dlSpeedEndpoint = Uri.parse(
    'https://speed.cloudflare.com/__down?bytes=$testSizeBytes',
  );

  static final Uri ulSpeedEndpoint = Uri.parse(
    'https://speed.cloudflare.com/__up',
  );

  static final Uri pingEndpoint = Uri.parse(
    'https://speed.cloudflare.com/__down?bytes=1',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  Future<WifiSpeedSurveyResult?> runSpeedTest({
    ValueChanged<double>? onProgress,
  }) async {
    final client = http_factory.httpClient();

    try {
      _reportProgress(onProgress, 0.0);

      // 1. Run Ping test first. This also serves to establish the TCP/TLS
      // connections (warm-up) so handshakes don't skew the DL/UL tests.
      final pingTimesMs = await _runPingTest(
        client,
        onProgress: onProgress,
      );

      final meanLatencyMs = _calculateMean(pingTimesMs);

      final jitterMs = _calculateJitter(
        pingTimesMs,
        meanLatencyMs,
      );

      // 2. Run DL and UL sequentially. Running them concurrently on Wi-Fi
      // causes TCP ACK starvation and drastically reduces the speed of both.
      _reportProgress(onProgress, 0.25);
      final downloadSpeedMbps = await _runDownloadTest(client);
      _reportProgress(onProgress, 0.7);
      final uploadSpeedMbps = await _runUploadTest(client);
      _reportProgress(onProgress, 1.0);

      return WifiSpeedSurveyResult(
        downloadSpeedMbps: downloadSpeedMbps,
        uploadSpeedMbps: uploadSpeedMbps,
        pingTimesMs: pingTimesMs,
        meanLatencyMs: meanLatencyMs,
        jitterMs: jitterMs,
      );
    } catch (e, stackTrace) {
      debugLog(
        'Error during Wi-Fi speed test: $e\n$stackTrace',
        level: 3,
      );

      return null;
    } finally {
      client.close();
    }
  }

  void _reportProgress(ValueChanged<double>? onProgress, double progress) {
    onProgress?.call(progress.clamp(0.0, 1.0));
  }

  Future<double> _runDownloadTest(http.Client client) async {
    final request = http.Request('GET', dlSpeedEndpoint);

    // Send the request and wait for headers.
    final response = await client.send(request).timeout(requestTimeout);

    if (response.statusCode != 200) {
      return 0.0;
    }

    // Start timing after headers are received. ensures we're
    // timing the actual data transfer, avoiding any TTFB overhead.
    final stopwatch = Stopwatch()..start();

    int bytesReceived = 0;
    await for (final chunk in response.stream) {
      bytesReceived += chunk.length;
    }

    stopwatch.stop();

    if (stopwatch.elapsedMilliseconds == 0) {
      return 0.0;
    }

    final seconds = stopwatch.elapsedMilliseconds / 1000.0;

    return (bytesReceived * 8) / seconds / 1000000;
  }

  Future<double> _runUploadTest(http.Client client) async {
    final uploadData = Uint8List(testSizeBytes);
    final random = Random();

    // Create a 10KB random block to avoid easily compressible patterns
    // that would artificially inflate upload speeds.
    const int chunkSize = 10 * 1024;
    final chunk = Uint8List(chunkSize);
    for (int i = 0; i < chunkSize; i++) {
      chunk[i] = random.nextInt(256);
    }

    // Rapidly copy the 10KB chunk across the 8MB buffer using memory ranges.
    // This completes almost instantly and avoids blocking the UI thread.
    for (int offset = 0; offset < testSizeBytes; offset += chunkSize) {
      final end = min(offset + chunkSize, testSizeBytes);
      uploadData.setRange(offset, end, chunk);
    }

    final request = http.Request('POST', ulSpeedEndpoint)
      ..bodyBytes = uploadData;

    final stopwatch = Stopwatch()..start();

    final response = await client.send(request).timeout(requestTimeout);

    // Consume stream fully to ensure upload completed properly.
    await response.stream.drain();

    stopwatch.stop();

    if (response.statusCode != 200 || stopwatch.elapsedMilliseconds == 0) {
      return 0.0;
    }

    final seconds = stopwatch.elapsedMilliseconds / 1000.0;

    return (testSizeBytes * 8) / seconds / 1000000;
  }

  Future<List<double>> _runPingTest(
    http.Client client, {
    ValueChanged<double>? onProgress,
  }) async {
    // warm-up ping
    // establish the initial dns resolution, tcp handshake, and tls handshake.
    // Discard the result of this request so the overhead doesn't skew latency/jitter.
    try {
      await client.get(pingEndpoint).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore warm-up failure, proceed to actual pings
    }

    // Small delay to ensure the connection is ready and idle.
    await Future.delayed(const Duration(milliseconds: 200));
    _reportProgress(onProgress, 0.05);

    final pingTimesMs = <double>[];

    for (int i = 0; i < 5; i++) {
      try {
        final stopwatch = Stopwatch()..start();

        final response =
            await client.get(pingEndpoint).timeout(const Duration(seconds: 5));

        stopwatch.stop();

        if (response.statusCode == 200) {
          pingTimesMs.add(
            stopwatch.elapsedMilliseconds.toDouble(),
          );
        }
      } catch (_) {
        // Ignore individual ping failures.
      }

      // Small spacing between pings avoids burst effects.
      await Future.delayed(const Duration(milliseconds: 200));
      _reportProgress(onProgress, 0.05 + ((i + 1) / 5) * 0.2);
    }

    _reportProgress(onProgress, 0.25);

    return pingTimesMs;
  }

  double _calculateMean(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }

    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateJitter(
    List<double> values,
    double mean,
  ) {
    if (values.isEmpty) {
      return 0.0;
    }

    return values.fold<double>(
          0.0,
          (sum, value) => sum + (value - mean).abs(),
        ) /
        values.length;
  }

  Future<bool> uploadResult(
    WifiSpeedSurveyResult result, {
    Future<void> Function(Map<String, Object> props)? submitter,
  }) async {
    // convert Map<String, dynamic> to Map<String, Object>
    final props =
        result.toJson().map<String, Object>((k, v) => MapEntry(k, v as Object));
    // upload as a PostHog event
    props['platform'] = defaultTargetPlatform.toString();
    props['bssid'] = await NetworkInfo().getWifiBSSID() ?? 'unknown';

    try {
      if (submitter != null) {
        await submitter(props);
      }
      // await Posthog()
      //     .capture(eventName: "speed_test_completed", properties: props);
      debugLog(props.toString());
      return true;
    } catch (e, stackTrace) {
      debugLog(
        'Error uploading Wi-Fi survey results: $e\n$stackTrace',
        level: 3,
      );
      return false;
    }
  }
}
