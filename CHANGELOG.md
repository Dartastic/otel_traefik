# Changelog

## [0.1.0-beta.1] - 2026-06-04

### Added

- Initial release.
- `tracedTraefik<T>(...)` — wraps a otel_traefik call in a CLIENT-kind span
  with vendor-specific attributes.
- Zone-scoped suppression via `runWithoutTraefikInstrumentation()` / `Async()`.
