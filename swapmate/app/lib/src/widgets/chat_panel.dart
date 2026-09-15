import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'piece_painter.dart';

/// Room/team chat with a quick-phrase strip for partner communication.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.client,
    this.scopeSelectable = true,
    this.compact = false,
  });

  final GameClient client;
  final bool scopeSelectable;
  final bool compact;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<ChatMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.client.chatStream.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: Motion.base,
            curve: Motion.curve,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    widget.client.chat(t);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final client = widget.client;
    final msgs = client.chats;
    final inSeat = client.mySeat != null;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.md,
              Space.md,
              Space.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.forum_outlined, size: 16, color: c.textMuted),
                const SizedBox(width: Space.sm),
                Text('Chat', style: context.type.titleSmall),
                const Spacer(),
                Text('${msgs.length}', style: context.type.labelSmall),
              ],
            ),
          ),
          Divider(color: c.outline),
          Expanded(
            child: msgs.isEmpty
                ? Center(
                    child: Text(
                      inSeat
                          ? 'Say hi, or send a quick phrase to your partner.'
                          : 'No messages yet.',
                      style: context.type.bodySmall?.copyWith(
                        color: c.textFaint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.sm,
                    ),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) => _Bubble(
                      msgs[i],
                      mine: msgs[i].fromId == client.playerId,
                    ),
                  ),
          ),
          if (inSeat)
            QuickChatStrip(onSend: client.quickChat, compact: widget.compact),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.sm, 0, Space.sm, Space.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Message everyone…',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                IconButton(
                  onPressed: _send,
                  tooltip: 'Send',
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m, {required this.mine});
  final ChatMessage m;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final team = m.seat?.team;
    final color = team == null ? c.textMuted : c.team(team);
    final piece = m.quick?.piece;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            Avatar(name: m.fromName, team: team, size: 22),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: mine
                    ? c.accentSoft
                    : (m.isTeam
                          ? c.teamSoft(team ?? Team.one)
                          : c.surfaceRaised),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(Radii.md),
                  topRight: const Radius.circular(Radii.md),
                  bottomLeft: Radius.circular(mine ? Radii.md : 4),
                  bottomRight: Radius.circular(mine ? 4 : Radii.md),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.fromName,
                        style: context.type.labelSmall?.copyWith(color: color),
                      ),
                      if (m.isTeam) ...[
                        const SizedBox(width: Space.xs),
                        Text(
                          '· team',
                          style: context.type.labelSmall?.copyWith(
                            color: c.textFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (piece != null) ...[
                        PieceGlyph(
                          Piece(PieceColor.white, PieceType.fromLetter(piece)),
                          size: 18,
                          shadow: false,
                        ),
                        const SizedBox(width: Space.xs),
                      ],
                      Flexible(
                        child: Text(m.display, style: context.type.bodyMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of one-tap partner phrases.
class QuickChatStrip extends StatelessWidget {
  const QuickChatStrip({super.key, required this.onSend, this.compact = false});
  final void Function(QuickChat) onSend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: compact ? 36 : 40,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.92, 1],
        ).createShader(rect),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          children: [
            for (final q in QuickChat.values)
              Padding(
                padding: const EdgeInsets.only(
                  right: Space.xs,
                  top: 2,
                  bottom: 6,
                ),
                child: Semantics(
                  button: true,
                  label: 'Quick chat: ${q.text}',
                  child: InkWell(
                    key: Key('quick-${q.code}'),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSend(q);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surfaceSunken,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        border: Border.all(color: c.outline),
                      ),
                      child: Row(
                        children: [
                          if (q.piece != null) ...[
                            PieceGlyph(
                              Piece(
                                PieceColor.white,
                                PieceType.fromLetter(q.piece!),
                              ),
                              size: 16,
                              shadow: false,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            q.text,
                            style: context.type.labelMedium?.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
