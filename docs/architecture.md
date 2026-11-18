# Architecture

> Status: **draft for review**.

SpendWise IQ uses a **feature-first, layered** structure. Each feature owns its own domain, data and presentation code. The goal is a codebase that is easy to test, easy to navigate, and small enough per file to review.

## Decisions at a glance

| Topic | Decision |
|---|---|
| Structure | Feature-first, with `domain`, `data` and `presentation` per feature |
| State management | Cubit (`flutter_bloc`), `equatable` for state |
| Navigation | `go_router` |
| Dependency wiring | Constructors + `RepositoryProvider` / `BlocProvider`. No `get_it` for now. |
| Errors | Use cases return a small sealed `Result<T>`. No `dartz` / `fpdart`. |
| Code generation | Only what drift needs. No `freezed` or `json_serializable`. |
| Use cases | Only for real logic or validation, not as pass-throughs |
| Money | Integer minor units (cents), single currency in the MVP |
| Language | English only in the MVP. Failures carry codes, not user-facing text. |

## Principles

1. **Feature-first.** Code is grouped by what it does for the user (scan, expenses, categories), not by technical type.
2. **Dependencies point inward.** `presentation` and `data` both depend on `domain`. `domain` depends on nothing but Dart.
3. **Add structure when it earns its place.** No layer, class or file exists just to match a diagram.
4. **Small files, reusable widgets.** Split before a file becomes hard to read (see [File size](#file-size-and-widgets)).
5. **Offline-first.** The local database is the source of truth. A server, if added later, plugs in behind the repository.
6. **Scanning is optional.** Every expense can be entered by hand, and the app never requires camera permission. Scan is a shortcut into the same add-expense form, not a separate path.
7. **Feedback through snackbars.** Results of user actions ("Expense saved", "Couldn't save") are shown as snackbars.

## Folder structure

```
lib/
├── main.dart
├── app/                     # MaterialApp, go_router setup, dependency wiring
├── core/                    # Non-UI infrastructure shared by all features
│   ├── theme/               # colors, spacing, typography, ThemeData
│   ├── database/            # drift database setup
│   ├── errors/              # Result and AppFailure types
│   └── utils/               # pure helpers (formatters, extensions)
├── shared/
│   └── widgets/             # reusable UI used by two or more features
└── features/
    └── <feature>/
        ├── domain/
        │   ├── entities/        # plain Dart objects (Expense, Category)
        │   ├── repositories/    # abstract interfaces
        │   └── usecases/        # only where there is real logic (see below)
        ├── data/
        │   ├── datasources/     # wrappers around plugins and I/O
        │   ├── mappers/         # database row <-> entity conversion
        │   └── repositories/    # implementations of the domain interfaces
        └── presentation/
            ├── cubit/           # <name>_cubit.dart + <name>_state.dart
            ├── pages/           # route-level screens
            └── widgets/         # widgets used only by this feature
```

Create a feature folder when work on it starts, and only the sub-folders it needs.

Planned features: `onboarding`, `scan`, `expenses`, `categories`, `dashboard`, `export`, `security`, and a small `settings` (presentation only at first). Budgets are planned after the MVP.

## Layer responsibilities

| Layer | Contains | May depend on | Never depends on |
|---|---|---|---|
| **domain** | Entities, repository interfaces, use cases, business rules (parsing, categorizing, validation, report grouping) | Dart only | Flutter, drift, ML Kit, other layers |
| **data** | Datasources, mappers, repository implementations | its own domain, plugins, drift | presentation |
| **presentation** | Cubits, states, pages, widgets | domain (entities, use cases, repository interfaces) | data |

The domain layer is plain Dart so the important logic can be unit tested without a device.

## Data flow

```
Datasource  ->  Repository  ->  Use case  ->  Cubit  ->  UI
 (plugin /      (implements     (business     (state)    (widgets)
  database)      domain          logic)
                 interface)
```

- **Datasource** talks to one external thing: drift tables, ML Kit, the camera, `local_auth`, the file system.
- **Repository** implements the domain interface, maps data to entities, and is the only place that knows where data comes from.
- **Use case** holds business logic and validation, and may combine several repositories.
- **Cubit** holds UI state and calls use cases (or repositories, see below). It emits states.
- **UI** renders state and calls cubit methods. It contains no business logic.

### When a use case is required

A use case is added only when it does more than forward a call.

- **Use one** for real logic, validation or orchestration. Example: `ScanReceipt` asks the OCR repository for text, runs the parser, and suggests a category. `SaveExpense` validates the expense before writing it.
- **Skip it** for plain reads and deletes. A cubit may call the repository interface directly for "list expenses" or "delete expense". A use case that only calls `repository.getExpenses()` is boilerplate.
- If a skipped use case later gains logic, introduce it then. Moving a call out of a cubit is a small change.

### Validation

- **Business rules** are checked in use cases. Examples: the amount is greater than zero, the date is not in the future, a category is set, a category name is not empty or a duplicate. This means saving goes through a use case even though it is a write.
- **Input parsing** stays in the form. The form turns the text "12.50" into a number and shows an error if it is not a number. It does not decide what a valid expense is.
- Because the rules live in the use case, they hold no matter which screen or feature calls it.
- A use case that depends on the current time takes a `DateTime Function() now` parameter, so tests do not depend on the real clock.

Starting rules for an expense (change them here when the product changes): amount greater than zero, date not in the future, category required, vendor optional (blank becomes "Unknown"), title optional (trimmed, at most 60 characters). Adding and editing share these rules (`ExpenseRules`).

Starting rules for a category: a name is required, at most 30 characters, and unique ignoring case and surrounding spaces (`CategoryRules`). The "Other" category is the fallback: it can be renamed but never deleted, and deleting any other category moves its expenses to it in one database transaction. The Categories screen uses `CreateCategory`, which reports a duplicate name. The expense form's New chip uses `FindOrCreateCategory`, which quietly selects the category the user already has.

### Datasources

Add a datasource class only where it wraps something we want to fake in tests or isolate from a plugin: ML Kit, camera, biometrics, PDF and CSV generation.

For drift, the generated database access object (DAO) already is the datasource, so it is not wrapped again.

### Entities and mappers

- Entities live in `domain` and are plain, immutable Dart classes (with `equatable`).
- Drift generates its own row classes in `data`. A mapper converts between a row and an entity. There are no separate DTO classes beyond that.
- Money is stored as **integer minor units** (cents), never `double`.
- Expenses and categories have a UUID `id` and `createdAt` / `updatedAt`, so a server can be added later. No sync logic exists until then.

### Changing the database

Testers and users already have data, so a table change must never lose it:

1. Change the table in `tables.dart`, raise `schemaVersion` in `app_database.dart`, and add the step to `onUpgrade` (for example `addColumn`).
2. Run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `app_database.g.dart`.
3. Add a test that opens a database in the old shape and checks the data survives (see `test/core/database/app_database_test.dart`). Remove the upgrade step and confirm the test fails.

### Receipt photos

The receipt photo is **not stored**. It is a temporary file used for text recognition and shown next to the review form so the user can compare. It is deleted when the user saves or cancels. An expense has no image field in the MVP. Keeping receipts as proof can be added later as an opt-in "Attach receipt" option.

## State management

- **Cubit** (`flutter_bloc`) per screen or feature. Use full Bloc only when events matter (for example a debounced search).
- State classes use `equatable`. Prefer a `sealed` class for loading, loaded and error, or one class with a `status` field for forms.
- `<name>_cubit.dart` and `<name>_state.dart` are separate files, not `part` files.
- Lists come from the repository as `Stream<List<Entity>>` (drift `watch`), so screens update when data changes.

## Errors

Use cases return a small sealed `Result<T>` from `core/errors`:

```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> { const Success(this.value); final T value; }
final class Failure<T> extends Result<T> { const Failure(this.failure); final AppFailure failure; }
```

- `AppFailure` is sealed: `ValidationFailure` (field and code), `StorageFailure`, `OcrFailure`, `UnknownFailure`.
- A validation error is an **expected outcome**, so it is a `Failure`, not an exception.
- Repositories **throw** for unexpected problems (disk error, OCR engine error). The use case catches them and returns a `Failure`.
- A cubit that calls a repository directly (plain reads and deletes) catches the exception and emits an error state.
- Failures carry **codes**, not text. The UI maps a code to a message, which keeps the domain free of user-facing strings and ready for translation.
- Cubits handle a `Result` with an exhaustive `switch`.

## Dependency wiring

Dependencies are passed through constructors. `app/` creates the database, datasources and repositories once and exposes them with `RepositoryProvider`. A cubit is created with `BlocProvider` near the screen that owns it, and receives its use cases built from the repositories. We do not add `get_it` unless wiring becomes repetitive (roughly a dozen use cases to hand-build) or something outside the widget tree needs a dependency. If we add it, registration stays manual, without `injectable`.

## Navigation

`go_router`, configured in `app/`.

- Redirects handle first launch (onboarding) and the biometric lock screen.
- Route paths are constants. Routes take ids as path parameters, not entity objects.

## Sharing code between features

- **Start inside the feature.** Promote code to `shared/widgets/` or `core/` when a **second** feature needs it.
- A feature may use another feature's **domain** (entities, repository interfaces, use cases). It must never import another feature's `data` or `presentation`.
- Shared entities live in the feature that owns the concept. Example: `Category` lives in `categories/domain` and is used by expenses and the dashboard.

## File size and widgets

- Aim for files under about **250 lines**, and split before **400**. Long files are a review signal, not a hard rule.
- One public widget per file. Name the file after the widget.
- Build UI from small widget classes, not long `_buildSomething()` methods, so pieces can be reused and tested.
- Keep a page file to layout and wiring. Move sections into `widgets/`.
- Reusable, feature-agnostic widgets (buttons, empty states, section headers) go to `shared/widgets/`.

## Safe areas and screen edges

Phones have notches, rounded corners and gesture bars, so content must never sit under them. Every screen follows these rules:

- A screen drawn **without an app bar** (welcome, onboarding, lock) wraps its content in `SafeArea`. A background color may fill the whole screen behind the status bar, but text, icons, images and buttons stay inside the safe area.
- A screen with an `AppBar` already handles the top. A page in a `Scaffold` with a bottom navigation bar already handles the bottom.
- A scrolling form outside the app shell (for example Add expense) wraps its list in `SafeArea(top: false)`, so the last button clears the gesture bar.
- Side insets matter in landscape. The app shell wraps its body in `SafeArea(top: false, bottom: false)`.
- Anything drawn over a page (buttons, a progress bar) applies `SafeArea` or `MediaQuery.paddingOf(context)` itself.
- Every new screen gets a test that simulates insets. See `test/app/safe_area_test.dart` and the `safePadding` option of `pumpRouterApp`.

## Naming

| Thing | File | Class |
|---|---|---|
| Entity | `expense.dart` | `Expense` |
| Repository interface | `expense_repository.dart` | `ExpenseRepository` |
| Repository implementation | `expense_repository_impl.dart` | `ExpenseRepositoryImpl` |
| Use case | `save_expense.dart` | `SaveExpense` (callable via `call()`) |
| Cubit and state | `expense_list_cubit.dart`, `expense_list_state.dart` | `ExpenseListCubit`, `ExpenseListState` |
| Page | `expense_list_page.dart` | `ExpenseListPage` |

## Testing

Tests mirror `lib/` under `test/`. We aim for 80% coverage by testing what matters, not every file.

| What | How |
|---|---|
| Domain logic (parser, categorizer, validation, report grouping, use cases) | Plain unit tests, no Flutter |
| Cubits | `bloc_test` with a fake repository |
| Repositories | Against an in-memory drift database |
| Reusable widgets in `shared/widgets` | Widget tests |
| Pages | Only where the screen has meaningful behavior |

CI enforces formatting, static analysis and the coverage gate. See [README](../README.md#continuous-integration).

## Example: scanning a receipt

```
ScanPage (UI)
  -> ScanCubit                        # where the scan is: working, preview, done, failed
    -> ScanReceipt (use case)         # pick, read, recover, discard
      -> ReceiptPhotoSource           # domain interface
        -> ImagePickerPhotoSource     # data: wraps image_picker
      -> ReceiptTextReader            # domain interface
        -> MlKitReceiptTextReader     # data: wraps google_mlkit_text_recognition
      -> ReceiptRows                  # domain: joins OCR lines at the same height into rows
      -> ParseReceipt                 # domain: finds vendor, date, total
      -> SuggestCategory              # domain: suggests a category the user has
```

The cubit emits a scanned result that fills the add-expense form, beside the receipt photo. The plugins sit behind two small interfaces, so everything else is tested with fakes and only the native ML Kit call needs a phone. The photo is temporary: it is deleted when the form closes, and whenever a scan fails or is left. After the user verifies it, saving goes through the `SaveExpense` use case, which validates the business rules and then writes through `ExpenseRepository`.

## Example: monthly report

```
ExportPage (UI)
  -> ExportCubit
    -> BuildMonthlyReport (use case)  # domain: groups a month's expenses by category and day
      -> ExpenseRepository            # reads the month's expenses
    -> ReportExporter (datasource)    # builds PDF or CSV bytes
    -> system share sheet             # share, or "Save to Files / Drive"
```

Grouping and totals are plain Dart and unit tested. The PDF and CSV generation sits behind the datasource. Sharing uses the system share sheet, so no custom download or storage-permission code is needed.
