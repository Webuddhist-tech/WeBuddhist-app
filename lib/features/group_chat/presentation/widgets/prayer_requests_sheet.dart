import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_delete_dialog.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/new_prayer_request_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_prompt.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_supporters_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing an event's prayer requests, with a prompt on top
/// that opens the composer.
class PrayerRequestsSheet extends ConsumerStatefulWidget {
  const PrayerRequestsSheet({super.key, required this.eventId});

  final String eventId;

  static Future<void> show(BuildContext context, {required String eventId}) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PrayerRequestsSheet(eventId: eventId),
    );
  }

  @override
  ConsumerState<PrayerRequestsSheet> createState() =>
      _PrayerRequestsSheetState();
}

class _PrayerRequestsSheetState extends ConsumerState<PrayerRequestsSheet> {
  final _sheetController = DraggableScrollableController();

  /// Owned by the draggable sheet; only listened to here.
  ScrollController? _listController;

  /// Two resting heights only: where it opens, and full. A drag in either
  /// direction snaps to the nearer one; a drag below the opening height
  /// dismisses.
  static const double _initialSize = 0.6;
  static const double _maxSize = 0.95;

  /// Read through the container: socket frames can land after the sheet's
  /// element is deactivated, where `ref.read` throws.
  late final ProviderContainer _providers;
  ScaffoldMessengerState? _messenger;
  AppLocalizations? _l10n;

  ChatLiveClient? _live;
  StreamSubscription<ChatLiveEvent>? _liveSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connectingLive = false;
  bool _hadLiveSession = false;
  bool _disposed = false;
  bool _composing = false;
  String? _roomId;

  static const double _loadMoreThreshold = 200;

  PrayerRequestsNotifier get _notifier =>
      _providers.read(prayerRequestsProvider(widget.eventId).notifier);

