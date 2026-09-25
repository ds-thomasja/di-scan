import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// Seat position options in the Settings menu's "View" section.
enum SeatPosition {
  facingForLowerBehindForUpper,
  alwaysNextToOrFacing,
  alwaysBehind,
}

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
/// holes detection) keep demo state seeded from the values shown in the
/// Figma "Open=true" snapshot; they are not wired to real scanning
/// behaviour. That state is owned by this widget's [State] (not by the popup
/// content), so values survive closing and reopening the panel for as long
/// as [HeaderMenuSettings] stays mounted.
class HeaderMenuSettings extends StatefulWidget {
  const HeaderMenuSettings({
    super.key,
    this.showRenderStyle = true,
    this.showSound = true,
    this.showView = true,
    this.showHolesDetection = true,
  });

  /// Whether the "Render style" section renders in the panel. Figma's node
  /// always shows all four sections; this only exists so the gallery
  /// playground can preview the panel with sections hidden.
  final bool showRenderStyle;

  /// Whether the "Sound" section renders in the panel.
  final bool showSound;

  /// Whether the "View" section renders in the panel.
  final bool showView;

  /// Whether the "Holes detection" section renders in the panel.
  final bool showHolesDetection;

  @override
  State<HeaderMenuSettings> createState() => _HeaderMenuSettingsState();
}

class _HeaderMenuSettingsState extends State<HeaderMenuSettings> {
  // Tracks whether the Settings popup is open, purely to drive the anchor
  // button's selected/pressed look (matches Figma's Open=true style).
  bool _settingsOpen = false;

  // Lives here rather than in the popup content: the popup route's widgets
  // are disposed on close, which previously reset every value on reopen.
  final _values = _SettingsValues();

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

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
      popupBuilder: (context, _, _, _) => _SettingsPanel(
        values: _values,
        showRenderStyle: widget.showRenderStyle,
        showSound: widget.showSound,
        showView: widget.showView,
        showHolesDetection: widget.showHolesDetection,
      ),
    );
  }
}

/// The panel's control values, owned by [_HeaderMenuSettingsState].
///
/// A [ChangeNotifier] rather than plain fields plus `setState`: the popup
/// lives in its own route, which isn't guaranteed to rebuild when the anchor
/// widget does, so the panel listens to this object directly.
class _SettingsValues extends ChangeNotifier {
  static const renderStyleOptions = ['White light (Default)'];
  static const soundOptions = ['Pulse'];

  String _renderStyle = renderStyleOptions.first;
  bool _autorotation = true;
  bool _feedbackActiveScanning = true;
  String _sound = soundOptions.first;
  double _soundVolume = 50;
  SeatPosition _seatPosition = SeatPosition.facingForLowerBehindForUpper;
  bool _highlightHoles = true;

  String get renderStyle => _renderStyle;
  set renderStyle(String value) => _update(() => _renderStyle = value);

  bool get autorotation => _autorotation;
  set autorotation(bool value) => _update(() => _autorotation = value);

  bool get feedbackActiveScanning => _feedbackActiveScanning;
  set feedbackActiveScanning(bool value) =>
      _update(() => _feedbackActiveScanning = value);

  String get sound => _sound;
  set sound(String value) => _update(() => _sound = value);

  double get soundVolume => _soundVolume;
  set soundVolume(double value) => _update(() => _soundVolume = value);

  SeatPosition get seatPosition => _seatPosition;
  set seatPosition(SeatPosition value) => _update(() => _seatPosition = value);

