/// Upper bound used when clamping like counts after optimistic decrements.
const int connectLikeCountMax = 1 << 31;

int clampConnectLikeCount(int count) => count.clamp(0, connectLikeCountMax);

bool resolveOptimisticIsLiked({
  required bool serverLikedByMe,
  required bool? likedOverride,
}) => likedOverride ?? serverLikedByMe;

int resolveOptimisticLikeCount({
  required int serverLikeCount,
  required bool serverLikedByMe,
  required bool? likedOverride,
  required int? likeCountOverride,
}) {
  final base = likeCountOverride ?? serverLikeCount;
  if (likedOverride == null) return base;
  if (likedOverride && !serverLikedByMe) return base + 1;
  if (!likedOverride && serverLikedByMe) {
    return clampConnectLikeCount(base - 1);
  }
  return base;
}

int nextLikeCountAfterToggle({
  required int currentCount,
  required bool wasLiked,
}) => wasLiked ? clampConnectLikeCount(currentCount - 1) : currentCount + 1;

/// Local optimistic UI state shared by post and comment like buttons.
class ConnectOptimisticLikeState {
  bool? likedOverride;
  int? likeCountOverride;
  bool isSubmitting = false;

  bool isLiked(bool serverLikedByMe) => resolveOptimisticIsLiked(
    serverLikedByMe: serverLikedByMe,
    likedOverride: likedOverride,
  );

  int likeCount({
    required int serverLikeCount,
    required bool serverLikedByMe,
  }) => resolveOptimisticLikeCount(
    serverLikeCount: serverLikeCount,
    serverLikedByMe: serverLikedByMe,
    likedOverride: likedOverride,
    likeCountOverride: likeCountOverride,
  );

  void beginToggle(bool wasLiked) {
    isSubmitting = true;
    likedOverride = !wasLiked;
  }

  void revert(bool wasLiked) {
    isSubmitting = false;
    likedOverride = wasLiked;
  }

  void commitSuccess({
    required int serverLikeCount,
    required bool serverLikedByMe,
  }) {
    isSubmitting = false;
    likeCountOverride = likeCount(
      serverLikeCount: serverLikeCount,
      serverLikedByMe: serverLikedByMe,
    );
  }
}
