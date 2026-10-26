# Plan Search and Pagination Implementation

> **Status (Oct 2026): partly historical.** The search UI and the tabbed hub described below
> (`PlansScreen`, `MyPlansTab`, `FindPlansTab`, `PlanSearchDelegate`, `planSearchProvider`) are no
> longer mounted anywhere — they are only exported from `lib/features/plans/plans.dart` and push
> routes that no longer exist (`/plans/info`, `/plans/details`). Plan browsing and search now live in
> `lib/features/practice` (`AllPlansScreen`, `PlansSearchScreen` → `seriesSearchProvider`).
>
> Still live: `findPlansPaginatedProvider` (practice `SelectPlanScreen`) and
> `myPlansPaginatedProvider` (home plan lists, practice routine screens, group event detail).
> Both now seed their first page from the Hive cache (`PlansLocalDatasource`) before fetching.
> `MyPlansNotifier.loadInitial()` goes through the cache-first `getUserPlans()`, so only
> `refresh()` (→ `refreshUserPlans()`) is guaranteed to hit the network.

## Overview

Implemented a production-ready plan search feature with debounced API calls and infinite scroll pagination for both search results and the Find Plans tab.

## Implementation Summary

### 1. Search State Management

**File**: `lib/features/plans/presentation/providers/plan_search_provider.dart`

- Created `PlanSearchState` class to manage:

  - Search query
  - Results list
  - Loading states (initial and loadMore)
  - Error handling
  - Pagination state (hasMore, skip)

- Implemented `PlanSearchNotifier` with:
  - 500ms debounce using `dart:async Timer`
  - Automatic cancellation of pending timers on new queries
  - Pagination support (20 items per page)
  - Load more functionality
  - Retry mechanism
  - Proper cleanup on dispose

### 2. Find Plans Pagination

**File**: `lib/features/plans/presentation/providers/find_plans_paginated_provider.dart`

- Created `FindPlansState` class for paginated plans
- Implemented `FindPlansNotifier` with:
  - Initial data loading
  - Infinite scroll with load more
  - Pull-to-refresh support
  - Error handling and retry
  - 20 items per page

### 3. Search UI - SearchDelegate

**File**: `lib/features/plans/presentation/search/plan_search_delegate.dart`

- Extended Flutter's `SearchDelegate<Plan?>`
- Features:
  - Real-time search with debouncing
  - Loading indicator during API calls
  - Empty states for no query and no results
  - Error state with retry button
  - Infinite scroll (loads more at 200px from bottom)
  - Uses `PlanCard` widget for consistency
  - Navigation to plan details on tap

### 4. Find Plans Tab Update

**File**: `lib/features/plans/presentation/widgets/find_plan_tab.dart`

- Converted from `ConsumerWidget` to `ConsumerStatefulWidget`
- Added `ScrollController` for infinite scroll detection
- Integrated with `findPlansPaginatedProvider`
- Features:
  - Loads more plans at 200px from bottom
  - Pull-to-refresh support
  - Loading indicator at bottom during pagination
  - Maintains all existing error/empty states

### 5. My Plans Tab Update

**File**: `lib/features/plans/presentation/widgets/my_plan_tab.dart`

- Converted from `ConsumerWidget` to `ConsumerStatefulWidget`
- Added `ScrollController` for infinite scroll detection
- Integrated with `myPlansPaginatedProvider`
- Features:
  - Loads more plans at 200px from bottom
  - Pull-to-refresh support
  - Loading indicator at bottom during pagination
  - Maintains all existing error/empty states including "Browse Plans" CTA

### 6. My Plans Pagination Provider

**File**: `lib/features/plans/presentation/providers/my_plans_paginated_provider.dart`

- Created `MyPlansState` class for paginated user plans
- Implemented `MyPlansNotifier` with:
  - Initial data loading
  - Infinite scroll with load more
  - Pull-to-refresh support
  - Error handling and retry
  - Tracks total count from API
  - 20 items per page

### 7. Plans Screen Integration

**File**: `lib/features/plans/presentation/screens/plans_screen.dart`

- Integrated search button with `showSearch()`
- Removed old commented-out search code
- Cleaned up unused imports

### 8. Repository Enhancements

**Files**:

- `lib/features/plans/data/repositories/plans_repository_impl.dart`
- `lib/features/plans/data/repositories/user_plans_repository.dart`

Plans Repository:

