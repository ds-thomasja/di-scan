import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The "Help" header menu button — a question-mark icon that opens a dropdown
/// menu with About DI Scan / Give feedback / Onboarding.
///
/// Mirrors the Figma "Header Menu Help" component (node 5620:29386). Opening
/// and closing the popup is handled natively by [DSActionsButton], which
/// already provides correct dismiss-on-outside-tap and focus behaviour.
///
/// The menu opens right-aligned to the button (bottom-right anchor,
/// extending down-left), matching the Figma frame: the button sits near the
/// right edge of the header, so its menu is meant to open into the space to
/// its left.
class HeaderMenuHelp extends StatelessWidget {
  const HeaderMenuHelp({
    super.key,
    this.onAboutDiScan,
    this.onGiveFeedback,
    this.onOnboarding,
  });

  /// Called when "About DI Scan" is selected.
  final VoidCallback? onAboutDiScan;

  /// Called when "Give feedback" is selected.
  final VoidCallback? onGiveFeedback;

  /// Called when "Onboarding" is selected.
  final VoidCallback? onOnboarding;

  @override
  Widget build(BuildContext context) {
    return DSActionsButton.iconTertiary(
      icon: DSIcons.helpCircle,
      tooltip: 'Help',
      actions: [
        [
          DSAction(
            title: 'About DI Scan',
            icon: DSIcons.infoCircle,
            // Falls back to a no-op so the row stays enabled (hover/pressed
            // states testable) even when the host hasn't wired an action.
            onTrigger: onAboutDiScan ?? () {},
          ),
          DSAction(
            title: 'Give feedback',
            icon: DSIcons.comment,
            onTrigger: onGiveFeedback ?? () {},
          ),
          DSAction(
            title: 'Onboarding',
            icon: DSIcons.annotations,
            onTrigger: onOnboarding ?? () {},
          ),
        ],
      ],
    );
  }
}
