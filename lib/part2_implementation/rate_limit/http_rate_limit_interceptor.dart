import 'interceptor_contract.dart';

class RateLimitExceededException implements Exception {
  final String message;
  const RateLimitExceededException(this.message);

  @override
  String toString() => 'RateLimitExceededException: $message';
}

class HttpRateLimitInterceptor extends InterceptorContract {
  HttpRateLimitInterceptor({required this.executeRequest});

  final Future<ResponseData> Function(BaseRequest request) executeRequest;

  BaseRequest? _lastRequest;
  int _resendsForCurrentRequest = 0;
  bool _suppressRequestCounterReset = false;

  int? _parseRetryAfterSeconds(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        return int.tryParse(entry.value);
      }
    }
    return null;
  }

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    _lastRequest = request;
    if (!_suppressRequestCounterReset) {
      _resendsForCurrentRequest = 0;
    }
    _suppressRequestCounterReset = false;
    return request;
  }

  @override
  Future<ResponseData> interceptResponse({
    required ResponseData response,
  }) async {
    if (response.statusCode != 429) {
      return response;
    }
    if (_resendsForCurrentRequest >= 2) {
      throw const RateLimitExceededException(
        'Limite de reenvios após 429 excedido.',
      );
    }
    final request = _lastRequest;
    if (request == null) {
      throw const RateLimitExceededException(
        'Request original indisponível para reenvio.',
      );
    }
    final seconds = _parseRetryAfterSeconds(response.headers) ?? 0;
    _resendsForCurrentRequest++;
    await Future<void>.delayed(Duration(seconds: seconds));
    _suppressRequestCounterReset = true;
    final next = await executeRequest(request);
    return interceptResponse(response: next);
  }
}