- Updated `getPlans()` method to accept:
  - `search` parameter for text query
  - `skip` parameter for pagination offset
  - `limit` parameter for page size

User Plans Repository:

- Updated `getUserPlans()` method to accept:
  - `skip` parameter for pagination offset
  - `limit` parameter for page size

### 9. Datasource Updates

**Files**:

- `lib/features/plans/data/datasource/plans_remote_datasource.dart`
- `lib/features/plans/data/datasource/user_plans_remote_datasource.dart`

Both datasources updated to:

- Build query parameters dynamically
- Support skip/limit for pagination
- Maintain existing language filtering

### 10. Provider Updates

**Files**:

- `lib/features/plans/presentation/providers/plans_providers.dart`
- `lib/features/plans/presentation/providers/user_plans_provider.dart`

Plans Providers:

- Added `findPlansPaginatedProvider` for Find Plans tab
- Added `planSearchProvider` for search functionality

User Plans Provider:

- Added `myPlansPaginatedProvider` for My Plans tab
- All providers use language from `localeProvider`

## Technical Decisions

### Debouncing

- Used `dart:async Timer` (no external dependencies)
- 500ms delay balances responsiveness and API efficiency
- Cancels previous timers when query changes

### Pagination

- 20 items per page (good balance for mobile)
- Loads more at 200px from bottom threshold
- Separate loading indicators for initial and pagination

### Architecture

- Clean separation of concerns
- StateNotifier for complex state management
- Reusable components (`PlanCard`)
- Consistent error/empty states across features

### User Experience

- Immediate visual feedback on query change
- Smooth infinite scroll
- Pull-to-refresh support
- Clear loading, error, and empty states
- Native SearchDelegate UI

## API Integration

Find Plans and search go through `GetPlansUseCase` (`domain/usecases/plans_usecases.dart`) →
`PlansRepositoryImpl.getPlans()` → `PlansRemoteDatasource`:

```dart
getPlansUseCase(GetPlansParams(
  language: languageCode,
  search: query,      // Text search query (search only)
  skip: offset,       // Pagination offset
  limit: pageSize,    // Items per page (20)
));
```

My Plans calls `UserPlansRepositoryInterface.getUserPlans(language:, skip:, limit:)` directly
(and `refreshUserPlans(...)` on pull-to-refresh).

## Files Created

1. `lib/features/plans/presentation/providers/plan_search_provider.dart` - Search state management
2. `lib/features/plans/presentation/providers/find_plans_paginated_provider.dart` - Find Plans pagination
3. `lib/features/plans/presentation/providers/my_plans_paginated_provider.dart` - My Plans pagination
4. `lib/features/plans/presentation/search/plan_search_delegate.dart` - Search UI
5. `docs/implementation/PLAN_SEARCH_PAGINATION.md` (this file)

## Files Modified

1. `lib/features/plans/presentation/screens/plans_screen.dart` - Search integration
2. `lib/features/plans/presentation/widgets/find_plan_tab.dart` - Added pagination
3. `lib/features/plans/presentation/widgets/my_plan_tab.dart` - Added pagination
4. `lib/features/plans/presentation/providers/plans_providers.dart` - Added Find Plans provider
5. `lib/features/plans/presentation/providers/user_plans_provider.dart` - Added My Plans provider
6. `lib/features/plans/data/repositories/plans_repository_impl.dart` - Added search/pagination params
7. `lib/features/plans/data/repositories/user_plans_repository.dart` - Added pagination params
8. `lib/features/plans/data/datasource/plans_remote_datasource.dart` - Query param builder
9. `lib/features/plans/data/datasource/user_plans_remote_datasource.dart` - Query param builder

## Testing Recommendations

1. **Search Functionality**

   - Test debouncing: type quickly and verify only one API call
   - Test empty query handling
   - Test no results state
   - Test error handling and retry

2. **Pagination**

   - Test initial load
   - Test scroll to bottom triggers load more
   - Test end of results (no more data)
   - Test pull-to-refresh

3. **Performance**

   - Verify no memory leaks (proper disposal)
   - Test with slow network
   - Test with large result sets

4. **Edge Cases**
   - Empty search results
   - Network errors
   - Rapid query changes
   - Scroll during loading

## Future Enhancements

1. Add search filters (difficulty, duration, etc.)
2. Add search history
3. Add search suggestions
4. Cache search results
5. Add analytics for popular searches
6. Optimize image loading in results
