import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../net/game_client.dart';
import 'theme.dart';

/// Chat history + composer. Used in the lobby card and the in-game overlay.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.client,
    required this.session,
    this.dense = true,
    this.autofocus = false,
    this.onClose,
    this.transparent = false,
  });
  final GameClient client;
  final RoomSession session;
  final bool dense;
  final bool autofocus;
  final VoidCallback? onClose;
  final bool transparent;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_refresh);
    if (widget.autofocus) WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    if (widget.session.chat.length != _lastLen) {
      _lastLen = widget.session.chat.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: VhMotion.base, curve: VhMotion.curve);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.client.removeListener(_refresh);
    _ctl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctl.text.trim();
    if (text.isNotEmpty) {
      widget.client.send({'t': Msg.chat, 'text': text});
      _ctl.clear();
    }
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final chat = widget.session.chat;
    final onDark = widget.transparent;
    final bodyStyle = (widget.dense ? t.textTheme.bodyMedium : t.textTheme.bodyMedium)?.copyWith(
      color: onDark ? Colors.white : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.transparent)
          Padding(
            padding: const EdgeInsets.fromLTRB(VhSpace.xl, VhSpace.lg, VhSpace.lg, VhSpace.sm),
            child: Row(
              children: [
                Expanded(child: Text('Chat', style: t.textTheme.headlineSmall)),
                if (widget.onClose != null)
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
        Expanded(
          child: chat.isEmpty
              ? Center(
                  child: Text(
                    'Say hello to the hearth.',
                    style: t.textTheme.bodySmall?.copyWith(color: onDark ? Colors.white70 : null),
                  ),
                )
              : ShaderMask(
                  // Fade the top edge so older, partially scrolled lines taper out.
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0, 0.12],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.transparent ? VhSpace.sm : VhSpace.xl,
                      vertical: VhSpace.md,
                    ),
                    itemCount: chat.length,
                    itemBuilder: (context, i) => _ChatLine(
                      entry: chat[i],
                      style: bodyStyle!,
                      onDark: onDark,
                      mine: chat[i].from == widget.client.playerName,
                    ),
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.transparent ? 0 : VhSpace.lg,
            VhSpace.sm,
            widget.transparent ? 0 : VhSpace.lg,
            widget.transparent ? 0 : VhSpace.lg,
          ),
          child: TextField(
            controller: _ctl,
            focusNode: _focus,
            autofocus: widget.autofocus,
            maxLength: 200,
            style: onDark ? const TextStyle(color: Colors.white) : null,
            decoration: InputDecoration(
              hintText: 'Message everyone…',
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: onDark ? Colors.black.withValues(alpha: 0.45) : null,
              hintStyle: onDark ? const TextStyle(color: Colors.white54) : null,
              suffixIcon: IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
                color: onDark ? Colors.white : null,
              ),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
        ),
      ],
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.entry, required this.style, required this.onDark, required this.mine});
  final ChatEntry entry;
  final TextStyle style;
  final bool onDark;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (entry.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_rounded, size: 13, color: VhColors.gold.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entry.text,
                style: style.copyWith(
                  fontStyle: FontStyle.italic,
                  color: onDark ? Colors.white70 : t.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final nameColor = mine ? VhColors.gold : chatColorFor(entry.from);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(
              text: '${entry.from}  ',
              style: style.copyWith(fontWeight: FontWeight.w700, color: nameColor),
            ),
            TextSpan(text: entry.text),
          ],
        ),
      ),
    );
  }
}

/// Stable per-name accent color for chat and name tags.
Color chatColorFor(String name) {
  const palette = [
    VhColors.sky,
    VhColors.moss,
    Color(0xffc987e8),
    Color(0xffe88a5c),
    Color(0xff5ccfc0),
    Color(0xffe0c25c),
  ];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}
