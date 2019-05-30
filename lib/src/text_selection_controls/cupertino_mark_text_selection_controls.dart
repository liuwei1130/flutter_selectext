import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_selectext/src/text_selection_controls/handle_mark.dart';
import 'package:flutter_selectext/src/selectable_text_selection_controls.dart';

String _tag = 'CupertinoMarkText';
// Padding around the line at the edge of the text selection that has 0 width and
// the height of the text font.
const double _kHandlesPadding = 18.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 36.0;

const Color _kToolbarBackgroundColor = Color(0xFF2E2E2E);
const Color _kToolbarDividerColor = Color(0xFFB9B9B9);
// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const Color _kHandlesColor = Color(0xFF136FE0);

// This offset is used to determine the center of the selection during a drag.
// It's slightly below the center of the text so the finger isn't entirely
// covering the text being selected.
const Size _kSelectionOffset = Size(20.0, 30.0);
const Size _kToolbarTriangleSize = Size(18.0, 9.0);
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
const BorderRadius _kToolbarBorderRadius = BorderRadius.all(Radius.circular(7.5));

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.11,
  fontWeight: FontWeight.w300,
  color: CupertinoColors.white,
);

/// Paints a triangle below the toolbar.
class _TextSelectionToolbarNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _kToolbarBackgroundColor
      ..style = PaintingStyle.fill;
    final Path triangle = Path()
      ..lineTo(_kToolbarTriangleSize.width / 2, 0.0)
      ..lineTo(0.0, _kToolbarTriangleSize.height)
      ..lineTo(-(_kToolbarTriangleSize.width / 2), 0.0)
      ..close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionToolbarNotchPainter oldPainter) => false;
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatefulWidget {
  const _TextSelectionToolbar(
      {Key key,
      this.handleCopy,
      this.handleSelectAll,
      this.translateBuildView,
      this.markColor,
      this.markString,
      this.delegate,
      this.context,
      this.globalEditableRegion,
      this.position})
      : super(key: key);

  final VoidCallback handleCopy;
  final VoidCallback handleSelectAll;
  final TranslateBuildView translateBuildView;
  final TextSelectionDelegate delegate;
  final BuildContext context;
  final Rect globalEditableRegion;
  final Offset position;

  /// 自定义的文字
  final String markString;
  final Color markColor;

  @override
  State<StatefulWidget> createState() {
    return _TextSelectionToolbarState();
  }
}

class _TextSelectionToolbarState extends State<_TextSelectionToolbar> {
  @override
  Widget build(BuildContext context) {
    debugPrint('$_tag, _TextSelectionToolbarState : build');
    var childWidget;

    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    if (widget.translateBuildView != null) {
      items.add(_buildToolbarButton(widget.markString, () {
        widget.translateBuildView(widget.delegate.textEditingValue);
        widget.delegate.hideToolbar();
      }));
    }

    if (widget.handleCopy != null) {
      if (items.isNotEmpty) items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.copyButtonLabel, widget.handleCopy));
    }

    if (items.isEmpty) return Container();

    final Widget triangle = SizedBox.fromSize(
        size: _kToolbarTriangleSize,
        child: CustomPaint(
          painter: _TextSelectionToolbarNotchPainter(),
        ));

    childWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: _kToolbarBorderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kToolbarDividerColor,

              borderRadius: _kToolbarBorderRadius,

              // Add a hairline border with the button color to avoid
              // antialiasing artifacts.
              border: Border.all(color: _kToolbarBackgroundColor, width: 0),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),

        // TODO(xster): Position the triangle based on the layout delegate, and
        // avoid letting the triangle line up with any dividers.
        // https://github.com/flutter/flutter/issues/11274
        triangle,

        const Padding(padding: EdgeInsets.only(bottom: 10.0)),
      ],
    );
    return ConstrainedBox(
        constraints: BoxConstraints.tight(widget.globalEditableRegion.size),
        child: CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            MediaQuery.of(widget.context).size,
            widget.globalEditableRegion,
            widget.position,
          ),
          child: childWidget,
        ));
  }

  /// Builds a themed [CupertinoButton] for the toolbar.
  CupertinoButton _buildToolbarButton(String text, VoidCallback onPressed) {
    return CupertinoButton(
      child: Text(text, style: _kToolbarButtonFontStyle),
      color: _kToolbarBackgroundColor,
      minSize: _kToolbarHeight,
      padding: _kToolbarButtonPadding,
      borderRadius: null,
      pressedOpacity: 0.7,
      onPressed: onPressed,
    );
  }
}

