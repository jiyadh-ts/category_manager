# Category Manager

Flutter machine-test app for **mock login** (JSONPlaceholder) and **offline nested categories** (Drift/SQLite). State uses Cubit; navigation uses GoRouter.

## Features

- Login with JSONPlaceholder **username or email** (no real password API)
- Session saved in SharedPreferences (skip login after restart)
- Logout clears session only; categories stay in SQLite
- Profile loaded from `GET /users/{id}`
- Unlimited nested categories, scoped per logged-in user
- Add / edit / delete / search / expand-collapse
- Per-level **Load more** with Show filter **10 / 20 / 50 / All**
- Duplicate sibling-name validation (trim + case-insensitive)
- Cascade delete of subcategories
- Categories persist after app restart

## Prerequisites

- Flutter SDK (stable)
- Android emulator, iOS simulator, or a device
- Internet access for JSONPlaceholder (login + profile)

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Android needs internet permission for the API (already configured in a typical Flutter project).

### Code generation

Drift generates `lib/core/database/app_database.g.dart`. Re-run build_runner after changing the database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Tests

```bash
flutter test
```

Covers helpers (duplicates, tree, search, path, paging slices), session storage, and in-memory Drift (insert, isolation, cascade delete).

## How to understand the code

Start here:

1. [`lib/main.dart`](lib/main.dart) — creates Dio, Drift, repositories, Cubits, and the app
2. [`lib/routes/app_router.dart`](lib/routes/app_router.dart) — GoRouter + auth redirect
3. Feature Cubits — UI calls these; they call repositories

```
UI (pages/widgets)
  -> Cubit
    -> Repository
      -> Dio (auth/profile)  or  Drift SQLite (categories)
```

| Path | Role |
|------|------|
| `lib/core/database/` | Drift SQLite (`AppDatabase`) |
| `lib/core/storage/` | SharedPreferences session |
| `lib/features/auth/` | Mock login |
| `lib/features/profile/` | Profile from API |
| `lib/features/categories/` | Category CRUD + tree UI |
| `…/domain/category_helpers.dart` | Tree build, search, paging helpers |
| `…/presentation/cubit/` | Cubit + Equatable states |

Each feature: **presentation** → **domain** → **data**. No service locator; providers in `main.dart`.

## Architecture notes

### State management

Cubit (not Bloc events) + Equatable:

- `AuthCubit` — users list, login, logout, restore session
- `ProfileCubit` — load profile, retry
- `CategoryCubit` — load tree, CRUD, search, expand, load-more

Widgets never query SQLite/Dio directly.

### Local database

**Drift + SQLite** table `categories`:

| Column | Notes |
|--------|--------|
| `id` | Auto-increment PK |
| `userId` | Owner (JSONPlaceholder user id) |
| `name` | Category name |
| `parentId` | Null = root; else parent row |
| `createdAt` | Timestamp |

Rows are filtered by `userId`. SharedPreferences stores only login session (`userId`, `username`).

### Category hierarchy

Stored as a **flat adjacency list** (`parentId`). On load, the repository reads all rows for the user and `buildCategoryTree` builds the nested tree in memory. `CategoryTile` renders one node and its children recursively.

Delete uses a children-first id list so foreign keys stay valid.

### Search and pagination

SQLite returns the full list for the user; the Cubit keeps that tree and applies **in-memory** per-level paging:

1. **Roots** — show first *N*; Load more raises visible count
2. **Children** — when expanded, show first *N* direct children; Load more under that parent only
3. **Search** — collect name matches, page them, rebuild a small tree with ancestors (`buildTreeFromMatches`) so deep hits stay visible

*N* comes from Show: **10 / 20 / 50 / All** (default 10). Bottom nav: **Categories** | **Profile**.

### API (auth / profile)

Base: `https://jsonplaceholder.typicode.com`

1. `GET /users` — login matches username **or** email (case-insensitive)
2. `GET /users/{id}` — profile fields from the response

Not a real auth server; errors distinguish invalid login vs network/timeout.
