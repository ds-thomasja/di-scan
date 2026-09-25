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
/// the press is released. Dropping onto another card calls
/// [onSwitchRequested]; the list itself never mutates [items]. While the
/// host performs the switch it can show spinners on the affected cards via
/// [loadingIndices].
class CatalogList extends StatefulWidget {
  const CatalogList({
    super.key,
    required this.items,
    this.selectedIndex,
    this.spacing = 12.0,
    this.loadingIndices = const {},
    this.onSelectionChanged,
    this.onRemovePressed,
    this.onAddPressed,
    this.onSwitchRequested,
  });

  final List<CatalogListItem> items;

  /// Initial selected index. `null` means nothing is selected.
  final int? selectedIndex;

  /// Vertical gap between cards.
  final double spacing;

  /// Indices of cards that show a loading spinner (e.g. while the host
  /// performs a switch requested via [onSwitchRequested]). Host-owned; the
  /// list never changes it. Loading cards cannot start a drag.
  final Set<int> loadingIndices;

  /// Called when the selected index changes. `null` means deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Called when a card's remove action is triggered, with the item's index.
  final ValueChanged<int>? onRemovePressed;

  /// Called when the trailing "Add scan" button is pressed. The button is
  /// disabled when null.
  final VoidCallback? onAddPressed;

  /// Called when a drag is released over another card, with the dragged
  /// card's index ([source]) and the card it was dropped on ([target]).
  /// The host is responsible for reordering [items] and, if desired, for
  /// marking both indices as [loadingIndices] while that happens.
  final void Function(int source, int target)? onSwitchRequested;

  @override
  State<CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends State<CatalogList> {
  int? _selectedIndex;
  int? _draggingIndex;
  int? _dragTargetIndex;
  OverlayEntry? _dragOverlay;
  final _dragPosition = ValueNotifier<Offset>(Offset.zero);

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
    _dragOverlay?.remove();
    _dragOverlay = null;
    _dragPosition.dispose();
    super.dispose();
  }

  void _handleSelectionChanged(int index, bool selected) {
    final next = selected ? index : null;
    setState(() => _selectedIndex = next);
    widget.onSelectionChanged?.call(next);
  }

  void _startDrag(int index, Offset pointerGlobal) {
    final renderBox =
        _cardKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _cardInitialTopLeft = renderBox.localToGlobal(Offset.zero);
    _dragStartPointer = pointerGlobal;
    _draggingIndex = index;
    _dragPosition.value = _cardInitialTopLeft;

    final item = widget.items[index];
    _dragOverlay = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Offset>(
        valueListenable: _dragPosition,
        builder: (context, position, _) => Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: _DraggableCatalogCard(item: item),
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
        base.left,
        base.top - halfGap,
        base.right,
        base.bottom + halfGap,
      );
      if (rect.contains(pointerGlobal)) {
        newTarget = i;
        break;
      }
    }
    if (newTarget != _dragTargetIndex) {
      setState(() => _dragTargetIndex = newTarget);
    }
  }

  void _endDrag() {
    _dragOverlay?.remove();
    _dragOverlay = null;

    final sourceIndex = _draggingIndex;
    final targetIndex = _dragTargetIndex;

    if (mounted) {
      setState(() {
        _draggingIndex = null;
        _dragTargetIndex = null;
      });
    }

    if (sourceIndex != null && targetIndex != null) {
      widget.onSwitchRequested?.call(sourceIndex, targetIndex);
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
            onLongPressStart:
                (widget.items[i].disabled || widget.loadingIndices.contains(i))
                ? null
                : (details) => _startDrag(i, details.globalPosition),
            onLongPressMoveUpdate: (details) =>
                _updateDrag(details.globalPosition),
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
              isLoading: widget.loadingIndices.contains(i),
              selected: _selectedIndex == i,
              onSelectedChanged: (v) => _handleSelectionChanged(i, v),
              onRemovePressed: widget.onRemovePressed != null
                  ? () => widget.onRemovePressed!(i)
                  : null,
            ),
          ),
        ],
        if (widget.items.isNotEmpty) SizedBox(height: widget.spacing),
        DSButton.secondary(
          icon: DSIcons.add,
          buttonText: 'Add scan',
          stretch: true,
          onPressed: widget.onAddPressed,
        ),
      ],
    );
  }
}

// Floating card rendered in the Overlay while a drag is active.
//
// Reuses [CatalogCard]'s compact layout (so the two cannot drift apart) with
// the drag-copy rules applied: always the compact arch-upper icon layout
// (`selected: false`, `scanModel: false`, so no scan image), never the green
// status check (`showStatus: false`), plus an elevation-3 shadow. The icon
// background keeps CatalogCard's own `BlendMode.multiply`. Pointer and focus
// are excluded — the copy is purely visual.
class _DraggableCatalogCard extends StatelessWidget {
  const _DraggableCatalogCard({required this.item});

  final CatalogListItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.border.radius.standard),
        boxShadow: tokens.shadows.elevation3,
      ),
      child: ExcludeFocus(
        child: IgnorePointer(
          child: CatalogCard(
            name: item.name,
            subtext: item.subtext,
            showSubtext: item.showSubtext,
            selected: false,
            scanModel: false,
            showStatus: false,
          ),
        ),
      ),
    );
  }
}
