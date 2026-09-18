import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing an event's prayer requests, with a composer on top.
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
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  final _scrollController = ScrollController();

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
  bool _sending = false;

  /// Composer shown before the first request exists.
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
    _scrollController.addListener(_onScroll);
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      unawaited(_notifier.loadMore());
    }
  }

  /// Connects once the room is known; the socket is event-scoped.
  void _syncRoom(String? roomId) {
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

  void _startComposing() {
    setState(() => _composing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bodyFocusNode.requestFocus();
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final result = await _notifier.send(body);
      if (!mounted) return;
      result.fold((failure) => presentChatSendError(context, failure), (_) {
        _bodyController.clear();
        unawaited(_markRoomRead());
        unawaited(_ensureLiveConnected());
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prayerRequestsProvider(widget.eventId));
    _syncRoom(state.roomId);

    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final available = size.height - keyboardInset - topInset - 48;
    final height = math.max(220.0, math.min(size.height * 0.6, available));

    final canCompose = state.roomStatus == PrayerRoomStatus.ready;
    final showComposer =
        canCompose && (_composing || state.requests.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildDragHandle(context),
              if (showComposer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: PrayerRequestComposer(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    hintText: context.l10n.event_prayer_hint,
                    isSending: _sending,
                    onSubmit: _send,
                  ),
                ),
              Expanded(child: _buildBody(context, state, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrayerRequestsState state,
    bool isDark,
  ) {
    final mutedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    if (state.roomStatus == PrayerRoomStatus.closed) {
      return _Notice(text: context.l10n.event_prayer_closed, color: mutedColor);
    }
    if (state.roomStatus == PrayerRoomStatus.failed ||
        (state.error != null && state.requests.isEmpty && state.hasLoaded)) {
      return _Notice(
        text: context.l10n.event_prayer_load_failed,
        color: mutedColor,
        actionLabel: context.l10n.group_chat_retry,
        onAction: () => unawaited(_notifier.retry()),
      );
    }
    if (!state.hasLoaded || (state.isLoading && state.requests.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.requests.isEmpty) {
      return _EmptyState(
        isDark: isDark,
        onAdd: _composing ? null : _startComposing,
      );
    }

    final user = ref.watch(userProvider).user;
    final selfName = joinChatName(user?.firstName, user?.lastName);
    final viewerId = _viewerId;
    final viewerEmail = user?.email;
    final itemCount = state.requests.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
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
          onTogglePrayer: () => unawaited(_notifier.togglePrayer(request.id)),
        );
      },
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
