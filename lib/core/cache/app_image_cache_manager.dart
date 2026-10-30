import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// One disk store for every network image, under the default key so files
/// cached before it existed stay valid. Nothing else may build a default
/// manager, or two stores would share one database.
final CacheManager appImageCacheManager = CacheManager(
  Config(
    DefaultCacheManager.key,
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 1500,
  ),
);
