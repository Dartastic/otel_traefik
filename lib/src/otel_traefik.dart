// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

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
    span.setStringAttribute('http.route', '$operation');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.router != null) {
        span.setStringAttribute('traefik.router', res.router!);
      }
      if (res.serviceTarget != null) {
        span.setStringAttribute('traefik.service', res.serviceTarget!);
      }
      if (res.entrypoint != null) {
        span.setStringAttribute('traefik.entrypoint', res.entrypoint!);
      }
      if (res.middleware != null) {
        span.setStringAttribute('traefik.middleware', res.middleware!);
      }
      if (res.upstreamHost != null) {
        span.setStringAttribute('server.address', res.upstreamHost!);
      }
      if (res.upstreamUri != null) {
        span.setStringAttribute('url.full', res.upstreamUri!);
      }
      if (res.provider != null) {
        span.setStringAttribute('traefik.provider', res.provider!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('traefik.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'traefik.error',
        );
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
