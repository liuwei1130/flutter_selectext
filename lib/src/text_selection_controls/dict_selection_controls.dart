import 'package:flutter/material.dart';
import 'package:flutter_selectext/src/selectable_text_selection_delegate.dart';
import '../selectable_text_selection_controls.dart';

/// 字典中使用的选择控制器
class DictSelectionControls extends SelectableTextSelectionControls {
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // TODO: implement buildHandle
    return null;
  }

  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, Offset position,
      SelectableTextSelectionDelegate delegate) {
    // TODO: implement buildToolbar
    return null;
  }

  @override
  // TODO: implement handleSize
  Size get handleSize => null;
}
