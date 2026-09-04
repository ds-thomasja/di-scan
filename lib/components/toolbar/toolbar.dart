import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The floating scan-control toolbar anchored at the bottom centre of the
/// 3D viewport.
///
/// Mirrors the Figma "Toolbar" component (node 2815:22380) and the design
/// definition in S3806-5062. It is a horizontal row of up to two floating
/// pill cards, separated by `spacing/component/xxs` (4 px):
///
/// 1. The optional **Assistant pill** ([assistant], default `true`): a single
///    toggle button that opens the Workflow Assistant panel.
/// 2. The permanent **Main pill**: three groups separated by vertical
///    dividers —
///    - Cut-Tool and Trash (plain icon buttons),
///    - Color-Mode (plain icon button) and Autorotation (toggle button),
///    - Video-View (toggle button).
///
/// The three toggle buttons are **not** stateful: per [DSToggleButton]'s
/// contract, their `selected` value is owned by the host and fed back in
/// through [assistantActive], [autorotationActive] and [videoViewActive]. The
/// three plain icon buttons fire their callback immediately and have no
/// persistent visual state.
///
/// Per the design definition, no button has a disabled state; passing `null`
/// for a callback therefore only makes that button inert, it does not render a
/// disabled look.
///
/// Positioning is the caller's responsibility: the design places this widget
/// with a [Positioned] at `bottom: 0`, horizontally centred inside the 3D
/// viewport's [Stack]. The toolbar itself shrink-wraps to its content and has
/// no fixed size or breakpoints.
class Toolbar extends StatelessWidget {
  /// Creates the scan toolbar.
  const Toolbar({
    super.key,
    this.assistant = true,
    this.assistantActive = false,
    this.onAssistantPressed,
    this.onCutTool,
    this.onTrash,
    this.onColorMode,
    this.autorotationActive = false,
    this.onAutorotationPressed,
    this.videoViewActive = false,
    this.onVideoViewPressed,
  });

  /// Whether the Assistant pill is rendered to the left of the main pill.
  ///
  /// Defaults to `true`, matching the Figma variant default. When `false`,
  /// only the main pill is visible and the 4 px inter-pill gap collapses.
  final bool assistant;

  /// Whether the Assistant toggle button renders as selected.
  ///
  /// Host-owned; the toolbar never mutates it.
  final bool assistantActive;

  /// Called when the Assistant toggle button is pressed.
  ///
  /// The host is expected to flip [assistantActive] in response.
  final VoidCallback? onAssistantPressed;

  /// Called when the Cut-Tool icon button is pressed.
  final VoidCallback? onCutTool;

  /// Called when the Trash icon button is pressed.
  final VoidCallback? onTrash;

  /// Called when the Color-Mode icon button is pressed.
  final VoidCallback? onColorMode;

  /// Whether the autorotation toggle button renders as selected.
  ///
  /// Host-owned; the toolbar never mutates it.
  final bool autorotationActive;

  /// Called when the autorotation toggle button is pressed.
  ///
  /// The host is expected to flip [autorotationActive] in response.
  final VoidCallback? onAutorotationPressed;

  /// Whether the Video-View toggle button renders as selected.
  ///
  /// Host-owned; the toolbar never mutates it.
  final bool videoViewActive;

