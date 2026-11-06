// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_traefik_suppression.dart';

class TraefikResult {
  /// Creates a result.
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

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class TraefikCallResult<T> {
  /// Creates a call result.
  const TraefikCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final TraefikResult? result;
}

Future<T> tracedTraefik<T>({
  required String operation,
  required Future<TraefikCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (traefikInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_traefik');
  final span = t.startSpan('traefik $operation', kind: SpanKind.server);
  try {
    span.addAttributes(
        OTelAPI.attributes([OTelAPI.attributeString('http.route', operation)]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.router != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.router', res.router!)]));
      }
      if (res.serviceTarget != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.service', res.serviceTarget!)]));
      }
      if (res.entrypoint != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.entrypoint', res.entrypoint!)]));
      }
      if (res.middleware != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.middleware', res.middleware!)]));
      }
      if (res.upstreamHost != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('server.address', res.upstreamHost!)]));
      }
      if (res.upstreamUri != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('url.full', res.upstreamUri!)]));
      }
      if (res.provider != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.provider', res.provider!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('traefik.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            ErrorAttributes.errorType.key,
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
