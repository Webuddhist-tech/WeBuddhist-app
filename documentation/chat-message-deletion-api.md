# Chat message deletion API

How the app deletes group-chat messages today, and the bulk endpoint proposed
so a multi-select delete becomes one request instead of a loop.

Verified against `https://api.webuddhist.com/openapi.json` on 2026-09-14.
Client code: `lib/features/group_chat/`.

## Current endpoint — one message per request

```
DELETE /api/v1/chat/rooms/{room_id}/messages/{message_id}
Authorization: Bearer <access token>
```

| | |
| --- | --- |
| Path `room_id` | UUID of the chat room |
| Path `message_id` | UUID of the message |
| Request body | none |
| Success | `204 No Content`, empty body |
| Validation error | `422` with `HTTPValidationError` (malformed id) |
| Other refusals | generic error for a non-sender or an already deleted message |
| Authorisation | sender only, enforced server side |

Deletion is a soft delete: the message keeps its row and gains `deleted_at`.
Later fetches of `GET /chat/rooms/{room_id}/messages` return it with
`deleted_at` set and, at present, still carrying its original `body`.

### Socket broadcast

On success the server broadcasts one frame on `WS /chat/live` to every
connected member, the sender included:

```json
{
  "type": "message_deleted",
  "message_id": "<uuid>",
  "deleted_by": "<user uuid>",
  "deleted_at": "2026-09-14T10:12:03Z"
}
```

Parsed by `ChatLiveClient.parseFrame` into `ChatLiveMessageDeleted` and
applied by `GroupChatThreadNotifier.applyDeletion`.

### What the client does with it

`GroupChatRemoteDatasource.deleteMessage` issues the call.
`GroupChatThreadNotifier.deleteMessage` wraps it and, on `204`:

- stamps the row's `deleted_at` with the device clock, because the response
  carries no timestamp; the next fetch replaces it with the server's value;
- stamps `parent.deleted_at` on every loaded reply quoting that id, so their
  quotes become tombstones in the same frame;
- holds the deletion while a page fetch is in flight, so a page built before
  the delete cannot resurrect the row.

The `message_deleted` frame runs through the same `applyDeletion`, so the
sender's own broadcast is a no-op and other members see the tombstone live.

### Multi-select delete

The selection header allows up to `kChatMaxSelection` (10) rows. Delete is
offered only when every selected row is the viewer's own and still standing.
`_deleteSelection` in `group_chat_thread.dart` shows one confirmation
dialog, titled with the count, then calls
`GroupChatThreadNotifier.deleteMessages`, which:

1. for **one** id, calls the single-message endpoint above — it exists on
   every backend and needs no bulk call;
2. for **several** ids, sends **one bulk request** (below); a `204`
   tombstones every id, stamped with the device clock until the
   `message_deleted` broadcast or the next fetch brings the server's value;
3. treats any refusal as **all or nothing**, matching the server: every id
   stays selected and nothing tombstones;
4. **falls back** to the single-message endpoint, one call per id in
   order, on an environment that answers the bulk request with `404` or
   `405` — the two answers a server gives for a route it does not have.

The thread then drops every deleted id from the selection, leaves any
failure selected under one "couldn't be deleted" snackbar so tapping Delete
again retries, and shows "Messages deleted" when all succeed.

## Bulk endpoint — live

Verified against the spec on 2026-09-14 (`DeleteChatMessagesRequest`).

```
DELETE /api/v1/chat/rooms/{room_id}/messages
Authorization: Bearer <access token>
Content-Type: application/json

{ "message_ids": ["<uuid>", "<uuid>"] }
```

| | |
| --- | --- |
| Path `room_id` | UUID of the chat room |
| Body `message_ids` | required, array of message UUIDs |
| Success | `204 No Content`, empty body |
| Validation error | `422` — a missing body answers `{"detail":[{"type":"missing","loc":["body"], …}]}`, which is what the first query-parameter attempt hit |
| Semantics | **all or nothing**: if any id was not sent by the caller, nothing is deleted and the response names the offending ids |
| Broadcast | one `message_deleted` frame per message, same shape as a single delete |

The ids travel in a JSON body on `DELETE`. Dio sends it when `data` is
given; the earlier query-parameter shape in this document was a proposal
the backend did not adopt.

Client: `GroupChatRemoteDatasource.deleteMessages` → repository
`deleteMessages` → `GroupChatThreadNotifier.deleteMessages`.

### Open point for the backend

The all-or-nothing refusal's status code and body are not in the spec (only
`204` and `422` are listed). The client treats any non-`204` as "nothing was
deleted", which is correct whatever the code, but a documented `403` with
the offending ids in `detail` would let the UI highlight exactly which rows
blocked the delete.

## Related backend request

`ChatMessageParentDTO` (the quoted original embedded in a reply) has no
`deleted_at`. The client already parses it as optional; once the server adds
it, a reply whose original was deleted in an earlier session and is outside
the loaded window renders its quote as a tombstone with no client change.
