import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';

/// The backend's error code on a refused send.
String? chatSendErrorCode(Object error) {
  return switch (error) {
    ValidationFailure(:final code) => code,
    ValidationException(:final code) => code,
    _ => null,
  };
}

enum ChatSendErrorKind { inappropriate, notAMember, invalidParent, generic }

/// Classifies send failures so every path shares the same copy.
ChatSendErrorKind chatSendErrorKind(Object error) {
  final code = chatSendErrorCode(error);
  if (ChatModeration.isInappropriateLanguage(code)) {
    return ChatSendErrorKind.inappropriate;
  }
  if (ChatModeration.isInvalidParentMessage(code)) {
    return ChatSendErrorKind.invalidParent;
  }
  if (error is AuthorizationFailure || error is AuthorizationException) {
    return ChatSendErrorKind.notAMember;
  }
  return ChatSendErrorKind.generic;
}

String chatSendErrorMessage(AppLocalizations l10n, Object error) {
  return switch (chatSendErrorKind(error)) {
    ChatSendErrorKind.inappropriate => l10n.group_chat_inappropriate,
    ChatSendErrorKind.notAMember => l10n.group_chat_not_a_member,
    ChatSendErrorKind.invalidParent => l10n.group_chat_reply_parent_gone,
    ChatSendErrorKind.generic => switch (error) {
      Failure(:final message) => message,
      Exception() => error.toString(),
      _ => error.toString(),
    },
  };
}

/// Surfaces send failures. Profanity and 403 use dedicated l10n strings.
void presentChatSendError(BuildContext context, Object error) {
  showChatSendError(ScaffoldMessenger.of(context), context.l10n, error);
}

/// The same copy, for callers that resolved the messenger and localizations
/// while their element was still active.
///
/// An async result can land after a route pop but before the element
/// unmounts, where `ScaffoldMessenger.of` and `context.l10n` throw.
void showChatSendError(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Object error,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(chatSendErrorMessage(l10n, error))));
}
