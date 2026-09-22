import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// Seat position options in the Settings menu's "View" section.
enum SeatPosition { facingForLowerBehindForUpper, alwaysNextToOrFacing, alwaysBehind }

/// The "Settings" header menu button — a sliders icon that opens a
/// scanning-preferences panel.
///
/// Mirrors the Figma "Header Menu Settings" component (node 5620:27629).
/// Opening/closing is handled by [DSModalPopupAnchor], which already
/// provides correct dismiss-on-outside-tap and focus behaviour.
///
/// The panel opens right-aligned to the button (bottom-right anchor,
/// extending down-left), matching the Figma frame: the button sits near the
/// right edge of the header, so its panel is meant to open into the space to
/// its left.
///
/// The panel's controls (render style, autorotation, sound, seat position,
/// holes detection) keep local demo state seeded from the values shown in
/// the Figma "Open=true" snapshot; they are not wired to real scanning
/// behaviour.
class HeaderMenuSettings extends StatefulWidget {
  const HeaderMenuSettings({super.key});

  @override
  State<HeaderMenuSettings> createState() => _HeaderMenuSettingsState();
}

class _HeaderMenuSettingsState extends State<HeaderMenuSettings> {
  // Tracks whether the Settings popup is open, purely to drive the anchor
  // button's selected/pressed look (matches Figma's Open=true style).
  bool _settingsOpen = false;

  @override
  Widget build(BuildContext context) {
    return DSModalPopupAnchor<void>(
      preferredPosition: DSPopupPosition.bottomRight,
      alternativePositions: const [
        DSPopupPosition.bottomLeft,
        DSPopupPosition.topRight,
      ],
      anchorContentBuilder: (context, openPopup) {
        final tokens = DSTokens.of(context);
        // DSToggleButton's `selected` look is tinted (for persistent
        // filter-style toggles) and doesn't match the neutral "pressed" look
        // DSActionsButton forces on the other header buttons while their
        // popup is open. Build directly on the same DSCrudeButton + tertiary
        // theme so all header buttons share one open-state look.
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