  /// Called when the Video-View toggle button is pressed.
  ///
  /// The host is expected to flip [videoViewActive] in response.
  final VoidCallback? onVideoViewPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (assistant) ...[
          _ToolbarPill(
            groups: [
              [
                _ToggleItem(
                  icon: DSIcons.activity,
                  tooltip: 'Assistant',
                  semanticsLabel: 'Workflow Assistant',
                  selected: assistantActive,
                  onPressed: onAssistantPressed,
                ),
              ],
            ],
          ),
          SizedBox(width: tokens.spacing.component.xxs),
        ],
        _ToolbarPill(
          groups: [
            [
              _IconItem(
                icon: DSIcons.cutTool,
                tooltip: 'Cut scan',
                semanticsLabel: 'Cut Tool',
                onPressed: onCutTool,
              ),
              _IconItem(
                icon: DSIcons.trash,
                tooltip: 'Reset selected scan data',
                semanticsLabel: 'Delete scan',
                onPressed: onTrash,
              ),
            ],
            [
              _IconItem(
                icon: DSIcons.colorMode,
                tooltip: 'Change appearance',
                semanticsLabel: 'Color Mode',
                onPressed: onColorMode,
              ),
              _ToggleItem(
                icon: DSIcons.movementContinous,
                tooltip: 'Toggle autorotation',
                semanticsLabel: 'Autorotation',
                selected: autorotationActive,
                onPressed: onAutorotationPressed,
              ),
            ],
            [
              _ToggleItem(
                icon: DSIcons.videoView,
                tooltip: 'Toggle live view',
                semanticsLabel: 'Video View',
                selected: videoViewActive,
                onPressed: onVideoViewPressed,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One floating pill card of the [Toolbar]: a shrink-wrapped, elevated,
/// rounded surface holding [groups] of buttons separated by vertical
/// [DSDivider]s.
///
/// The DS library does have an internal widget for exactly this shape
/// (`DSFocusModeToolbar`), but it is **not** part of the package's public API
/// — `lib/src/widgets/focus_mode/index.dart` is never re-exported from
/// `lightning_core_ui.dart`, and that is still true in every published tag up
/// to v52.0.0 (this project is pinned to v51.0.0). Reaching into `lib/src` is
/// against this project's import rules, so the card chrome is composed here
/// instead — but strictly from the same design tokens that
/// `DSFocusModeToolbarThemeData` itself reads, so the result is
/// token-equivalent rather than hand-tuned:
///
/// | This widget                             | `DSFocusModeToolbarThemeData` |
/// | --------------------------------------- | ----------------------------- |
/// | `surface.standard`                      | `backgroundColor`             |
/// | `border.radius.standard`                | `borderRadius`                |
/// | `shadows.elevation1`                    | `shadow`                      |
/// | `spacing.component.xs` (padding)        | `padding`                     |
/// | `spacing.component.xs` (item spacing)   | `spacing`                     |
///
/// The one deliberate difference: the DS widget gives its group dividers a
/// hard-coded 40 px cross-axis size (with a source `TODO` wishing they would
/// stretch instead). Here [IntrinsicHeight] plus
/// [CrossAxisAlignment.stretch] lets the dividers stretch to the pill's actual
/// content height, which is what the design definition asks for
/// (`align-self: stretch`).
class _ToolbarPill extends StatelessWidget {
  const _ToolbarPill({required this.groups});

  /// The button groups, in main-axis order. A vertical divider is drawn
  /// between consecutive groups, never before the first or after the last.
  final List<List<Widget>> groups;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final gap = SizedBox(width: tokens.spacing.component.xs);

    final children = <Widget>[];
    for (final (groupIndex, group) in groups.indexed) {
      if (groupIndex > 0) {
        children.addAll([gap, const DSDivider.vertical(), gap]);
      }
      for (final (itemIndex, item) in group.indexed) {
        if (itemIndex > 0) children.add(gap);
        children.add(item);
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface.standard,
        borderRadius: BorderRadius.circular(tokens.border.radius.standard),
        boxShadow: tokens.shadows.elevation1,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.component.xs),
        // IntrinsicHeight sizes the row to its tallest child (a 40 px button),
        // which then gives the otherwise-unbounded DSDivider.vertical a
        // definite height to stretch into.
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A plain, single-action icon-only button inside a toolbar pill.
///
/// This DS version has no dedicated `DSIconButton`, so this follows the exact
/// pattern already used for the Settings anchor button in `header_menus.dart`:
/// a [DSCrudeButton] with the tertiary theme (transparent at rest, with the
/// standard DS hover/pressed backgrounds) wrapping a medium [DSIcon] padded by
/// `spacing/component/xs`, all inside a [_ToolbarTooltip]. That yields the 8 px
/// padding around a 24 px icon — a 40x40 px tap target — that the design
/// definition specifies, and it matches the intrinsic size of the neighbouring
/// [DSToggleButton]s so the pill's dividers line up with them.
class _IconItem extends StatelessWidget {
  const _IconItem({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
    this.onPressed,
  });

  final DSIconRef icon;
  final String tooltip;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      child: _ToolbarTooltip(
        message: tooltip,
        child: DSCrudeButton(
          themeData: DSCrudeButtonThemeData.tertiary(tokens),
          onPressed: onPressed,
          builder: (context, state) => Padding(
            padding: EdgeInsets.all(tokens.spacing.component.xs),
            child: DSIcon(
              iconRef: icon,
              iconSize: tokens.icon.size.m,
            ),
          ),
        ),
      ),
    );
  }
}

/// A toggle button inside a toolbar pill.
///
/// A thin wrapper over [DSToggleButton] that adds the accessible label
/// required by the design definition and overrides its tooltip placement —
/// the icon, padding and the `surface-selected/standard` selected background
/// all come from [DSToggleButton] itself, but its *tooltip* param is left
/// unset in favour of wrapping the whole button in [_ToolbarTooltip]: see
/// that widget's doc comment for why.
class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
    required this.selected,
    this.onPressed,
  });

  final DSIconRef icon;
  final String tooltip;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      toggled: selected,
      label: semanticsLabel,
      child: _ToolbarTooltip(
        message: tooltip,
        child: DSToggleButton(
          icon: icon,
          selected: selected,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// A tooltip for a toolbar button that always prefers showing *above* its
/// child, matching the design definition (the Toolbar is anchored at the
/// bottom of the viewport, so a tooltip opening downward would run off
/// screen).
///
/// [DSTooltip] (and, through it, [DSToggleButton]'s built-in `tooltip` param)
/// hard-codes `preferBelow: true` via the internal, unexported
/// `DSTooltipThemeData` in this DS version, with no constructor parameter to
/// override it — confirmed by reading `lib/src/theme/components/token_based/
/// ds_tooltip_theme_data.dart` in the pinned v51.0.0 checkout. Rather than
/// reach into `lib/src`, this rebuilds the same visual styling directly from
/// the public tokens that class itself reads (`surface.contrast`,
/// `text.textXs`/`text.onContrast`, `border.radius.small`,
/// `shadows.elevation2`, `spacing.component.xs`/`xxs`,
/// `animation.duration.macroForward`) around a plain Flutter [Tooltip] with
/// `preferBelow: false`.
class _ToolbarTooltip extends StatelessWidget {
  const _ToolbarTooltip({required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Tooltip(
      message: message,
      preferBelow: false,
      // Half of the 40 px button tap target (8 px padding + 24 px icon),
      // matching DSTooltipWrapper's own `anchorSize.height / 2`.
      verticalOffset: 20,
      margin: EdgeInsets.all(tokens.spacing.component.xxs),
      waitDuration: tokens.animation.duration.macroForward,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.component.xs,
        vertical: tokens.spacing.component.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.border.radius.small),
        color: tokens.surface.contrast,
        boxShadow: tokens.shadows.elevation2,
      ),
      textStyle: tokens.text.textXs.copyWith(color: tokens.text.onContrast),
      child: child,
    );
  }
}
