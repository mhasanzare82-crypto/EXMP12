# Project architecture

The app uses a feature-first, layered Flutter structure. Keep each responsibility in its own file and avoid putting feature logic in `main.dart`.

## Structure

```text
lib/
  main.dart                         # Application entry point only
  app/
    app.dart                         # MaterialApp composition
  core/
    constants/
      app_constants.dart             # App-wide constants
    theme/
      app_theme.dart                 # Global theme
    services/                        # Shared platform/API services
    errors/                          # Shared error types and handling
    utils/                           # Small reusable utilities
  features/
    activities/
      data/                          # Local persistence and CSV export
      domain/models/                 # Activity and count-entry models
      presentation/
        pages/                       # Activity tracking screen
        widgets/                     # Activity-specific widgets
        state/                       # Feature state/controllers
    home/                            # Reserved for a future dashboard
      data/
      domain/
      presentation/
        pages/                       # Full screens
        widgets/                     # Home-only widgets
        state/                       # State/controller for the feature

## Rules for future changes

- One screen per page file; reusable screen-specific components live in that feature's `widgets/` folder.
- Keep API/data access in `data/`, business rules in `domain/`, and UI in `presentation/`.
- Put genuinely shared code in `core/`; do not couple one feature to another feature's internals.
- Add each new feature as its own folder under `features/<feature_name>/`.
- Keep `main.dart` limited to bootstrapping the app.
- Add dependencies only when the selected feature actually requires them.
