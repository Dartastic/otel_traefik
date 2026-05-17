# otel_traefik

Dartastic OpenTelemetry bridge for Traefik (edge router / API gateway).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_traefik/otel_traefik.dart';

await tracedTraefik<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return TraefikCallResult(value: r, result: TraefikResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutTraefikInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
