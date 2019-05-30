import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_selectext/src/selectable_text.dart';
import 'package:flutter_selectext/src/text_selection_controls/cupertino_mark_text_selection_controls.dart';
import 'package:flutter_selectext/src/text_selection_controls/handle_mark.dart';
import 'package:flutter_selectext/src/text_selection_controls/material_mark_text_selection_controls.dart';

class MarkText extends StatelessWidget {
  MarkText(
    this.text, {
    Key key,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.cursorRadius,
    this.cursorColor,
    this.dragStartBehavior = DragStartBehavior.down,
    this.enableInteractiveSelection = true,
    this.onTap,
    @required this.markColor,
    @required this.translateBuildView,
    @required this.markList,
    @required this.markString,
  })  : assert(text != null),
        textSpan = null,
        super(key: key);

  MarkText.rich(
    this.textSpan, {
    Key key,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.cursorRadius,
    this.cursorColor,
    this.dragStartBehavior = DragStartBehavior.down,
    this.enableInteractiveSelection = true,
    this.onTap,
    @required this.markColor,
    @required this.translateBuildView,
    @required this.markList,
    @required this.markString,
  })  : assert(textSpan != null),
        text = null,
        super(key: key);

  final String text;
  final TextSpan textSpan;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Radius cursorRadius;
  final Color cursorColor;
  final bool enableInteractiveSelection;
  final DragStartBehavior dragStartBehavior;
  final GestureTapCallback onTap;
  final Color markColor;
  final TranslateBuildView translateBuildView;
  final String markString;
  final List<TextSelection> markList;

  void _onPaintContent(TextPainter textPainter, Canvas canvas) {
    if (markList != null) {
      for (TextSelection textSelection in markList) {
        List<TextBox> textBox = textPainter.getBoxesForSelection(textSelection);
        for (TextBox box in textBox) {
          canvas.drawRect(box.toRect(), Paint()..color = markColor);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iosTextSelectionControls = CupertinoMarkTextSelectionControls(
        translateBuildView: translateBuildView, markColor: markColor, markString: markString);
    final androidTextSelectionControls = MaterialMarkTextSelectionControls(
        translateBuildView: translateBuildView, markColor: markColor, markString: markString);

    TextSpan textSpan = this.textSpan;
    if (text != null) {
      textSpan = TextSpan(style: style, text: text);
    }

    return SelectableText.rich(
      textSpan,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      iosTextSelectionControls: iosTextSelectionControls,
      androidTextSelectionControls: androidTextSelectionControls,
      dragStartBehavior: dragStartBehavior,
      enableInteractiveSelection: enableInteractiveSelection,
      onTap: onTap,
      onPaintContent: _onPaintContent,
    );
  }
}
