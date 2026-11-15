# Architecture

Working uses a feature-first structure with explicit boundaries between application composition, shared infrastructure, and feature code.

## Source layout

```text
lib/
  main.dart
  app/
    app.dart
  core/
    constants/
    theme/
    utils/
  features/
    activities/
      data/
        activity_repository.dart
        activity_export_service.dart
      domain/
        models/
      presentation/
        controllers/
        pages/
```

## Responsibilities

- **App:** configures the root widget, locale, and theme.
- **Core:** contains app-wide constants, theme, and small stateless utilities.
- **Activities domain:** contains activity and entry entities; it must not depend on Flutter UI or persistence plugins.
- **Activities data:** owns local persistence and CSV/share integration.
- **Activities presentation:** owns screen state orchestration in the controller and renders UI in pages/widgets.

## Rules

- Keep platform APIs and serialization out of widgets.
- Keep state transitions and validation in the feature controller or domain layer, not in build methods.
- Do not add placeholder features or duplicate screens. Create a feature folder only when it has a real user-facing responsibility.
- Prefer immutable values at layer boundaries and validate external data before using it.
- Add tests for business rules, serialization, and date formatting.
- Keep `main.dart` limited to application bootstrap.
