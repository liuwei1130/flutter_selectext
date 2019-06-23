import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart' show CupertinoTheme, CupertinoColors;
import 'package:flutter/material.dart' show Theme, ThemeData, Feedback, debugCheckHasMaterial;
import 'package:flutter/widgets.dart';
import 'package:flutter_selectext/src/text_selection_controls/cupertino_copy_text_selection_controls.dart';
import 'package:flutter_selectext/src/input_less_focus_node.dart';
import 'package:flutter_selectext/src/selectext_editable_text.dart';
import 'package:flutter_selectext/src/selectable_text_render_editable.dart';
import 'package:flutter_selectext/src/selectable_text_selection_controls.dart';
import 'package:flutter_selectext/src/text_selection_controls/material_copy_text_selection_controls.dart';
import 'package:flutter_selectext/src/text_selection_controls/cupertino_mark_text_selection_controls.dart';
import 'package:flutter_selectext/src/text_selection_controls/material_mark_text_selection_controls.dart';

String _tag = 'SelectableText';

class SelectableText extends StatelessWidget {
  SelectableText(this.text,
      {Key key,
      this.style,
      this.textAlign = TextAlign.start,
      this.textDirection,
      this.cursorRadius,
      this.cursorColor,
      this.androidTextSelectionControls,
      this.iosTextSelectionControls,
      this.dragStartBehavior = DragStartBehavior.down,
      this.enableInteractiveSelection = true,
      this.onTap,
      this.onPaintContent})
      : assert(text != null),
        textSpan = null,
        super(key: key);

  SelectableText.rich(this.textSpan,
      {Key key,
      this.style,
      this.textAlign = TextAlign.start,
      this.textDirection,
      this.cursorRadius,
      this.cursorColor,
      this.androidTextSelectionControls,
      this.iosTextSelectionControls,
      this.dragStartBehavior = DragStartBehavior.down,
      this.enableInteractiveSelection = true,
      this.onTap,
      this.onPaintContent})
      : assert(textSpan != null),
        text = null,
        super(key: key);

  final SelectableTextSelectionControls androidTextSelectionControls;
  final SelectableTextSelectionControls iosTextSelectionControls;

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
  final PaintContentHandler onPaintContent;

  final _effectiveFocusNode = InputlessFocusNode();

  final GlobalKey<SelectableTextEditableTextState> _editableTextKey =
      GlobalKey<SelectableTextEditableTextState>();

  SelectableTextRender get _renderEditable => _editableTextKey.currentState.renderEditable;

  TextSelection get selection => _renderEditable.selection;

  set selection(TextSelection value) {
    _editableTextKey.currentState.hideToolbar();
    _renderEditable.selection = value;
  }

  void _handleTapDown(TapDownDetails details) {
    debugPrint('$_tag, _handleTapDown');
    _renderEditable.handleTapDown(details);
  }

  void _handleSingleTapUp(BuildContext context, TapUpDetails details) {
    debugPrint('$_tag, _handleSingleTapUp');
    if (onTap == null) {
      _renderEditable.selectWord(cause: SelectionChangedCause.tap);
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        if (onTap == null && iosTextSelectionControls != null &&
            iosTextSelectionControls is CupertinoMarkTextSelectionControls) {
          (iosTextSelectionControls as CupertinoMarkTextSelectionControls)
              .translateBuildView(_editableTextKey?.currentState?.textEditingValue);
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        if (onTap == null && androidTextSelectionControls != null &&
            androidTextSelectionControls is MaterialMarkTextSelectionControls) {
          (androidTextSelectionControls as MaterialMarkTextSelectionControls)
              .translateBuildView(_editableTextKey?.currentState?.textEditingValue);
        }
        break;
    }
    _editableTextKey.currentState.hideToolbar();
    _effectiveFocusNode.unfocus();
    if (onTap != null) {
      onTap();
    }
  }

  void _handleSingleLongTapStart(BuildContext context, LongPressStartDetails details) {
    debugPrint('$_tag, _handleSingleLongTapStart');
    // the EditableText widget will force the keyboard to come up if our focus node
    // is already focused. It does this by using a TextInputConnection
    // In order to tool it not to do that, we override our focus while selecting text
    _effectiveFocusNode.overrideFocus = false;

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        _renderEditable.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _renderEditable.selectWord(cause: SelectionChangedCause.longPress);
        Feedback.forLongPress(context);
        break;
    }

    // Stop overriding our focus
    _effectiveFocusNode.overrideFocus = null;
  }

