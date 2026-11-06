import 'package:flutter/material.dart';

/// Text sizes above this (a child or parent who has asked the phone for very
/// large text) are not squeezed: shrinking a screen to fit would make the
/// buttons smaller than a finger, so [FitContent] scrolls instead.
const double fitContentLargestText = 1.3;

/// Lays [child] out at the width available and, if it is taller than the room,
/// scales the whole of it down to fit. At normal text sizes it never scrolls,
/// so every essential control stays on screen on any phone or tablet. When
/// there is room the child keeps its natural size and takes only the height it
/// needs.
///
/// This is the safety net under the screens that were redesigned to fit: it
/// guarantees that no content is pushed off the bottom of the screen.
///
/// Two honest limits, because shrinking a screen below a readable, tappable
/// size helps nobody: when the text is set above [fitContentLargestText], or
/// when fitting would need a scale below [minScale] (a question far longer
/// than any screen), the content scrolls instead.
class FitContent extends StatefulWidget {
  const FitContent({
    required this.child,
    super.key,
    this.alignment = Alignment.topCenter,
    this.minScale = 0.5,
  });

  final Widget child;
  final Alignment alignment;

  /// The smallest scale worth drawing; below it the content scrolls.
  final double minScale;

  @override
  State<FitContent> createState() => _FitContentState();
}

class _FitContentState extends State<FitContent> {
  final _natural = GlobalKey();
  bool _scrolls = false;

  /// After layout, compares the content's natural height with the room and
  /// switches between scaling and scrolling. A margin on the way back stops it
  /// flipping between the two.
  void _measure(double room) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _natural.currentContext?.size;
      if (size == null || size.height <= 0) return;
      final needed = room / size.height;
      final want =
          _scrolls ? needed < widget.minScale * 1.08 : needed < widget.minScale;
      if (want != _scrolls) setState(() => _scrolls = want);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hugeText =
        MediaQuery.textScalerOf(context).scale(1) > fitContentLargestText;
    return LayoutBuilder(
      builder: (context, box) {
        final body = SizedBox(
          key: _natural,
          width: box.maxWidth,
          child: widget.child,
        );
        if (!box.hasBoundedHeight) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: widget.alignment,
            child: body,
          );
        }
        _measure(box.maxHeight);
        if (hugeText || _scrolls) {
          return SingleChildScrollView(child: body);
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: widget.alignment,
          child: body,
        );
      },
    );
  }
}

/// [FitContent], except while the on-screen keyboard is up: then the content
/// scrolls so the field being typed in can be reached. Only forms use this.
class FitOrScroll extends StatelessWidget {
  const FitOrScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0
          ? SingleChildScrollView(child: child)
          : FitContent(child: child);
}
