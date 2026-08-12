import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';
import '../catalog_card/catalog_card.dart';

class CatalogListItem {
  const CatalogListItem({
    required this.name,
    this.subtext = '',
    this.showSubtext = true,
    this.scanModel = false,
    this.scanModelImage,
    this.showStatus = false,
    this.disabled = false,
  });

  final String name;
  final String subtext;
  final bool showSubtext;
  final bool scanModel;
  final Widget? scanModelImage;
  final bool showStatus;
  final bool disabled;
}

/// A vertically stacked list of [CatalogCard] widgets with single-selection.
///
/// Selection state is managed internally. The currently selected index is
/// exposed via [onSelectionChanged]. Pass [selectedIndex] to control the
/// initial selection; subsequent changes are owned by this widget.
///
/// Long-pressing a card activates drag mode: a floating copy of the card
/// (compact icon layout with elevation shadow) follows the pointer until
/// the press is released.
class CatalogList extends StatefulWidget {
  const CatalogList({
    super.key,
    required this.items,
    this.selectedIndex,
    this.spacing = 8.0,
    this.onSelectionChanged,
    this.onRemovePressed,
  });

  final List<CatalogListItem> items;

  /// Initial selected index. `null` means nothing is selected.
  final int? selectedIndex;

  /// Vertical gap between cards.
  final double spacing;

  /// Called when the selected index changes. `null` means deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Called when a card's remove action is triggered, with the item's index.
  final ValueChanged<int>? onRemovePressed;

  @override
  State<CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends State<CatalogList> {
  int? _selectedIndex;
  int? _draggingIndex;
  int? _dragTargetIndex;
  Set<int> _loadingIndices = {};
  Timer? _loadingTimer;
  OverlayEntry? _dragOverlay;
  final _dragPosition = ValueNotifier<Offset>(Offset.zero);
  final _dragHasTarget = ValueNotifier<bool>(false);

  // One key per list item to resolve each card's screen position.
  late List<GlobalKey> _cardKeys;
  Offset _dragStartPointer = Offset.zero;
  Offset _cardInitialTopLeft = Offset.zero;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _cardKeys = List.generate(widget.items.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(CatalogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if (oldWidget.items.length != widget.items.length) {
      _cardKeys = List.generate(widget.items.length, (_) => GlobalKey());
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _dragOverlay?.remove();
    _dragOverlay = null;
    _dragPosition.dispose();
    _dragHasTarget.dispose();
    super.dispose();
  }

  void _handleSelectionChanged(int index, bool selected) {
    final next = selected ? index : null;
    setState(() => _selectedIndex = next);
    widget.onSelectionChanged?.call(next);
  }

  void _startDrag(int index, Offset pointerGlobal) {
    final renderBox = _cardKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _cardInitialTopLeft = renderBox.localToGlobal(Offset.zero);
    _dragStartPointer = pointerGlobal;
    _draggingIndex = index;
    _dragPosition.value = _cardInitialTopLeft;

    final item = widget.items[index];
    _dragOverlay = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Offset>(
        valueListenable: _dragPosition,
        builder: (context, position, _) => ValueListenableBuilder<bool>(
          valueListenable: _dragHasTarget,
          builder: (context, hasTarget, _) => Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              color: Colors.transparent,
              child: _DraggableCatalogCard(
                name: item.name,
                subtext: item.subtext,
                showSubtext: item.showSubtext,
                isOverTarget: hasTarget,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_dragOverlay!);
    setState(() {});
  }

  void _updateDrag(Offset pointerGlobal) {
    if (_dragOverlay == null) return;
    final delta = pointerGlobal - _dragStartPointer;
    _dragPosition.value = _cardInitialTopLeft + delta;

    int? newTarget;
    for (int i = 0; i < _cardKeys.length; i++) {
      if (i == _draggingIndex) continue;
      final rb = _cardKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (rb == null) continue;
      final base = rb.localToGlobal(Offset.zero) & rb.size;
      final halfGap = widget.spacing / 2;
      final rect = Rect.fromLTRB(
        base.left, base.top - halfGap, base.right, base.bottom + halfGap,
      );
      if (rect.contains(pointerGlobal)) {
        newTarget = i;
        break;
      }
    }
    if (newTarget != _dragTargetIndex) {
      setState(() => _dragTargetIndex = newTarget);
      _dragHasTarget.value = newTarget != null;
    }
  }

  void _endDrag() {
    _dragOverlay?.remove();
    _dragOverlay = null;
    _dragHasTarget.value = false;

    final sourceIndex = _draggingIndex;
    final targetIndex = _dragTargetIndex;

    if (mounted) {
      setState(() {
        _draggingIndex = null;
        _dragTargetIndex = null;
        if (sourceIndex != null && targetIndex != null) {
          _loadingIndices = {sourceIndex, targetIndex};
        }
      });
    }

    if (sourceIndex != null && targetIndex != null) {
      _loadingTimer?.cancel();
      _loadingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _loadingIndices = {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.items.length; i++) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          GestureDetector(
            key: _cardKeys[i],
            onLongPressStart: (widget.items[i].disabled || _loadingIndices.contains(i))
                ? null
                : (details) => _startDrag(i, details.globalPosition),
            onLongPressMoveUpdate: (details) => _updateDrag(details.globalPosition),
            onLongPressEnd: (_) => _endDrag(),
            onLongPressCancel: _endDrag,
            child: CatalogCard(
              key: ValueKey(i),
              name: widget.items[i].name,
              subtext: widget.items[i].subtext,
              showSubtext: widget.items[i].showSubtext,
              scanModel: widget.items[i].scanModel,
              scanModelImage: widget.items[i].scanModelImage,
              showStatus: widget.items[i].showStatus,
              disabled: widget.items[i].disabled,
              isDragSource: _draggingIndex == i,
              isDragTarget: _dragTargetIndex == i,
              isLoading: _loadingIndices.contains(i),
              selected: _selectedIndex == i,
              onSelectedChanged: (v) => _handleSelectionChanged(i, v),
              onRemovePressed: widget.onRemovePressed != null
                  ? () => widget.onRemovePressed!(i)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

// Floating card rendered in the Overlay while a drag is active.
// Always uses the compact icon layout (arch-upper) regardless of whether
// the source card has a scan model image.
class _DraggableCatalogCard extends StatelessWidget {
  const _DraggableCatalogCard({
    required this.name,
    required this.subtext,
    required this.showSubtext,
    required this.isOverTarget,
  });

  final String name;
  final String subtext;
  final bool showSubtext;
  final bool isOverTarget;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return SizedBox(
      width: 288,
      height: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface.standard,
          borderRadius: BorderRadius.circular(tokens.border.radius.standard),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.layout.s),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.background.standard,
                  borderRadius: BorderRadius.circular(tokens.border.radius.standard),
                ),
                child: Center(
                  child: DSIcon.medium(
                    iconRef: isOverTarget ? DSIcons.repeat : DSIcons.archUpper,
                    color: tokens.icon.subdued,
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.component.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: tokens.text.textBase.copyWith(
                        color: tokens.text.standard,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (showSubtext)
                      Text(
                        subtext,
                        style: tokens.text.textSm.copyWith(
                          color: tokens.text.subdued,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
