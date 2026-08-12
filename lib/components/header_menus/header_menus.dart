import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// Which header menu button this instance renders, mirroring the Figma
/// `Type` variant of the "Header Menus" component (node 4806:26687).
enum HeaderMenuType { settings, help, more }

/// Seat position options in the Settings menu's "View" section.
enum SeatPosition { facingForLowerBehindForUpper, alwaysNextToOrFacing, alwaysBehind }

/// One of the three icon buttons in the app header — Settings, Help or More —
/// that opens a dropdown menu/panel when pressed.
///
/// Mirrors the Figma "Header Menus" component (node 4806:26687):
/// - `Type` = Settings | Help | More → picked via the named constructors
///   [HeaderMenus.settings], [HeaderMenus.help], [HeaderMenus.more].
/// - `Open` = true | false documents each button's popped-up appearance. It
///   is not exposed as a field here: opening/closing is handled natively by
///   the underlying DS popup widgets ([DSActionsButton] for Help/More,
///   [DSModalPopupAnchor] for Settings), which already provide correct
///   dismiss-on-outside-tap and focus behaviour — reimplementing that via an
///   externally driven boolean would only duplicate state they already own.
///
/// All three menus open right-aligned to their button (bottom-right anchor,
/// extending down-left), matching the Figma frame: the three icons sit near
/// the right edge of the 396px-wide "Header Menus" header, so their menus
/// are meant to open into the space to their left.
///
/// The Settings panel's controls (render style, autorotation, sound, seat
/// position, holes detection) keep local demo state seeded from the values
/// shown in the Figma "Open=true" snapshot; they are not wired to real
/// scanning behaviour.
class HeaderMenus extends StatefulWidget {
  /// The "More" header menu: Create design / Open in Canvas / Finish and close.
  const HeaderMenus.more({
    super.key,
    this.onCreateDesign,
    this.onOpenInCanvas,
    this.onFinishAndClose,
  })  : type = HeaderMenuType.more,
        onGiveFeedback = null,
        onOnboarding = null;

  /// The "Help" header menu: Give feedback / Onboarding.
  const HeaderMenus.help({
    super.key,
    this.onGiveFeedback,
    this.onOnboarding,
  })  : type = HeaderMenuType.help,
        onCreateDesign = null,
        onOpenInCanvas = null,
        onFinishAndClose = null;

  /// The "Settings" header menu: a scanning-preferences panel.
  const HeaderMenus.settings({super.key})
      : type = HeaderMenuType.settings,
        onCreateDesign = null,
        onOpenInCanvas = null,
        onFinishAndClose = null,
        onGiveFeedback = null,
        onOnboarding = null;

  /// Which header menu this instance renders (Figma `Type` variant).
  final HeaderMenuType type;

  /// Called when "Create design" is selected in the More menu.
  final VoidCallback? onCreateDesign;

  /// Called when "Open in Canvas" is selected in the More menu.
  final VoidCallback? onOpenInCanvas;

  /// Called when "Finish and close" is selected in the More menu.
  final VoidCallback? onFinishAndClose;

  /// Called when "Give feedback" is selected in the Help menu.
  final VoidCallback? onGiveFeedback;

  /// Called when "Onboarding" is selected in the Help menu.
  final VoidCallback? onOnboarding;

  @override
  State<HeaderMenus> createState() => _HeaderMenusState();
}

class _HeaderMenusState extends State<HeaderMenus> {
  // Tracks whether the Settings popup is open, purely to drive the anchor
  // button's selected/pressed look (matches Figma's Open=true style).
  bool _settingsOpen = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case HeaderMenuType.more:
        return DSActionsButton.iconTertiary(
          icon: DSIcons.dotsVertical,
          tooltip: 'More',
          actions: [
            [
              DSAction(
                title: 'Create design',
                icon: DSIcons.toothDesign,
                onTrigger: widget.onCreateDesign,
              ),
              DSAction(
                title: 'Open in Canvas',
                icon: DSIcons.canvas,
                onTrigger: widget.onOpenInCanvas,
              ),
              DSAction(
                title: 'Finish and close',
                icon: DSIcons.close,
                onTrigger: widget.onFinishAndClose,
              ),
            ],
          ],
        );
      case HeaderMenuType.help:
        return DSActionsButton.iconTertiary(
          icon: DSIcons.helpCircle,
          tooltip: 'Help',
          actions: [
            [
              DSAction(
                title: 'Give feedback',
                icon: DSIcons.comment,
                onTrigger: widget.onGiveFeedback,
              ),
              DSAction(
                title: 'Onboarding',
                icon: DSIcons.annotations,
                onTrigger: widget.onOnboarding,
              ),
            ],
          ],
        );
      case HeaderMenuType.settings:
        return DSModalPopupAnchor<void>(
          preferredPosition: DSPopupPosition.bottomRight,
          alternativePositions: const [
            DSPopupPosition.bottomLeft,
            DSPopupPosition.topRight,
          ],
          anchorContentBuilder: (context, openPopup) {
            final tokens = DSTokens.of(context);
            // DSToggleButton's `selected` look is tinted (for persistent
            // filter-style toggles) and doesn't match the neutral "pressed"
            // look DSActionsButton forces on More/Help while their popup is
            // open. Build directly on the same DSCrudeButton + tertiary
            // theme so all three header buttons share one open-state look.
            return DSTooltip(
              message: 'Settings',
              child: DSCrudeButton(
                clickableState: _settingsOpen ? DSClickableState.pressed : null,
                themeData: DSCrudeButtonThemeData.tertiary(tokens),
                onPressed: () async {
                  setState(() => _settingsOpen = true);
                  await openPopup();
                  if (mounted) setState(() => _settingsOpen = false);
                },
                builder: (context, state) => Padding(
                  padding: EdgeInsets.all(tokens.spacing.component.xs),
                  child: DSIcon(
                    iconRef: DSIcons.settingsLinesHorizontal,
                    iconSize: tokens.icon.size.m,
                  ),
                ),
              ),
            );
          },
          popupBuilder: (context, _, _, _) => const _SettingsPanel(),
        );
    }
  }
}

