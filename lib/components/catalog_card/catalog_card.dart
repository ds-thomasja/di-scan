import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// A selectable card that represents a scan catalog entry.
///
/// Renders in two layouts driven by [selected]:
/// - Compact (not selected): fixed 288×96 row with thumbnail + label
/// - Expanded (selected): stacked image + label row with action buttons
///
/// Interaction states (hover, pressed, focus) are handled internally.
/// Set [disabled] externally to lock the card.
class CatalogCard extends StatefulWidget {
  const CatalogCard({
    super.key,
    this.name = 'Catalog name',
    this.subtext = 'Subtext',
    this.showSubtext = true,
    this.scanModel = false,
    this.scanModelImage,
    this.selected = false,
    this.disabled = false,
    this.showStatus = false,
    this.isDragTarget = false,
    this.isDragSource = false,
    this.isLoading = false,
    this.onRemovePressed,
    this.onTap,
    this.onSelectedChanged,
  });

  /// Primary label text.
  final String name;

  /// Secondary label text shown below [name].
  final String subtext;

  /// Whether [subtext] is visible.
  final bool showSubtext;

  /// When true the card uses a real scan image instead of the arch placeholder.
  final bool scanModel;

  /// The scan image widget. Required when [scanModel] is true; falls back to
  /// the arch-upper icon when null.
  final Widget? scanModelImage;

  /// Initial expanded (card-view) vs. compact (list-view) state. Tapping
  /// toggles this internally and notifies [onSelectedChanged].
  final bool selected;

  /// Disables all interaction and applies disabled visual styling.
  final bool disabled;

  /// Shows the check-circle-filled status icon.
  final bool showStatus;

  /// The card the user is currently dragging over. Shows hovered background,
  /// repeat icon, fixed "Switch" label, and hides subtext.
  final bool isDragTarget;

  /// The card the user long-pressed to start dragging. Shows subdued
  /// background with a dashed border; text and icon use disabled styling.
  /// In the selected (expanded) state the image area is left empty.
  final bool isDragSource;

  /// Shows an indeterminate spinner in the image slot and suppresses all
  /// interaction feedback. Used while a drag-drop switch operation is in
  /// progress.
  final bool isLoading;

  /// Called when the user confirms "Remove catalog" from the action menu.
  final VoidCallback? onRemovePressed;

  /// Called after a tap (before the selected state changes). Use for any
  /// additional side-effects; selected toggling happens regardless.
  final VoidCallback? onTap;

