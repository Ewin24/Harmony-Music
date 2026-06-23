import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/debug_logger.dart';

/// Dio interceptor that emits structured, color-coded logs for every request
/// and response handled by the app. Disabled in release mode.
///
/// Log shape:
///   [timestamp] [INFO ] [HTTP] ──> GET  https://example.com/api/v1/x?a=b
///   [timestamp] [DEBUG] [HTTP]     body: {"key":"value"}
///   [timestamp] [INFO ] [HTTP] <── 200 (412ms, 1.4 KB)
///   [timestamp] [DEBUG] [HTTP]     body: {…pretty JSON, fully expanded…}
///
/// Bodies are passed through to [DebugLogger.dump] with `fullDump: true`
/// so they are pretty-printed (2-space indent) and **never** truncated.
/// The previous behaviour truncated responses to 1200 characters and then
/// tried to re-parse the broken JSON, which produced a single-line `toString`
/// blob instead of a readable tree.
class HttpLoggingInterceptor extends Interceptor {
  HttpLoggingInterceptor({this.tag = 'HTTP'});

  final String tag;
  static const _stopwatchKey = '__debug_logger_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_stopwatchKey] = DateTime.now();
    final uri = _uriString(options);
    DebugLogger.info(tag, '──> ${options.method.padRight(5)} $uri');
    final data = options.data;
    if (data != null) {
      DebugLogger.dump(tag, _normalizeForLog(data),
          label: 'request body', fullDump: true);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final elapsed = _elapsedMs(response.requestOptions);
    final sizeKb = _approxKb(response.data);
    DebugLogger.info(
      tag,
      '<── ${response.statusCode} '
      '${response.requestOptions.method.padRight(5)} '
      '(${elapsed}ms, $sizeKb KB)',
    );
    final data = response.data;
    if (data != null) {
      DebugLogger.dump(tag, _normalizeForLog(data),
          label: 'response body', fullDump: true);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final elapsed = _elapsedMs(err.requestOptions);
    DebugLogger.error(
      tag,
      'xx ${err.requestOptions.method.padRight(5)} '
      '${err.response?.statusCode ?? "no-status"} '
      '(${elapsed}ms) ${_uriString(err.requestOptions)}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }

  // --- helpers --------------------------------------------------------------

  String _uriString(RequestOptions o) {
    final base = o.baseUrl;
    final path = o.path;
    final full = base.isEmpty ? path : '$base$path';
    if (o.queryParameters.isEmpty) return full;
    final query = o.queryParameters.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return '$full?$query';
  }

  int _elapsedMs(RequestOptions o) {
    final start = o.extra[_stopwatchKey];
    if (start is DateTime) {
      return DateTime.now().difference(start).inMilliseconds;
    }
    return -1;
  }

  String _approxKb(Object? data) {
    try {
      final s = data is String ? data : json.encode(data);
      return (s.length / 1024).toStringAsFixed(1);
    } catch (_) {
      return '?';
    }
  }

  /// Lightly shape a body for logging. We deliberately do **not** truncate:
  /// the caller passes `fullDump: true` so [DebugLogger] emits the entire
  /// pretty-printed tree.
  Object? _normalizeForLog(Object? data) {
    if (data is List<int>) {
      return '<binary ${data.length} bytes>';
    }
    if (data is FormData) {
      return '<form data fields=${data.fields.length} files=${data.files.length}>';
    }
    return data;
  }
}
