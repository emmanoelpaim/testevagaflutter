import 'package:flutter_test/flutter_test.dart';

import 'package:testevagaflutter/part2_implementation/rate_limit/http_rate_limit_interceptor.dart';
import 'package:testevagaflutter/part2_implementation/rate_limit/interceptor_contract.dart';

void main() {
  group('HttpRateLimitInterceptor', () {
    const req = BaseRequest(url: 'https://api.test/data', method: 'GET');

    test('resposta que não é 429 devolve sem reenviar', () async {
      var executions = 0;
      final interceptor = HttpRateLimitInterceptor(
        executeRequest: (r) async {
          executions++;
          return const ResponseData(statusCode: 200, headers: {}, body: null);
        },
      );
      await interceptor.interceptRequest(request: req);
      final out = await interceptor.interceptResponse(
        response: const ResponseData(statusCode: 200, headers: {}, body: 'x'),
      );
      expect(out.statusCode, 200);
      expect(executions, 0);
    });

    test('429 com Retry-After reenvia e devolve 200 na segunda tentativa', () async {
      var executions = 0;
      final interceptor = HttpRateLimitInterceptor(
        executeRequest: (r) async {
          executions++;
          if (executions == 1) {
            return const ResponseData(
              statusCode: 429,
              headers: {'retry-after': '0'},
              body: null,
            );
          }
          return const ResponseData(statusCode: 200, headers: {}, body: 'ok');
        },
      );
      await interceptor.interceptRequest(request: req);
      final out = await interceptor.interceptResponse(
        response: const ResponseData(
          statusCode: 429,
          headers: {'retry-after': '0'},
          body: null,
        ),
      );
      expect(out.statusCode, 200);
      expect(out.body, 'ok');
      expect(executions, 2);
    });

    test('terceira resposta 429 consecutiva lança RateLimitExceededException', () async {
      var executions = 0;
      final interceptor = HttpRateLimitInterceptor(
        executeRequest: (r) async {
          executions++;
          return const ResponseData(
            statusCode: 429,
            headers: {'retry-after': '0'},
            body: null,
          );
        },
      );
      await interceptor.interceptRequest(request: req);
      await expectLater(
        interceptor.interceptResponse(
          response: const ResponseData(
            statusCode: 429,
            headers: {'retry-after': '0'},
            body: null,
          ),
        ),
        throwsA(isA<RateLimitExceededException>()),
      );
      expect(executions, 2);
    });

    test('sem request em cache lança ao tentar reenviar após 429', () async {
      final interceptor = HttpRateLimitInterceptor(
        executeRequest: (r) async => const ResponseData(
          statusCode: 200,
          headers: {},
          body: null,
        ),
      );
      await expectLater(
        interceptor.interceptResponse(
          response: const ResponseData(
            statusCode: 429,
            headers: {'retry-after': '0'},
            body: null,
          ),
        ),
        throwsA(isA<RateLimitExceededException>()),
      );
    });
  });
}
