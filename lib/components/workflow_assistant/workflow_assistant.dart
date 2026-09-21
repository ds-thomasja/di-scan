import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The two visual states of [WorkflowAssistant], matching the Figma "type"
/// variant (Default / Success).
enum WorkflowAssistantVariant {
  /// The informational state: a 32x32 px [DSIcons.activity] indicator,
  /// tinted `icon/information`.
  standard,

  /// The completion state: a 32x32 px `icon/success` circle badge containing
  /// a white [DSIcons.check] icon.
  success,
}

/// The floating "Workflow Assistant" panel, opened from [Toolbar]'s
/// Assistant pill (see `toolbar.dart`, which already wires
/// `DSIcons.activity` to a tooltip of this exact name).
///
/// Mirrors the Figma "WorkflowAssistant" component (node 4327:14315) and the
/// design definition in S3806-5447. A fixed-width (288 px) card, meant to be
/// positioned by the caller as a floating overlay near the 3D viewport. It
/// has a permanent indicator + title, and five independently-optional
/// content slots shown top to bottom: [description], [media], [bullets], a
/// switch-with-label toggle, and a secondary [buttonLabel] button. Each
/// slot's preceding gap collapses along with it when hidden.
///
/// Height changes are animated via [AnimatedSize], matching the resize
/// animation used by `CatalogCard` (see `catalog_card.dart`): 380ms,
/// [Curves.easeOutQuint], top-anchored so the card grows/shrinks from its
/// title downward instead of jumping. This covers a slot
/// appearing/disappearing, [description] rewrapping to a different number
/// of lines when its text changes, and [title] itself wrapping across up
/// to 3 lines (truncated with an ellipsis beyond that) as its text changes.
///
/// The close button is always shown; dismissal (removing the panel from the
/// tree) is the caller's responsibility, driven by [onClose].
class WorkflowAssistant extends StatelessWidget {
  /// Creates the Workflow Assistant panel.
  const WorkflowAssistant({
    super.key,
    this.variant = WorkflowAssistantVariant.standard,
    required this.title,
    this.description,
    this.media,
    this.bullets = const [],
    this.switchLabel,
    this.switchValue = false,
    this.onSwitchChanged,
    this.buttonLabel,
    this.onButtonPressed,
    required this.onClose,
  });

  /// The card width fixed by the Figma design; content area is
  /// `_width - 2 * _padding` (240 px).
  static const _width = 288.0;

  /// The card's outer padding. Fixed at 24 px, matching the Figma frame's
  /// literal (unbound) padding value — deliberately NOT `tokens.spacing
  /// .layout.l`, since that token is responsive to the *host app's* window
  /// width (24 px under `DSFormFactor.small`, but 48 px at any wider form
  /// factor). This card is a small, fixed-width floating overlay whose own
  /// padding must not double just because it happens to be shown in a wide
  /// window.
  static const _padding = 24.0;

  /// The title wraps across up to this many lines before truncating with
  /// an ellipsis.
  static const _titleMaxLines = 3;

  /// Which indicator/badge to render next to the title.
  final WorkflowAssistantVariant variant;

  /// The card's title, styled `heading2xl`. Wraps across up to
  /// [_titleMaxLines] lines, truncating with an ellipsis beyond that.
  final String title;

  /// Optional body copy shown below the title, styled `textLg`. Hidden
  /// (along with its preceding gap) when null.
  final String? description;

  /// An optional image or animation shown in a 240x150 px (1.6:1), rounded,
  /// bordered frame. Hidden (along with its preceding gap) when null.
  final Widget? media;

  /// Optional bullet items, each rendered with a small `icon/information`
  /// dot. Hidden (along with its preceding gap) when empty.
  final List<String> bullets;

  /// The label of the optional switch-with-label toggle row. The row (and
  /// its preceding gap) is hidden when null.
  final String? switchLabel;

  /// The toggle's current value. Host-owned; the panel never mutates it.
  final bool switchValue;

  /// Called when the toggle is tapped, with the proposed new value.
  final ValueChanged<bool>? onSwitchChanged;

  /// The label of the optional secondary action button. The button (and its
  /// preceding gap) is hidden when null.
  final String? buttonLabel;

