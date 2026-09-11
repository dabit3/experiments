import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../net/game_client.dart';
import 'pixel.dart';

/// Chat history + composer. Used in the lobby panel and the in-game overlay.
/// In-game ([transparent]) it mirrors the classic layout: translucent
/// history lines above a full-width black input line.
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
    _lastLen = widget.session.chat.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      if (widget.autofocus) _focus.requestFocus();
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    if (widget.session.chat.length != _lastLen) {
      _lastLen = widget.session.chat.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
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
    final s = Gui.of(context);
    final chat = widget.session.chat;
    final lines = chat.isEmpty
        ? Align(
            alignment: widget.transparent ? Alignment.bottomLeft : Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(2.0 * s),
              child: const PxText('Say hello to the hearth.', color: Px.gray),
            ),
          )
        : ListView.builder(
            controller: _scroll,
            shrinkWrap: widget.transparent,
            padding: EdgeInsets.symmetric(horizontal: 2.0 * s, vertical: 1.0 * s),
            itemCount: chat.length,
            itemBuilder: (context, i) => _ChatLine(entry: chat[i], mine: chat[i].from == widget.client.playerName),
          );
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: widget.transparent
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    color: chat.isEmpty ? Colors.transparent : const Color(0x80000000),
                    child: lines,
                  ),
                )
              : lines,
        ),
        SizedBox(height: widget.transparent ? 2.0 * s : 4.0 * s),
        Row(
          children: [
            Expanded(
              child: PxField(
                controller: _ctl,
                focusNode: _focus,
                hint: 'Message everyone...',
                width: double.infinity,
                height: 14,
                maxLength: 200,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            SizedBox(width: 2.0 * s),
            PxButton('Send', width: 40, height: 14, onPressed: _send),
          ],
        ),
      ],
    );
    // Never squeeze below the composer row: clip the history instead.
    final minH = (widget.transparent ? 16.0 : 22.0) * s;
    return LayoutBuilder(
      builder: (context, bc) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: bc.maxHeight.clamp(minH, double.infinity),
          maxHeight: bc.maxHeight.clamp(minH, double.infinity),
          child: column,
        ),
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.entry, required this.mine});
  final ChatEntry entry;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final style = pxStyle(s, color: entry.system ? Px.gray : Px.white);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (!entry.system)
            TextSpan(
              text: '<${entry.from}> ',
              style: style.copyWith(color: mine ? Px.yellow : chatColorFor(entry.from)),
            ),
          TextSpan(text: entry.text),
        ],
      ),
      softWrap: true,
    );
  }
}

/// Stable per-name accent colour for chat and name tags, drawn from the
/// classic 16-colour text palette.
Color chatColorFor(String name) {
  const palette = [
    Px.aqua,
    Px.green,
    Color(0xffff55ff),
    Px.gold,
    Color(0xff5555ff),
    Color(0xff00aaaa),
    Color(0xffaa00aa),
    Color(0xff55ff55),
  ];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}