/// The Settings menu's popup content: render style, autorotation, sound,
/// seat position and holes-detection controls (Figma node 4806:27969).
class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  static const _renderStyleOptions = ['White light (Default)'];
  static const _soundOptions = ['Pulse'];

  String _renderStyle = _renderStyleOptions.first;
  bool _autorotation = true;
  bool _feedbackActiveScanning = true;
  String _sound = _soundOptions.first;
  double _soundVolume = 50;
  SeatPosition _seatPosition = SeatPosition.facingForLowerBehindForUpper;
  bool _highlightHoles = true;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final sectionGap = SizedBox(height: tokens.spacing.component.m);
    final itemGap = SizedBox(height: tokens.spacing.component.xs);

    // DSSlider and other Material-based DS controls need a Material
    // ancestor, which the popup route doesn't provide on its own — wrap the
    // panel like DSOptionList's own popup content does.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 272 + 2 * tokens.spacing.component.m,
        decoration: BoxDecoration(
          color: tokens.surface.standard,
          borderRadius: BorderRadius.circular(tokens.border.radius.standard),
          boxShadow: tokens.shadows.elevation3,
        ),
        padding: EdgeInsets.symmetric(
          vertical: tokens.spacing.component.xs,
          horizontal: tokens.spacing.component.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(tokens, 'Render style'),
            itemGap,
            DSDropdown<String>(
              items: _renderStyleOptions
                  .map((option) => DSDropdownItem(title: option, value: option))
                  .toList(),
              value: _renderStyle,
              onChanged: (value) => setState(() => _renderStyle = value ?? _renderStyle),
              stretch: true,
            ),
            sectionGap,
            DSSwitch(
              label: 'Autotoration',
              value: _autorotation,
              onChanged: (value) => setState(() => _autorotation = value),
            ),
            sectionGap,
            const DSDivider.horizontal(),
            sectionGap,
            _header(tokens, 'Sound'),
            itemGap,
            DSSwitch(
              label: 'Feedback active scanning',
              value: _feedbackActiveScanning,
              onChanged: (value) => setState(() => _feedbackActiveScanning = value),
            ),
            sectionGap,
            DSDropdown<String>(
              items: _soundOptions
                  .map((option) => DSDropdownItem(title: option, value: option))
                  .toList(),
              value: _sound,
              onChanged: (value) => setState(() => _sound = value ?? _sound),
              stretch: true,
            ),
            sectionGap,
            DSSlider(
              value: _soundVolume,
              onChanged: (value) => setState(() => _soundVolume = value),
              min: 0,
              max: 100,
              divisions: 10,
              showMinMax: true,
              showValueIndicator: DSSliderShowValueIndicator.never,
            ),
            sectionGap,
            const DSDivider.horizontal(),
            sectionGap,
            _header(tokens, 'View'),
            Text(
              'Seat position relative to patient',
              style: tokens.text.textBase.copyWith(color: tokens.text.standard),
            ),
            itemGap,
            DSRadio<SeatPosition>(
              value: SeatPosition.facingForLowerBehindForUpper,
              groupValue: _seatPosition,
              label: 'Facing for lower, behind for upper',
              onChanged: (value) => setState(() => _seatPosition = value),
            ),
            itemGap,
            DSRadio<SeatPosition>(
              value: SeatPosition.alwaysNextToOrFacing,
              groupValue: _seatPosition,
              label: 'Always next to or facing',
              onChanged: (value) => setState(() => _seatPosition = value),
            ),
            itemGap,
            DSRadio<SeatPosition>(
              value: SeatPosition.alwaysBehind,
              groupValue: _seatPosition,
              label: 'Always behind',
              onChanged: (value) => setState(() => _seatPosition = value),
            ),
            sectionGap,
            const DSDivider.horizontal(),
            sectionGap,
            _header(tokens, 'Holes detection'),
            itemGap,
            DSSwitch(
              label: 'Highlight holes',
              value: _highlightHoles,
              onChanged: (value) => setState(() => _highlightHoles = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DSTokensData tokens, String text) => Text(
        text,
        style: tokens.text.textBaseStrong.copyWith(color: tokens.text.standard),
      );
}
