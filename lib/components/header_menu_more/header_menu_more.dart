import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The "More" header menu button — a kebab icon that opens a dropdown menu
/// with Create design / Open in Canvas / Finish and close.
///
/// Mirrors the Figma "Header Menu More" component (node 4806:26687). Opening
/// and closing the popup is handled natively by [DSActionsButton], which
/// already provides correct dismiss-on-outside-tap and focus behaviour.
///
/// The menu opens right-aligned to the button (bottom-right anchor,
/// extending down-left), matching the Figma frame: the button sits near the
/// right edge of the header, so its menu is meant to open into the space to
/// its left.
class HeaderMenuMore extends StatelessWidget {
  const HeaderMenuMore({
    super.key,
    this.onCreateDesign,
    this.onOpenInCanvas,
    this.onFinishAndClose,
  });

  /// Called when "Create design" is selected.
  final VoidCallback? onCreateDesign;

  /// Called when "Open in Canvas" is selected.
  final VoidCallback? onOpenInCanvas;

  /// Called when "Finish and close" is selected.
  final VoidCallback? onFinishAndClose;

  @override
  Widget build(BuildContext context) {
    return DSActionsButton.iconTertiary(
      icon: DSIcons.dotsVertical,
      tooltip: 'More',
      actions: [
        [
          DSAction(
            title: 'Create design',
            icon: DSIcons.toothDesign,
            onTrigger: onCreateDesign,
          ),
          DSAction(
            title: 'Open in Canvas',
            icon: DSIcons.canvas,
            onTrigger: onOpenInCanvas,
          ),
          DSAction(
            title: 'Finish and close',
            icon: DSIcons.close,
            onTrigger: onFinishAndClose,
          ),
        ],
      ],
    );
  }
}