  /// Called when the secondary action button is pressed.
  final VoidCallback? onButtonPressed;

  /// Called when the top-right close button is pressed.
  ///
  /// The panel does not remove itself; the host is expected to stop
  /// rendering it in response.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final description = this.description;
    final media = this.media;
    final switchLabel = this.switchLabel;
    final buttonLabel = this.buttonLabel;

    return SizedBox(
      width: _width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              color: tokens.surface.standard,
              borderRadius: BorderRadius.circular(tokens.border.radius.standard),
              boxShadow: tokens.shadows.elevation3,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutQuint,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Indicator(variant: variant),
                  SizedBox(height: tokens.spacing.layout.s),
                  Text(
                    title,
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.text.heading2xl.copyWith(color: tokens.text.standard),
                  ),
                  if (description != null) ...[
                    SizedBox(height: tokens.spacing.layout.xs),
                    Text(
                      description,
                      style: tokens.text.textLg.copyWith(color: tokens.text.standard),
                    ),
                  ],
                  if (media != null) ...[
                    SizedBox(height: tokens.spacing.layout.s),
                    _MediaFrame(child: media),
                  ],
                  if (bullets.isNotEmpty) ...[
                    SizedBox(height: tokens.spacing.layout.s),
                    _BulletList(bullets: bullets),
                  ],
                  if (switchLabel != null) ...[
                    SizedBox(height: tokens.spacing.layout.m),
                    DSSwitch(
                      label: switchLabel,
                      value: switchValue,
                      onChanged: onSwitchChanged,
                    ),
                  ],
                  if (buttonLabel != null) ...[
                    SizedBox(height: tokens.spacing.layout.m),
                    DSButton.secondary(
                      buttonText: buttonLabel,
                      onPressed: onButtonPressed,
                      stretch: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 21,
            child: DSButton.windowControlClose(onPressed: onClose),
          ),
        ],
      ),
    );
  }
}

/// The 32x32 px indicator next to the title: either the tinted `activity`
/// icon (standard) or a green `success` circle badge with a white check.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.variant});

  final WorkflowAssistantVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    // Wrapped in `Align` rather than left as a bare `SizedBox`: the parent
    // Column uses `CrossAxisAlignment.stretch` (needed by the media/switch/
    // button slots below, which must fill the card width per Figma), and a
    // fixed-size `SizedBox` placed directly under a stretched Column gets
    // its own width constraints forced to the full column width instead of
    // 32px — `Align` loosens those constraints first so the indicator stays
    // pinned to its natural 32x32 size at the left edge, matching the
    // Figma frame's `shrink-0` (non-stretching) indicator.
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 32,
        height: 32,
        child: switch (variant) {
          // Figma's "Icon" node for this variant is exactly 32x32 with the
          // activity glyph filling it edge to edge (no inner centering
          // margin) — not `DSIcon.medium`'s 24px, which would leave a 4px
          // gap on every side.
          WorkflowAssistantVariant.standard => DSIcon(
              iconRef: DSIcons.activity,
              iconSize: 32,
              color: tokens.icon.information,
            ),
          WorkflowAssistantVariant.success => DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.icon.success,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSIcon.medium(
                  iconRef: DSIcons.check,
                  color: tokens.icon.onInteractive,
                ),
              ),
            ),
        },
      ),
    );
  }
}

/// The 1.6:1, rounded, bordered frame around the optional [media] slot.
class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.border.radius.standard),
      child: AspectRatio(
        aspectRatio: 240 / 150,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.background.dimmer,
            border: Border.all(
              width: tokens.border.width.standard,
              color: tokens.border.standard,
            ),
            borderRadius: BorderRadius.circular(tokens.border.radius.standard),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A column of bullet items, each with a small `icon/information` dot.
class _BulletList extends StatelessWidget {
  const _BulletList({required this.bullets});

  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) SizedBox(height: tokens.spacing.component.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: tokens.spacing.component.xs),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: tokens.icon.information,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.component.s),
              Expanded(
                child: Text(
                  bullets[i],
                  style: tokens.text.textLg.copyWith(color: tokens.text.standard),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
