# Category Manager

A Flutter machine-test app for nested category management with mock login.

The goal of this project is readable, interview-friendly code: Cubit for state, Drift/SQLite for offline categories, Dio for JSONPlaceholder users, and GoRouter for three screens.

## Features

- Mock login using JSONPlaceholder username **or** email
- Login session saved with SharedPreferences (skip login after restart)
- Logout clears the saved session and returns to login
- Profile page loaded from the same API
- Unlimited nested categories stored locally (scoped per logged-in user)
- Add, edit, delete, search, expand/collapse
- Per-level **Load more** with a page-size filter (**10 / 20 / 50 / All**)
- Duplicate sibling-name validation
- Cascade delete of subcategories
- Categories persist in SQLite after app restart

## Architecture

The app uses a simple feature-based layout. Each feature has:

- **presentation**: pages, widgets, Cubit, state
- **domain**: entities and repository interfaces
- **data**: repository implementations, API or database access

```
UI (pages/widgets)
  -> Cubit
    -> Repository
      -> Dio API  or  Drift SQLite
```

There is no service locator and no Bloc event classes. Objects are created in `lib/main.dart` and provided with `RepositoryProvider` / `BlocProvider`.

## Folder structure

```
lib/
  main.dart
  core/database/          Drift database
  core/errors/            AppException
  core/storage/           SharedPreferences session helper
  features/auth/          Mock login
  features/profile/       User profile
  features/categories/    Category CRUD and tree UI
  routes/app_router.dart  GoRouter
```

## Database design

One SQLite table named `categories`:

| Column    | Type     | Notes                              |
|-----------|----------|------------------------------------|
| id        | integer  | Primary key, auto increment        |
| userId    | integer  | JSONPlaceholder owner user id      |
| name      | text     | Category name                      |
| parentId  | integer  | Null for root categories           |
| createdAt | datetime | Created timestamp                  |

Foreign keys are enabled. `parentId` points at another row in the same table.

The database stores a **flat list**. The tree is built in memory by `buildCategoryTree` in `category_helpers.dart`.

Rules:

- Two siblings cannot share the same name (trim + case-insensitive).
- The same name can exist under different parents.
- Delete removes the category and all descendants in one transaction.
- Edit changes the name only. Subcategories are added with “Add subcategory”.

## Cubit explanation

Each feature uses Cubit (not Bloc events) and Equatable states:

- `AuthCubit`: load users, mock login (username/email), logout
- `ProfileCubit`: load `/users/{id}`, retry
- `CategoryCubit`: load, add, update, delete, search, load-more, expand/collapse

Typical states: Initial, Loading, Success/Loaded, Error.

Widgets never query the database. They call Cubit methods and render the current state.

Login stores only `userId` and `username` in SharedPreferences. On startup, `AuthCubit` restores that session, so GoRouter opens CategoryPage instead of LoginPage. Logout clears the saved session. Categories stay in SQLite.

## API explanation

Base URL: `https://jsonplaceholder.typicode.com`

JSONPlaceholder is **not a real authentication API**. Login is mocked:

1. `GET /users` loads the user list.
2. The user enters a username **or** email.
3. Login matches against either field (case-insensitive).
4. The app stores only `userId` and `username`.
5. Errors are precise (invalid username/email, no internet, timeout).

Profile uses `GET /users/{id}` and displays name, username, email, phone, website, and company fields from the response. Nothing is hardcoded.

## Recursive category implementation

1. Load all rows from SQLite.
2. Group them by `parentId`.
3. Recursively attach children, starting from `parentId == null`.
4. `CategoryTile` draws one node, then builds child `CategoryTile` widgets.

Search also walks the tree: a parent stays visible if its name matches or any descendant matches.

## Search and load more

Listing and search use the in-memory hierarchy (still filtered by `userId` in SQLite). Pagination is **per sibling level**, not a flat mix of parents and nested modules:

1. **Roots:** show the first *N* parent folders; **Load more** reveals the next *N* roots.
2. **Children:** when a folder is expanded, show the first *N* direct children; **Load more** under that parent loads the next *N* siblings only.
3. **Search:** collect name matches, show the first *N* (with ancestor path rebuilt), then **Load more** for the next *N* matches.

*N* comes from the **Show** filter on the categories page: **10**, **20**, **50**, or **All** (everything at once, no Load more). Default is 10.

Bottom navigation has two tabs only: **Categories** and **Profile** (search lives on the categories page).

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Internet permission is required on Android for JSONPlaceholder.

## Code generation

Drift generates `lib/core/database/app_database.g.dart`.

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after changing the database schema.

## Testing

```bash
flutter test
```

Tests cover:

- Duplicate sibling validation
- Tree construction
- Recursive search
- Load-more sibling slicing helpers
- Parent validation
- Category path generation
- In-memory database insert, duplicate rejection, cascade delete, and per-user isolation
