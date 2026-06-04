// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_traefik_suppression.dart';

class TraefikResult {
  const TraefikResult({
    this.router,
    this.serviceTarget,
    this.entrypoint,
    this.middleware,
    this.upstreamHost,
    this.upstreamUri,
    this.provider,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? router;
  final String? serviceTarget;
  final String? entrypoint;
  final String? middleware;
  final String? upstreamHost;
  final String? upstreamUri;
  final String? provider;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

class TraefikCallResult<T> {
  const TraefikCallResult({required this.value, this.result});
  final T value;
  final TraefikResult? result;
}

Future<T> tracedTraefik<T>({
  required String operation,
  required Future<TraefikCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (traefikInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_traefik');
  final span = t.startSpan('traefik $operation', kind: SpanKind.server);
  try {
    span.addAttributes(
        OTel.attributes([OTel.attributeString('http.route', operation)]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.router != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.router', res.router!)]));
      }
      if (res.serviceTarget != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.service', res.serviceTarget!)]));
      }
      if (res.entrypoint != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.entrypoint', res.entrypoint!)]));
      }
      if (res.middleware != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.middleware', res.middleware!)]));
      }
      if (res.upstreamHost != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('server.address', res.upstreamHost!)]));
      }
      if (res.upstreamUri != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('url.full', res.upstreamUri!)]));
      }
      if (res.provider != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.provider', res.provider!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeInt('http.response.status_code', res.statusCode!)]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTel.attributes(
            [OTel.attributeString('traefik.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTel.attributes([
          OTel.attributeString(
            ErrorResource.errorType.key,
            res.errorCode ?? 'traefik.error',
          )
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