  bool get highlightHoles => _highlightHoles;
  set highlightHoles(bool value) => _update(() => _highlightHoles = value);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

/// The Settings menu's popup content: render style, autorotation, sound,
/// seat position and holes-detection controls (Figma node 4806:27969).
///
/// Stateless: reads and writes [values], which outlives the popup.
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.values,
    required this.showRenderStyle,
    required this.showSound,
    required this.showView,
    required this.showHolesDetection,
  });

  final _SettingsValues values;
  final bool showRenderStyle;
  final bool showSound;
  final bool showView;
  final bool showHolesDetection;

  /// Seat-position radio labels, in display order.
  static const _seatPositionLabels = {
    SeatPosition.facingForLowerBehindForUpper:
        'Facing for lower, behind for upper',
    SeatPosition.alwaysNextToOrFacing: 'Always next to or facing',
    SeatPosition.alwaysBehind: 'Always behind',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: values,
      builder: (context, _) => _buildPanel(DSTokens.of(context)),
    );
  }

  Widget _buildPanel(DSTokensData tokens) {
    final sectionGap = SizedBox(height: tokens.spacing.component.m);
    final itemGap = SizedBox(height: tokens.spacing.component.xs);

    final sections = [
      if (showRenderStyle) _renderStyleSection(tokens, itemGap),
      if (showSound) _soundSection(tokens, itemGap, sectionGap),
      if (showView) _viewSection(tokens, itemGap, sectionGap),
      if (showHolesDetection) _holesDetectionSection(tokens, itemGap),
    ];

    // Figma's panel has an extra XS-scale spacer between the panel's own
    // top padding and the first section, and an extra S-scale (component.m)
    // spacer between the last section and the panel's bottom padding — on
    // top of the panel's own symmetric component.xs padding below. That
    // makes the panel 16px clear at the top (8 padding + 8 spacer) but 24px
    // clear at the bottom (8 padding + 16 spacer), confirmed against the
    // Figma node (5620:27629): not a symmetric inset.
    final children = <Widget>[itemGap];
    for (var i = 0; i < sections.length; i++) {
      if (i > 0) {
        children.add(sectionGap);
        children.add(const DSDivider.horizontal());
        children.add(sectionGap);
      }
      children.add(sections[i]);
    }
    children.add(sectionGap);

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
          children: children,
        ),
      ),
    );
  }

  Widget _renderStyleSection(DSTokensData tokens, Widget itemGap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(tokens, 'Render style'),
        itemGap,
        DSDropdown<String>(
          items: _SettingsValues.renderStyleOptions
              .map((option) => DSDropdownItem(title: option, value: option))
              .toList(),
          value: values.renderStyle,
          onChanged: (value) =>
              values.renderStyle = value ?? values.renderStyle,
          stretch: true,
        ),
      ],
    );
  }

  Widget _soundSection(DSTokensData tokens, Widget itemGap, Widget sectionGap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(tokens, 'Sound'),
        itemGap,
        DSSwitch(
          label: 'Feedback active scanning',
          value: values.feedbackActiveScanning,
          onChanged: (value) => values.feedbackActiveScanning = value,
        ),
        sectionGap,
        DSDropdown<String>(
          items: _SettingsValues.soundOptions
              .map((option) => DSDropdownItem(title: option, value: option))
              .toList(),
          value: values.sound,
          onChanged: (value) => values.sound = value ?? values.sound,
          stretch: true,
        ),
        sectionGap,
        DSSlider(
          value: values.soundVolume,
          onChanged: (value) => values.soundVolume = value,
          min: 0,
          max: 100,
          showMinMax: true,
          showValueIndicator: DSSliderShowValueIndicator.never,
        ),
      ],
    );
  }

  Widget _viewSection(DSTokensData tokens, Widget itemGap, Widget sectionGap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(tokens, 'View'),
        itemGap,
        DSSwitch(
          label: 'Autorotation',
          value: values.autorotation,
          onChanged: (value) => values.autorotation = value,
        ),
        sectionGap,
        Text(
          'Seat position relative to patient',
          style: tokens.text.textBase.copyWith(color: tokens.text.standard),
        ),
        for (final MapEntry(key: position, value: label)
            in _seatPositionLabels.entries) ...[
          itemGap,
          DSRadio<SeatPosition>(
            value: position,
            groupValue: values.seatPosition,
            label: label,
            onChanged: (value) => values.seatPosition = value,
          ),
        ],
      ],
    );
  }

  Widget _holesDetectionSection(DSTokensData tokens, Widget itemGap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(tokens, 'Holes detection'),
        itemGap,
        DSSwitch(
          label: 'Highlight holes',
          value: values.highlightHoles,
          onChanged: (value) => values.highlightHoles = value,
        ),
      ],
    );
  }

  Widget _header(DSTokensData tokens, String text) => Text(
    text,
    style: tokens.text.textBaseStrong.copyWith(color: tokens.text.standard),
  );
}
