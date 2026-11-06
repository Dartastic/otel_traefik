// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_traefik/otel_traefik.dart';
import 'package:test/test.dart';

void main() {
  group('otel_traefik', () {
    test('suppression toggles in zone', () async {
      expect(traefikInstrumentationSuppressed(), isFalse);
      await runWithoutTraefikInstrumentationAsync(() async {
        expect(traefikInstrumentationSuppressed(), isTrue);
      });
      expect(traefikInstrumentationSuppressed(), isFalse);
    });

    test('TraefikResult fields default null', () {
      const r = TraefikResult();
      expect(r.statusCode, isNull);
    });
  });
}