/// Centers the toolbar around the given position, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(this.screenSize, this.globalEditableRegion, this.position);

  /// The size of the screen at the time that the toolbar was last laid out.
  final Size screenSize;

  /// Size and position of the editing region at the time the toolbar was last
  /// laid out, in global coordinates.
  final Rect globalEditableRegion;

  /// Anchor position of the toolbar, relative to the top left of the
  /// [globalEditableRegion].
  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset globalPosition = globalEditableRegion.topLeft + position;

    double x = globalPosition.dx - childSize.width / 2.0;
    double y = globalPosition.dy - childSize.height;

    if (x < _kToolbarScreenPadding)
      x = _kToolbarScreenPadding;
    else if (x + childSize.width > screenSize.width - _kToolbarScreenPadding)
      x = screenSize.width - childSize.width - _kToolbarScreenPadding;

    if (y < _kToolbarScreenPadding)
      y = _kToolbarScreenPadding;
    else if (y + childSize.height > screenSize.height - _kToolbarScreenPadding)
      y = screenSize.height - childSize.height - _kToolbarScreenPadding;

    debugPrint('$_tag, getPositionForChild : x : $x, y : $y');

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return screenSize != oldDelegate.screenSize ||
        globalEditableRegion != oldDelegate.globalEditableRegion ||
        position != oldDelegate.position;
  }
}

/// Draws a single text selection handle with a bar and a ball.
///
/// Draws from a point of origin somewhere inside the size of the painter
/// such that the ball is below the point of origin and the bar is above the
/// point of origin.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.origin});

  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _kHandlesColor
      ..strokeWidth = 2.0;
    // Draw circle below the origin that slightly overlaps the bar.
    canvas.drawCircle(origin.translate(0.0, 4.0), 5.5, paint);
    // Draw up from origin leaving 10 pixels of margin on top.
    canvas.drawLine(
      origin,
      origin.translate(
        0.0,
        -(size.height - 2.0 * _kHandlesPadding),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => origin != oldPainter.origin;
}

class CupertinoMarkTextSelectionControls extends SelectableTextSelectionControls {
  CupertinoMarkTextSelectionControls(
      {@required this.markColor, this.markString, this.translateBuildView});

  final String markString;
  final TranslateBuildView translateBuildView;
  final Color markColor;

  @override
  Size handleSize = _kSelectionOffset; // Used for drag selection offset.

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, Offset position,
      TextSelectionDelegate delegate) {
    assert(debugCheckHasMediaQuery(context));
    debugPrint('$_tag, buildToolbar');
    return _TextSelectionToolbar(
      context: context,
      globalEditableRegion: globalEditableRegion,
      position: position,
      handleCopy: isTextSelection(delegate) ? () => handleCopy(delegate) : null,
      translateBuildView: translateBuildView,
      delegate: delegate,
      markString: markString,
      markColor: markColor,
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = Size(2.0 * _kHandlesPadding, textLineHeight + 2.0 * _kHandlesPadding);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          // We give the painter a point of origin that's at the bottom baseline
          // of the selection cursor position.
          //
          // We give it in the form of an offset from the top left of the
          // SizedBox.
          origin: Offset(_kHandlesPadding, textLineHeight + _kHandlesPadding),
        ),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left: // The left handle is upside down on iOS.
        return Transform(
            transform: Matrix4.rotationZ(math.pi)..translate(-_kHandlesPadding, -_kHandlesPadding),
            child: handle);
      case TextSelectionHandleType.right:
        return Transform(
            transform: Matrix4.translationValues(
                -_kHandlesPadding, -(textLineHeight + _kHandlesPadding), 0.0),
            child: handle);
      case TextSelectionHandleType.collapsed: // iOS doesn't draw anything for collapsed selections.
        return Container();
    }
    assert(type != null);
    return null;
  }
}
