import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';

/// Filtered text chat. Used standalone (hub tab) and embedded (lobby/results).
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    this.standalone = false,
    this.channels = const [
      ChatChannel.global,
      ChatChannel.party,
      ChatChannel.room,
    ],
  });

  final bool standalone;
  final List<String> channels;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  String _channel = ChatChannel.global;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _channel = widget.channels.first;
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    AppScope.read(context).client.chatSend(_channel, t);
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final available = widget.channels.where((c) {
      if (c == ChatChannel.party) return client.party != null;
      if (c == ChatChannel.room) return client.room != null;
      return true;
    }).toList();
    if (!available.contains(_channel)) _channel = available.first;
    final msgs = client.chat.where((m) => m.channel == _channel).toList();
    if (msgs.length != _lastCount) {
      _lastCount = msgs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: Motion.normal,
            curve: Motion.standard,
          );
        }
      });
    }

    final body = Column(
      children: [
        if (available.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final c in available)
                  ButtonSegment(
                    value: c,
                    label: Text(switch (c) {
                      ChatChannel.party => 'Party',
                      ChatChannel.room => 'Room',
                      _ => 'Global',
                    }),
                  ),
              ],
              selected: {_channel},
              onSelectionChanged: (s) => setState(() => _channel = s.first),
            ),
          ),
        Expanded(
          child: msgs.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Quiet in here',
                  message:
                      'Say hi! Messages are filtered for everyone\'s safety.',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(Space.md),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.from.id == client.myId;
                    final grouped =
                        i > 0 &&
                        msgs[i - 1].from.id == m.from.id &&
                        m.timestamp - msgs[i - 1].timestamp < 60000;
                    return _Bubble(m, mine: mine, grouped: grouped);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.md,
            Space.md,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  maxLength: 160,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText:
                        'Message ${switch (_channel) {
                          ChatChannel.party => 'your party',
                          ChatChannel.room => 'the room',
                          _ => 'everyone',
                        }}…',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.standalone) return body;
    return ContentWidth(
      max: 820,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              'Chat',
              subtitle: 'Links, contact details and rude words are filtered automatically.',
            ),
            Expanded(
              child: Panel(padding: EdgeInsets.zero, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m, {required this.mine, required this.grouped});

  final ChatMessage m;
  final bool mine;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final time = DateTime.fromMillisecondsSinceEpoch(m.timestamp);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return Padding(
      padding: EdgeInsets.only(top: grouped ? Space.xxs : Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine)
            SizedBox(
              width: 32,
              child: grouped
                  ? null
                  : AvatarView(m.from.avatar, size: 28, background: p.surface2),
            ),
          if (!mine) const SizedBox(width: Space.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!grouped)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: Space.xxs,
                      left: Space.xs,
                      right: Space.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mine ? 'You' : m.from.name,
                          style: context.text.labelSmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Text(
                          '$hh:$mm',
                          style: context.text.labelSmall?.copyWith(
                            color: p.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (m.filtered) ...[
                          const SizedBox(width: Space.xs),
                          Tooltip(
                            message: 'Some words were filtered',
                            child: Icon(
                              Icons.shield_outlined,
                              size: 12,
                              color: p.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? BrickColors.sky : p.surface2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(Radii.lg),
                      topRight: const Radius.circular(Radii.lg),
                      bottomLeft: Radius.circular(
                        mine ? Radii.lg : Radii.sm / 2,
                      ),
                      bottomRight: Radius.circular(
                        mine ? Radii.sm / 2 : Radii.lg,
                      ),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: context.text.bodyMedium?.copyWith(
                      color: mine ? Colors.white : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
