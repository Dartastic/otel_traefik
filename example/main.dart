// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_traefik/otel_traefik.dart';

/// Traces Traefik calls with OpenTelemetry.
///
/// `otel_traefik` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Traefik call in
/// [tracedTraefik]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'traefik-example');

  // Traces a Traefik call.
  final traefikId = await tracedTraefik<String>(
    operation: 'create',
    invoke: () async {
      // Make the Traefik call here, then report what it returned.
      const id = 'traefik_8f3a2c';
      return const TraefikCallResult(
          value: id,
          result: TraefikResult(
              router: 'example',
              serviceTarget: 'example',
              entrypoint: 'example',
              middleware: 'example',
              upstreamHost: 'api.example.com',
              upstreamUri: 'example',
              provider: 'example',
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedTraefik create returned $traefikId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTraefikInstrumentationAsync.
  await runWithoutTraefikInstrumentationAsync(
    () => tracedTraefik<String>(
      operation: 'create',
      invoke: () async {
        const id = 'traefik_8f3a2c';
        return const TraefikCallResult(
            value: id,
            result: TraefikResult(
                router: 'example',
                serviceTarget: 'example',
                entrypoint: 'example',
                middleware: 'example',
                upstreamHost: 'api.example.com',
                upstreamUri: 'example',
                provider: 'example',
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
