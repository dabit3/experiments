import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'profile_screen.dart';

/// Friends list, requests and the party panel.
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _friendName = TextEditingController();
  final _partyCode = TextEditingController();

  @override
  void dispose() {
    _friendName.dispose();
    _partyCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    final party = _PartyPanel(codeController: _partyCode);
    final friends = _FriendsPanel(nameController: _friendName);
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxl,
        ),
        children: [
          SectionHeader(
            'Friends & party',
            subtitle: 'Party up across web, iOS, Android and macOS.',
          ),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Entrance(child: party)),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Entrance(
                    delay: const Duration(milliseconds: 80),
                    child: friends,
                  ),
                ),
              ],
            )
          else ...[
            Entrance(child: party),
            const SizedBox(height: Space.lg),
            Entrance(delay: const Duration(milliseconds: 80), child: friends),
          ],
        ],
      ),
    );
  }
}

class _PartyPanel extends StatelessWidget {
  const _PartyPanel({required this.codeController});

  final TextEditingController codeController;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final party = client.party;

    if (party == null) {
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: BrickColors.sky),
                const SizedBox(width: Space.sm),
                Text('Party', style: context.text.titleMedium),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Parties travel together: when the leader launches an experience, everyone joins the same room.',
              style: context.text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: client.connected ? () => client.partyCreate() : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a party'),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (v) =>
                        client.partyJoin(v.trim().toUpperCase()),
                    decoration: const InputDecoration(
                      hintText: 'Party code',
                      isDense: true,
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                OutlinedButton(
                  onPressed: () => client.partyJoin(
                    codeController.text.trim().toUpperCase(),
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final leader = party.leaderId == client.myId;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: BrickColors.sky),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'Your party · ${party.members.length}/$maxRoomPlayers',
                  style: context.text.titleMedium,
                ),
              ),
              CodeBadge(party.code, label: 'Party'),
            ],
          ),
          const SizedBox(height: Space.md),
          for (final m in party.members)
            PlayerTile(
              m,
              dense: true,
              subtitle: m.id == party.leaderId
                  ? 'Leader'
                  : (m.online ? 'Online' : 'Offline'),
              trailing: m.id == party.leaderId
                  ? const Icon(
                      Icons.star_rounded,
                      color: BrickColors.sun,
                      size: 18,
                    )
                  : null,
              onTap: () => showProfileDialog(context, m.id),
            ),
          const SizedBox(height: Space.md),
          if (leader) ...[
            Text(
              'Launch for everyone',
              style: context.text.labelMedium?.copyWith(color: p.textTertiary),
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final place in places)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(place.accent)
                          .withValues(alpha: 0.16),
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Color.lerp(Color(place.accent), Colors.white, 0.35)
                          : Color.lerp(Color(place.accent), Colors.black, 0.25),
                    ),
                    onPressed: () => client.partyLaunch(
                      place.kind,
                      bots: (maxRoomPlayers - party.members.length).clamp(0, 3),
                    ),
                    icon: Icon(experienceIcon(place.kind), size: 18),
                    label: Text(place.name),
                  ),
              ],
            ),
          ] else
            Text(
              'Waiting for the leader to launch an experience…',
              style: context.text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: client.partyLeave,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Leave party'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsPanel extends StatelessWidget {
  const _FriendsPanel({required this.nameController});

  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final f = client.friends;

    void send() {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      client.friendRequest(name);
      nameController.clear();
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: BrickColors.cherry),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'Friends · ${f.friends.length}',
                  style: context.text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  onSubmitted: (_) => send(),
                  decoration: const InputDecoration(
                    hintText: 'Add by player name',
                    isDense: true,
                    prefixIcon: Icon(Icons.person_add_alt_1_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              FilledButton(onPressed: send, child: const Text('Add')),
            ],
          ),
          if (f.incoming.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(
              'Requests',
              style: context.text.labelMedium?.copyWith(color: p.textTertiary),
            ),
            for (final r in f.incoming)
              PlayerTile(
                r,
                dense: true,
                subtitle: 'Wants to be friends',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decline',
                      onPressed: () => client.friendDecline(r.id),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    FilledButton(
                      onPressed: () => client.friendAccept(r.id),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ),
          ],
          if (f.outgoing.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(
              'Sent',
              style: context.text.labelMedium?.copyWith(color: p.textTertiary),
            ),
            for (final r in f.outgoing)
              PlayerTile(
                r,
                dense: true,
                subtitle: 'Pending',
                trailing: TextButton(
                  onPressed: () => client.friendRemove(r.id),
                  child: const Text('Cancel'),
                ),
              ),
          ],
          const SizedBox(height: Space.lg),
          if (f.friends.isEmpty)
            EmptyState(
              icon: Icons.person_search_rounded,
              title: 'No friends yet',
              message: 'Ask a friend for their player name — they can be on any platform.',
            )
          else
            for (final fr in f.friends)
              PlayerTile(
                fr,
                dense: true,
                subtitle: fr.online ? 'Online' : 'Offline',
                onTap: () => showProfileDialog(context, fr.id),
                trailing: MenuAnchor(
                  builder: (context, controller, _) => IconButton(
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => showProfileDialog(context, fr.id),
                      leadingIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                      ),
                      child: const Text('View profile'),
                    ),
                    if (client.party != null && client.isPartyLeader)
                      MenuItemButton(
                        onPressed: () => client.chatSend(
                          ChatChannel.global,
                          '@${fr.name} join my party: ${client.party!.code}',
                        ),
                        leadingIcon: const Icon(Icons.send_rounded, size: 18),
                        child: const Text('Share party code'),
                      ),
                    MenuItemButton(
                      onPressed: () => client.friendRemove(fr.id),
                      leadingIcon: const Icon(
                        Icons.person_remove_outlined,
                        size: 18,
                      ),
                      child: const Text('Remove friend'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