  String get _viewerId => _providers.read(userProvider).user?.id?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _providers = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
    _l10n = context.l10n;
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    unawaited(_tearDownLive());
    _listController?.removeListener(_onScroll);
    _sheetController.dispose();
    super.dispose();
  }

  void _attachList(ScrollController controller) {
    if (identical(controller, _listController)) return;
    _listController?.removeListener(_onScroll);
    _listController = controller..addListener(_onScroll);
  }

  void _onScroll() {
    final controller = _listController;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(_notifier.loadMore());
    }
  }

  /// Pixels dragged down past the opening height in the current gesture.
  /// The sheet cannot shrink below it, so this is how a slow pull-down
  /// still reads as "close".
  double _pulledBelow = 0;

  static const double _dismissPull = 60;

  void _onHeaderDragStart(DragStartDetails details) => _pulledBelow = 0;

  /// Lets the handle and title resize the sheet, not only the list.
  void _onHeaderDrag(DragUpdateDetails details) {
    if (!_sheetController.isAttached) return;
    final delta = details.primaryDelta ?? 0;
    final next = _sheetController.size - _sheetController.pixelsToSize(delta);
    if (next < _initialSize) {
      _pulledBelow += delta;
    } else {
      _pulledBelow = 0;
    }
    _sheetController.jumpTo(next.clamp(_initialSize, _maxSize));
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    if (!_sheetController.isAttached) return;
    final velocity = details.primaryVelocity ?? 0;
    final size = _sheetController.size;
    final atRest = size <= _initialSize + 0.02;
    if (atRest && (velocity > 700 || _pulledBelow >= _dismissPull)) {
      Navigator.of(context).pop();
      return;
    }
    final expand =
        velocity < -300 ||
        (velocity <= 300 && size > (_initialSize + _maxSize) / 2);
    unawaited(
      _sheetController.animateTo(
        expand ? _maxSize : _initialSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  /// Connects once the room is known; the socket is event-scoped. A closed
  /// room keeps its id so the loaded requests still render, so the status has
  /// to be checked too — otherwise the rebuild that follows `markClosed`
  /// reconnects to the room the server just shut.
  void _syncRoom(PrayerRequestsState state) {
    if (state.roomStatus == PrayerRoomStatus.closed) return;
    final roomId = state.roomId;
    if (roomId == null || roomId.isEmpty || roomId == _roomId) return;
    _roomId = roomId;
    unawaited(_ensureLiveConnected());
    unawaited(_markRoomRead());
  }

  Future<void> _tearDownLive() async {
    final sub = _liveSub;
    final live = _live;
    _liveSub = null;
    _live = null;
    await sub?.cancel();
    await live?.dispose();
  }

  Future<void> _ensureLiveConnected() async {
    if (_disposed || _live != null || _connectingLive || _roomId == null) {
      return;
    }
    _connectingLive = true;

    final String? token;
    try {
      token = await _providers.read(authServiceProvider).getValidAccessToken();
    } catch (_) {
      _connectingLive = false;
      _scheduleReconnect();
      return;
    }
    if (_disposed || token == null) {
      _connectingLive = false;
      return;
    }

    final uri = ChatLiveClient.liveUri(
      restBaseUrl: _providers.read(apiConfigProvider).baseUrl,
      token: token,
      eventId: widget.eventId,
      roomId: _roomId,
    );
    final client = ChatLiveClient();
    _live = client;
    _connectingLive = false;
    final reconnected = _hadLiveSession;
    _hadLiveSession = true;

    try {
      _liveSub = client
          .connect(uri)
          .listen(
            _onLiveEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: _scheduleReconnect,
            cancelOnError: true,
          );
    } catch (_) {
      _live = null;
      _scheduleReconnect();
      return;
    }

    if (reconnected) await _notifier.refreshLatest();
  }

  void _scheduleReconnect() {
    if (_disposed || _roomId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectTimer = Timer(chatReconnectDelay(_reconnectAttempt), () async {
      if (_disposed) return;
      await _tearDownLive();
      await _ensureLiveConnected();
    });
  }

  void _onLiveEvent(ChatLiveEvent event) {
    if (_disposed) return;
    _reconnectAttempt = 0;

    switch (event) {
      case ChatLiveMessageCreated(message: final json):
        if (json.isEmpty) return;
        _notifier.appendLive(ChatMessageDTO.fromJson(json));
        unawaited(_markRoomRead());
      case ChatLiveMessageUpdated(message: final json):
        if (json.isEmpty) return;
        _notifier.applyEdit(ChatMessageDTO.fromJson(json));
      case ChatLivePrayersUpdated(prayers: final updates):
        _notifier.applyPrayersUpdated(updates, viewerId: _viewerId);
      case ChatLiveMessageDeleted(messageId: final messageId):
        _notifier.applyDeletion(messageId);
      case ChatLiveRoomClosed():
        _notifier.markClosed();
        _roomId = null;
        _reconnectTimer?.cancel();
        unawaited(_tearDownLive());
      case ChatLiveError():
        final messenger = _messenger;
        final l10n = _l10n;
        if (messenger != null && l10n != null) {
          showChatSendError(messenger, l10n, event);
        }
      case ChatLiveRoomInfo():
      case ChatLiveReactionsUpdated():
      case ChatLiveTyping():
      case ChatLivePresence():
      case ChatLiveUnknown():
        break;
    }
  }

  /// Best-effort: the room also lists under chats, so keep its badge clear.
  Future<void> _markRoomRead() async {
    final roomId = _roomId;
    if (_disposed || roomId == null) return;
    await _providers.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }

  /// Opens the composer sheet; the notifier already holds the new or edited
  /// request when it pops, so only a new one has room bookkeeping left.
  Future<void> _openComposer({ChatMessageDTO? editing}) async {
    if (_composing) return;
    _composing = true;
    try {
      final result = await NewPrayerRequestSheet.show(
        context,
        eventId: widget.eventId,
        editing: editing,
      );
      if (!mounted || result == null || editing != null) return;
      unawaited(_markRoomRead());
      unawaited(_ensureLiveConnected());
      final list = _listController;
      if (list != null && list.hasClients) {
        list.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } finally {
      _composing = false;
    }
  }

  /// Confirms, then deletes one of the viewer's own requests. No success
  /// toast: the card leaving the list already shows the delete landed.
  Future<void> _deleteRequest(ChatMessageDTO request) async {
    final l10n = context.l10n;
    final confirmed = await confirmChatMessageDelete(
      context,
      title: l10n.event_prayer_delete_title,
      body: l10n.event_prayer_delete_body,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _notifier.delete(request.id);
    if (!mounted) return;
    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.event_prayer_delete_failed)),
      ),
      (_) {},
    );
  }

  ChatPrayerUserDTO? _viewerAsSupporter() {
    final user = _providers.read(userProvider).user;
    final id = user?.id?.trim() ?? '';
    if (id.isEmpty) return null;
    return ChatPrayerUserDTO(
      userId: id,
      name: joinChatName(user?.firstName, user?.lastName),
      avatarUrl: user?.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prayerRequestsProvider(widget.eventId));
    _syncRoom(state);

    final canCompose = state.roomStatus == PrayerRoomStatus.ready;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSize,
      minChildSize: _initialSize,
      maxChildSize: _maxSize,
      snap: true,
      expand: false,
      builder: (context, scrollController) {
        _attachList(scrollController);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Grey band sets the header apart from the list below.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onHeaderDragStart,
                  onVerticalDragUpdate: _onHeaderDrag,
                  onVerticalDragEnd: _onHeaderDragEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDragHandle(context),
                        _buildTitleBar(context, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (canCompose)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: PrayerRequestPrompt(
                      hintText: context.l10n.event_prayer_hint,
                      onTap: () => unawaited(_openComposer()),
                    ),
                  ),
                Expanded(
                  child: _buildBody(context, state, isDark, scrollController),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrayerRequestsState state,
    bool isDark,
    ScrollController scrollController,
  ) {
    final mutedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    final Widget? placeholder;
    if (state.roomStatus == PrayerRoomStatus.closed) {
      placeholder = _Notice(
        text: context.l10n.event_prayer_closed,
        color: mutedColor,
      );
    } else if (state.roomStatus == PrayerRoomStatus.failed ||
        (state.error != null && state.requests.isEmpty && state.hasLoaded)) {
      placeholder = _Notice(
        text: context.l10n.event_prayer_load_failed,
        color: mutedColor,
        actionLabel: context.l10n.group_chat_retry,
        onAction: () => unawaited(_notifier.retry()),
      );
    } else if (!state.hasLoaded ||
        (state.isLoading && state.requests.isEmpty)) {
      placeholder = const Center(child: CircularProgressIndicator());
    } else if (state.requests.isEmpty) {
      placeholder = _EmptyState(
        isDark: isDark,
        onAdd: () => unawaited(_openComposer()),
      );
    } else {
      placeholder = null;
    }

    // Even a placeholder scrolls, so dragging it still resizes the sheet.
    if (placeholder != null) {
      return LayoutBuilder(
        builder:
            (context, constraints) => ListView(
              controller: scrollController,
              children: [
                SizedBox(height: constraints.maxHeight, child: placeholder),
              ],
            ),
      );
    }

    final user = ref.watch(userProvider).user;
    final selfName = joinChatName(user?.firstName, user?.lastName);
    final viewerId = _viewerId;
    final viewerEmail = user?.email;
    final canEdit = state.roomStatus == PrayerRoomStatus.ready;
    final itemCount = state.requests.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= state.requests.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final request = state.requests[index];
        final isSelf = isSelfChatMessage(
          senderId: request.senderId,
          senderEmail: request.senderEmail,
          currentUserId: viewerId,
          currentUserEmail: viewerEmail,
        );
        final displayName =
            chatSenderDisplayName(
              messageName: request.senderName,
              senderEmail: request.senderEmail,
            ) ??
            (isSelf ? selfName : null) ??
            context.l10n.group_chat_unknown_sender;
        return PrayerRequestTile(
          key: ValueKey(request.id),
          request: request,
          displayName: displayName,
          avatarUrl:
              request.senderAvatarUrl ?? (isSelf ? user?.avatarUrl : null),
          isOwn: isSelf,
          onTogglePrayer:
              () => unawaited(
                _notifier.togglePrayer(
                  request.id,
                  viewer: _viewerAsSupporter(),
                ),
              ),
          onShowSupporters:
              () => unawaited(
                PrayerSupportersSheet.show(
                  context,
                  eventId: widget.eventId,
                  request: request,
                  displayName: displayName,
                  isOwn: isSelf,
                ),
              ),
          onEdit:
              isSelf && canEdit
                  ? () => unawaited(_openComposer(editing: request))
                  : null,
          onDelete:
              isSelf && canEdit
                  ? () => unawaited(_deleteRequest(request))
                  : null,
        );
      },
    );
  }

  Widget _buildTitleBar(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              context.l10n.event_prayer_requests,
              strutStyle: context.tibetanStrutStyle(17, compact: true),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark, required this.onAdd});

  final bool isDark;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.event_prayer_empty_title,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(15, compact: true),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.event_prayer_empty_body,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(13),
              style: TextStyle(fontSize: 13, color: bodyColor),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  backgroundColor:
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                  foregroundColor:
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  context.l10n.event_prayer_add,
                  strutStyle: context.tibetanStrutStyle(14, compact: true),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(fontSize: 14, color: color),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
