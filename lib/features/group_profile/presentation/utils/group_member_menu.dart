import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';

/// Whether the space page shows its ⋮ member menu: only to a signed-in
/// member (or Page follower) the server has confirmed.
///
/// Membership comes from [lastConfirmedGroupMembership], so a leave in flight
/// or a failed leave keeps the menu, while the initial check, a join in
/// flight or a failed join keep it hidden.
bool showsGroupMemberMenu({
  required GroupFollowState followState,
  required bool signedIn,
}) {
  return signedIn && lastConfirmedGroupMembership(followState);
}