  void _handleSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    debugPrint('$_tag, _handleSingleLongTapMoveUpdate');
    // the EditableText widget will force the keyboard to come up if our focus node
    // is already focused. It does this by using a TextInputConnection
    // In order to tool it not to do that, we override our focus while selecting text
    _effectiveFocusNode.overrideFocus = false;

    _renderEditable.selectWordsInRange(
      from: details.globalPosition - details.offsetFromOrigin,
      to: details.globalPosition,
      cause: SelectionChangedCause.longPress,
    );
    //Stop overriding our focus
    _effectiveFocusNode.overrideFocus = null;
  }

  void _handleSingleLongTapEnd(LongPressEndDetails details) {
    debugPrint('$_tag, _handleSingleLongTapEnd');

    _editableTextKey.currentState.showToolbar();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    debugPrint('$_tag, _handleDoubleTapDown');
    _renderEditable.selectWord(cause: SelectionChangedCause.doubleTap);
    _editableTextKey.currentState.showToolbar();
  }

  void _handleSelectionChanged(
      BuildContext context, TextSelection selection, SelectionChangedCause cause) {
    debugPrint('$_tag, _handleSelectionChanged');
    // iOS cursor doesn't move via a selection handle. The scroll happens
    // directly from new text selection changes.
    if (Theme.of(context).platform == TargetPlatform.iOS &&
        cause == SelectionChangedCause.longPress) {
      _editableTextKey.currentState?.bringIntoView(selection.base);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasDirectionality(context));

    final ThemeData themeData = Theme.of(context);

    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit) effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle.merge(const TextStyle(fontWeight: FontWeight.bold));

    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Color cursorColor = this.cursorColor;
    Radius cursorRadius = this.cursorRadius;
    SelectableTextSelectionControls textSelectionControls;

    switch (themeData.platform) {
      case TargetPlatform.iOS:
        textSelectionControls ??= (iosTextSelectionControls ?? cupertinoCopyTextSelectionControls);

        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??= CupertinoTheme.of(context).primaryColor;
        cursorRadius ??= const Radius.circular(2.0);
        // An eyeballed value that moves the cursor slightly left of where it is
        // rendered for text on Android so its positioning more accurately matches the
        // native iOS text cursor positioning.
        //
        // This value is in device pixels, not logical pixels as is typically used
        // throughout the codebase.
        const int _iOSHorizontalOffset = -2;
        cursorOffset = Offset(_iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        textSelectionControls ??=
            (androidTextSelectionControls ?? materialCopyTextSelectionControls);

        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= themeData.cursorColor;
        break;
    }

    SelectableTextEditingController controller;
    if (text != null) {
      controller = SelectableTextEditingController(text: text);
    } else if (textSpan != null) {
      controller = SelectableTextEditingController.rich(textSpan);
    }

    Widget child = RepaintBoundary(
      child: SelectableTextEditableText(
        key: _editableTextKey,
        controller: controller,
        focusNode: _effectiveFocusNode,
        style: effectiveTextStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: null,
        selectionColor: themeData.textSelectionColor,
        selectionControls: enableInteractiveSelection ? textSelectionControls : null,
        onSelectionChanged: (selection, cause) {
          _handleSelectionChanged(context, selection, cause);
        },
        rendererIgnoresPointer: true,
        cursorWidth: 0,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        cursorOpacityAnimates: cursorOpacityAnimates,
        cursorOffset: cursorOffset,
        paintCursorAboveText: paintCursorAboveText,
        backgroundCursorColor: CupertinoColors.inactiveGray,
        enableInteractiveSelection: enableInteractiveSelection,
        dragStartBehavior: dragStartBehavior,
        onPaintContent: onPaintContent,
      ),
    );

    return Semantics(
      child: TextSelectionGestureDetector(
          onTapDown: _handleTapDown,
          onSingleTapUp: (details) {
            _handleSingleTapUp(context, details);
          },
          onSingleLongTapStart: (details) {
            _handleSingleLongTapStart(context, details);
          },
          onSingleLongTapMoveUpdate: _handleSingleLongTapMoveUpdate,
          onSingleLongTapEnd: _handleSingleLongTapEnd,
          onDoubleTapDown: _handleDoubleTapDown,
          behavior: HitTestBehavior.translucent,
          child: child,
        ),
    );
  }
}