  /// Called whenever the selected state changes, with the new value.
  final ValueChanged<bool>? onSelectedChanged;

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late bool _selected;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  bool _isButtonHovered = false;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void didUpdateWidget(CatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.disabled) return;
    widget.onTap?.call();
    final next = !_selected;
    setState(() => _selected = next);
    widget.onSelectedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return SizedBox(
      width: 288,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        enabled: !widget.disabled,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: widget.disabled ? null : (_) => setState(() { if (!_isButtonHovered) _isPressed = true; }),
          onTapUp: widget.disabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.disabled ? null : () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: (_isPressed && !_isButtonHovered) ? 0.97 : 1.0,
            duration: (_isPressed && !_isButtonHovered)
                ? const Duration(milliseconds: 80)
                : const Duration(milliseconds: 300),
            curve: (_isPressed && !_isButtonHovered)
                ? Curves.easeInCubic
                : Curves.easeOut,
            child: Stack(
              children: [
                _buildCard(tokens),
                if (_selected && !widget.isDragSource) _buildSelectionOverlay(tokens),
                if (widget.isDragSource) _buildDragSourceOverlay(tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(DSTokensData tokens) {
    if (widget.disabled) return tokens.surface.standard;
    if (widget.isLoading) return tokens.surface.standard;
    if (widget.isDragSource) return tokens.surface.subdued;
    if (widget.isDragTarget) return tokens.surface.hovered;
    if (_isPressed && !_isButtonHovered) return tokens.surface.pressed;
    if (_isFocused) return tokens.surface.standard;
    if (_isHovered && !_isButtonHovered) return tokens.surface.hovered;
    return tokens.surface.standard;
  }

  BoxBorder _border(DSTokensData tokens) {
    if (widget.isDragSource) return Border.all(color: Colors.transparent);
    if (_isFocused) {
      return Border.all(color: tokens.border.focused, width: tokens.border.width.focus);
    }
    return Border.all(
      color: _selected ? Colors.transparent : tokens.border.subdued,
      width: tokens.border.width.standard,
    );
  }

  Widget _buildCard(DSTokensData tokens) {
    final radius = BorderRadius.circular(tokens.border.radius.standard);
    return ClipRRect(
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        color: _backgroundColor(tokens),
        child: DecoratedBox(
          decoration: BoxDecoration(border: _border(tokens), borderRadius: radius),
          position: DecorationPosition.foreground,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutQuint,
            alignment: Alignment.topCenter,
            child: _selected
                ? _buildExpandedContent(tokens)
                : _buildCompactContent(tokens),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay(DSTokensData tokens) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.border.radius.standard),
            border: Border.all(
              color: tokens.border.interactiveHovered,
              width: tokens.border.width.selection,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragSourceOverlay(DSTokensData tokens) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DashedRoundedBorderPainter(
            color: tokens.border.standard,
            radius: tokens.border.radius.standard,
          ),
        ),
      ),
    );
  }

  // ── Compact layout (not selected) ───────────────────────────────────────────

  Widget _buildCompactContent(DSTokensData tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.layout.s),
      child: Row(
        children: [
          _compactImage(tokens),
          SizedBox(width: tokens.spacing.component.s),
          Expanded(child: _textColumn(tokens)),
          if (widget.showStatus) ...[
            SizedBox(width: tokens.spacing.component.xxs),
            _statusIcon(tokens),
          ],
        ],
      ),
    );
  }

  Widget _compactImage(DSTokensData tokens) {
    final radius = BorderRadius.circular(tokens.border.radius.standard);
    if (widget.isLoading) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: Center(child: DSProgressCircle.medium()),
      );
    }
    if (widget.isDragTarget) {
      return SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: DSIcon.medium(
            iconRef: DSIcons.repeat,
            color: tokens.icon.subdued,
          ),
        ),
      );
    }
    if (widget.isDragSource) {
      return SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: DSIcon.medium(
            iconRef: DSIcons.archUpper,
            color: tokens.icon.disabled,
          ),
        ),
      );
    }
    if (widget.scanModel && widget.scanModelImage != null) {
      return Opacity(
        opacity: widget.disabled ? tokens.opacities.disabled : 1.0,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: 64,
            height: 64,
            child: _MultiplyLayer(child: widget.scanModelImage!),
          ),
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: tokens.background.standard,
        backgroundBlendMode: BlendMode.multiply,
        borderRadius: radius,
      ),
      child: Center(
        child: DSIcon.medium(
          iconRef: DSIcons.archUpper,
          color: widget.disabled ? tokens.icon.disabled : tokens.icon.subdued,
        ),
      ),
    );
  }

  // ── Expanded layout (selected) ───────────────────────────────────────────────

  Widget _buildExpandedContent(DSTokensData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _expandedImage(tokens),
        Padding(
          padding: EdgeInsets.all(tokens.spacing.component.m),
          child: Row(
            children: [
              Expanded(child: _textColumn(tokens)),
              if (widget.showStatus) ...[
                SizedBox(width: tokens.spacing.component.xxs),
                _statusIcon(tokens),
              ],
              if (widget.onRemovePressed != null)
                MouseRegion(
                  onEnter: (_) => setState(() => _isButtonHovered = true),
                  onExit: (_) => setState(() => _isButtonHovered = false),
                  child: DSActionsButton.iconTertiary(
                    icon: DSIcons.dotsVertical,
                    enabled: !widget.disabled,
                    actions: [
                      [
                        DSAction(
                          title: 'Remove catalog',
                          icon: DSIcons.removeCircle,
                          destructive: true,
                          onTrigger: widget.onRemovePressed,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expandedImage(DSTokensData tokens) {
    final topRadius = BorderRadius.vertical(
      top: Radius.circular(tokens.border.radius.standard),
    );
    if (widget.isLoading) {
      return AspectRatio(
        aspectRatio: 288 / 162,
        child: ClipRRect(
          borderRadius: topRadius,
          child: const Center(child: DSProgressCircle.medium()),
        ),
      );
    }
    if (widget.isDragTarget) {
      return AspectRatio(
        aspectRatio: 288 / 162,
        child: ClipRRect(
          borderRadius: topRadius,
          child: Center(
            child: DSIcon.large(
              iconRef: DSIcons.repeat,
              color: tokens.icon.subdued,
            ),
          ),
        ),
      );
    }
    if (widget.isDragSource) {
      // Empty transparent area — no icon, no background.
      return const AspectRatio(aspectRatio: 288 / 162);
    }
    if (widget.scanModel && widget.scanModelImage != null) {
      return Opacity(
        opacity: widget.disabled ? tokens.opacities.disabled : 1.0,
        child: AspectRatio(
          aspectRatio: 288 / 162,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.border.radius.standard),
            child: _MultiplyLayer(
              child: widget.scanModelImage!,
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 288 / 162,
      child: ClipRRect(
        borderRadius: topRadius,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.background.standard,
            backgroundBlendMode: BlendMode.multiply,
          ),
          child: Center(
            child: DSIcon.large(
              iconRef: DSIcons.archUpper,
              color: widget.disabled ? tokens.icon.disabled : tokens.icon.subdued,
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared sub-widgets ───────────────────────────────────────────────────────

  Widget _textColumn(DSTokensData tokens) {
    final String displayName;
    final Color nameColor;
    final Color subtextColor;

    if (widget.isDragTarget) {
      displayName = 'Switch';
      nameColor = _selected ? tokens.text.disabled : tokens.text.standard;
      subtextColor = tokens.text.subdued; // unused — subtext hidden for target
    } else if (widget.isDragSource) {
      displayName = widget.name;
      nameColor = _selected ? tokens.text.standard : tokens.text.disabled;
      subtextColor = tokens.text.disabled;
    } else {
      displayName = widget.name;
      nameColor = widget.disabled ? tokens.text.disabled : tokens.text.standard;
      subtextColor = widget.disabled ? tokens.text.disabled : tokens.text.subdued;
    }

    final showSub = widget.showSubtext && !widget.isDragTarget;

    final nameWidget = Text(
      displayName,
      style: tokens.text.textBase.copyWith(color: nameColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    final subtextWidget = Text(
      widget.subtext,
      style: tokens.text.textSm.copyWith(color: subtextColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    // Stack keeps the text block height constant regardless of subtext visibility.
    // The invisible column (non-positioned) always reserves space for both lines,
    // so the title can center itself in that fixed height when subtext is hidden.
    return Stack(
      children: [
        Opacity(
          opacity: 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [nameWidget, subtextWidget],
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment:
                showSub ? MainAxisAlignment.start : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameWidget,
              if (showSub) subtextWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusIcon(DSTokensData tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.component.xs),
      child: DSIcon.medium(
        iconRef: DSIcons.checkCircleFilled,
        color: widget.disabled ? tokens.icon.disabled : tokens.icon.success,
      ),
    );
  }
}

// Paints a 2 px dashed rounded-rect border — used for the drag-source
// placeholder appearance.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  static const double _strokeWidth = 2.0;
  static const double _dashWidth = 6.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final inset = _strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - _strokeWidth, size.height - _strokeWidth),
      Radius.circular(radius),
    );

    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashed.addPath(
          metric.extractPath(distance, distance + _dashWidth),
          Offset.zero,
        );
        distance += _dashWidth + _dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// Paints its child into an isolated layer with BlendMode.multiply so that
// white areas in the child (e.g. a live-stream background) blend with
// whatever the card has already drawn behind it — equivalent to CSS
// mix-blend-multiply. No scaling or opacity change is applied to the child.
class _MultiplyLayer extends SingleChildRenderObjectWidget {
  const _MultiplyLayer({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMultiplyLayer();
}

class _RenderMultiplyLayer extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(offset & size, Paint()..blendMode = BlendMode.multiply);
    super.paint(context, offset);
    context.canvas.restore();
  }
}
