import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final screenCacheStoreProvider = Provider<ScreenCacheStore>((ref) {
  return ScreenCacheStore();
});
