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

  /// The card the user is currently dragging over. Shows a dropzone
  /// background with a dashed interactive border, an interactive-colored
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
  /// Fixed card width, both layouts (Figma frame width).
  static const _cardWidth = 288.0;

  /// Compact thumbnail edge length.
  static const _thumbSize = 64.0;

  /// Expanded image aspect ratio (Figma: 288×162).
  static const _imageAspect = 288 / 162;

  /// Press-in duration of the whole-card scale feedback.
  static const _pressDuration = Duration(milliseconds: 80);

  /// Background colour cross-fade between interaction states.
  static const _backgroundDuration = Duration(milliseconds: 200);

  /// Compact ↔ expanded resize. No DS animation token matches 380 ms, so it
  /// is kept as a named constant; `WorkflowAssistant` uses the same value
  /// and curve for its own resize (see `workflow_assistant.dart`).
  static const _resizeDuration = Duration(milliseconds: 380);

  late bool _selected;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  /// Mouse is over the ⋮ actions button: suppresses the card's hover/press
  /// visuals while pointing at the button.
  bool _isButtonHovered = false;

  /// A pointer (touch, mouse or stylus) is currently down on the ⋮ actions
  /// button. Needed because touch has no hover: without it, holding a finger
  /// on the button would still trigger the card's press scale. A plain field
  /// (no rebuild needed) — it is only read in [_handleTapDown].
  bool _pointerDownOnButton = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void didUpdateWidget(CatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected;
    }
  }

  void _handleTap() {
    if (widget.disabled) return;
    widget.onTap?.call();
    final next = !_selected;
    setState(() => _selected = next);
    widget.onSelectedChanged?.call(next);
  }

  void _handleTapDown(TapDownDetails _) {
    if (_pointerDownOnButton || _isButtonHovered) return;
    setState(() => _isPressed = true);
  }

  bool get _pressFeedback => _isPressed && !_isButtonHovered;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return SizedBox(
      width: _cardWidth,
      // Semantics: announced as a (toggle-like) button whose selected state
      // mirrors the expanded layout. The ⋮ actions button keeps its own node.
      child: Semantics(
        container: true,
        button: true,
        selected: _selected,
        enabled: !widget.disabled,
        child: FocusableActionDetector(
          enabled: !widget.disabled,
          // Enter/Space activate the focused card like a tap. Default
          // shortcuts map Enter/Space to ActivateIntent on native and to
          // ButtonActivateIntent (Enter) on web, so handle both.
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _handleTap(),
            ),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (_) => _handleTap(),
            ),
          },
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          child: GestureDetector(
            onTap: _handleTap,
            onTapDown: widget.disabled ? null : _handleTapDown,
            onTapUp: widget.disabled ? null : (_) => setState(() => _isPressed = false),
            onTapCancel: widget.disabled ? null : () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _pressFeedback ? 0.97 : 1.0,
              duration: _pressFeedback
                  ? _pressDuration
                  : tokens.animation.duration.macroForward,
              curve: _pressFeedback ? Curves.easeInCubic : Curves.easeOut,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildCard(tokens),
                  if (_selected && !widget.isDragSource && !widget.isDragTarget)
                    _buildSelectionOverlay(tokens),
                  if (widget.isDragSource) _buildDragSourceOverlay(tokens),
                  if (widget.isDragTarget) _buildDragTargetOverlay(tokens),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(DSTokensData tokens) {
    // Disabled and loading suppress all interaction feedback.
    if (widget.disabled || widget.isLoading) return tokens.surface.standard;
    if (widget.isDragSource) return tokens.surface.subdued;
    if (widget.isDragTarget) return tokens.surface.dropzone;
    if (_pressFeedback) return tokens.surface.pressed;
    // Focus keeps the standard surface (the focus border is the feedback).
    if (_isHovered && !_isButtonHovered && !_isFocused) return tokens.surface.hovered;
    return tokens.surface.standard;
  }

  BoxBorder _border(DSTokensData tokens) {
    if (widget.isDragSource) return Border.all(color: Colors.transparent);
    if (widget.isDragTarget) return Border.all(color: Colors.transparent);
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
        duration: _backgroundDuration,
        curve: Curves.easeOut,
        color: _backgroundColor(tokens),
        child: DecoratedBox(
          decoration: BoxDecoration(border: _border(tokens), borderRadius: radius),
          position: DecorationPosition.foreground,
          child: AnimatedSize(
            duration: _resizeDuration,
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

  Widget _buildDragTargetOverlay(DSTokensData tokens) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DashedRoundedBorderPainter(
            color: tokens.border.interactive,
            radius: tokens.border.radius.standard,
            strokeWidth: tokens.border.width.dropzone,
          ),
        ),
      ),
    );
  }

  // ── Compact layout (not selected) ───────────────────────────────────────────

  Widget _buildCompactContent(DSTokensData tokens) {
    // component.m (16 px), not layout.s: layout.* shrinks to 12 px below an
    // 840 px window width, which would make this fixed 288×96 card 88 px high.
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.component.m),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.border.radius.standard),
            child: SizedBox.square(
              dimension: _thumbSize,
              child: _imageContent(tokens, large: false),
            ),
          ),
          SizedBox(width: tokens.spacing.component.s),
          Expanded(child: _textColumn(tokens)),
          if (widget.showStatus && !widget.isDragTarget && !widget.isDragSource) ...[
            SizedBox(width: tokens.spacing.component.xxs),
            _statusIcon(tokens),
          ],
        ],
      ),
    );
  }

  // ── Expanded layout (selected) ───────────────────────────────────────────────

  Widget _buildExpandedContent(DSTokensData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _imageAspect,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(tokens.border.radius.standard),
            ),
            child: _imageContent(tokens, large: true),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(tokens.spacing.component.m),
          child: Row(
            children: [
              Expanded(child: _textColumn(tokens)),
              if (widget.showStatus && !widget.isDragTarget && !widget.isDragSource) ...[
                SizedBox(width: tokens.spacing.component.xxs),
                _statusIcon(tokens),
              ],
              if (widget.onRemovePressed != null && !widget.isDragSource)
                _actionsButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// The ⋮ overflow menu. [MouseRegion] keeps the mouse-only hover guard;
  /// [Listener] adds a pointer-down guard that also covers touch (see
  /// [_pointerDownOnButton]). The button's own tap recognizer wins the
  /// gesture arena, so a tap on it never reaches the card's `onTap`.
  Widget _actionsButton() {
    return Listener(
      onPointerDown: (_) => _pointerDownOnButton = true,
      onPointerUp: (_) => _pointerDownOnButton = false,
      onPointerCancel: (_) => _pointerDownOnButton = false,
      child: MouseRegion(
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
    );
  }

  /// The image slot's content, shared by both layouts. The caller provides
  /// the wrapper: a fixed rounded square (compact) or a top-rounded
  /// [AspectRatio] (expanded). Priority: loading → drag target → drag source
  /// → scan image → arch placeholder.
  Widget _imageContent(DSTokensData tokens, {required bool large}) {
    final iconSize = large ? tokens.icon.size.l : tokens.icon.size.m;
    if (widget.isLoading) {
      return const Center(child: DSProgressCircle.medium());
    }
    if (widget.isDragTarget) {
      return Center(
        child: DSIcon(
          iconRef: DSIcons.repeat,
          iconSize: iconSize,
          color: tokens.icon.interactive,
        ),
      );
    }
    if (widget.isDragSource) {
      // Expanded: empty transparent area — no icon, no background.
      if (large) return const SizedBox.shrink();
      return Center(
        child: DSIcon(
          iconRef: DSIcons.archUpper,
          iconSize: iconSize,
          color: tokens.icon.disabled,
        ),
      );
    }
    final scanModelImage = widget.scanModelImage;
    if (widget.scanModel && scanModelImage != null) {
      return Opacity(
        opacity: widget.disabled ? tokens.opacities.disabled : 1.0,
        child: _MultiplyLayer(child: scanModelImage),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background.standard,
        backgroundBlendMode: BlendMode.multiply,
      ),
      child: Center(
        child: DSIcon(
          iconRef: DSIcons.archUpper,
          iconSize: iconSize,
          color: widget.disabled ? tokens.icon.disabled : tokens.icon.subdued,
        ),
      ),
    );
  }

  // ── Shared sub-widgets ───────────────────────────────────────────────────────

  Widget _textColumn(DSTokensData tokens) {
    // Drag source and disabled both render all text disabled-styled; the drag
    // target shows a fixed interactive "Switch" label and hides the subtext.
    final muted = widget.isDragSource || widget.disabled;
    final displayName = widget.isDragTarget ? 'Switch' : widget.name;
    final nameColor = widget.isDragTarget
        ? tokens.text.interactive
        : muted
            ? tokens.text.disabled
            : tokens.text.standard;
    final subtextColor = muted ? tokens.text.disabled : tokens.text.subdued;

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
    this.strokeWidth = 2.0,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  static const double _dashWidth = 6.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
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
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
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
