import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

/// The currently connected scanner shown by [HeaderMenuDevice].
///
/// Passing `null` as [HeaderMenuDevice.device] means "no scanner selected",
/// which switches the widget into its "Select scanner" prompt mode.
@immutable
class HeaderMenuConnectedDevice {
  const HeaderMenuConnectedDevice({
    required this.name,
    this.wifiName,
    this.batteryPercent,
  });

  /// Display name of the scanner, e.g. "Primescan 2".
  final String name;

  /// Name of the Wi-Fi network the scanner is connected to.
  ///
  /// When `null`, the panel's "WiFi" row (and its optional warning) is
  /// omitted. The trigger's network icon is always shown.
  final String? wifiName;

  /// Battery charge in percent (0–100).
  ///
  /// Forwarded verbatim to [DSBatteryIndicator.batteryLevel], which asserts
  /// the 0–100 range. When `null`, the trigger shows no battery indicator and
  /// the panel omits its "Battery" row (and its optional warning).
  final int? batteryPercent;
}

/// The three responsive layouts of the trigger, per the Figma variants
/// ">L", "M" and "S".
enum _Breakpoint { s, m, l }

/// The "Device" header menu button — shows the selected scanner (name,
/// network, battery) and opens a detail panel, or prompts to select a
/// scanner when none is connected.
///
/// Mirrors the Figma "Header menu - Device" component (file
/// "Equipment-Components", node 4457:15146).
///
/// **Modes**
/// - [device] is `null`: a warning icon plus "Select scanner" (">L") /
///   "Scanner" (M) / no text (S). Pressing it calls [onSelectScanner]; there
///   is no panel in this mode (Figma has no Open=true variant for it).
/// - [device] is set: device name (">L" only), a Wi-Fi icon, and a
///   [DSBatteryIndicator] (">L" and M; icon + percentage). At S only the
///   Wi-Fi icon remains. Pressing it opens the detail panel.
///
/// **Responsiveness** — the layout follows the app's own window-width
/// breakpoints via [DSFormFactor.of] (small → S, medium → M, large and
/// extra large → ">L"), since this is a top-level header item that should
/// rescale with the app window. [formFactor] can override this (the gallery
/// uses it to preview each breakpoint without resizing the browser). Note
/// that [DSBatteryIndicator] reads [DSFormFactor.of] itself and hides its
/// percentage when the *real* form factor is small, independent of
/// [formFactor].
///
/// **Badges** — [hasNetworkAlert], [hasBatteryAlert] and [hasCalibrationDue]
/// each add an 8×8 [DSBadge] pinned to the button's top-right corner,
/// independent of the breakpoint. Multiple badges sit side by side.
///
/// Opening/closing the panel is handled by [DSModalPopupAnchor], matching
/// `HeaderMenuSettings`; the button keeps its pressed look while the panel is
/// open, like the other header menus.
class HeaderMenuDevice extends StatefulWidget {
  const HeaderMenuDevice({
    super.key,
    this.device,
    this.hasNetworkAlert = false,
    this.hasBatteryAlert = false,
    this.hasCalibrationDue = false,
    this.hasMultipleDevices = false,
    this.networkWarningMessage,
    this.batteryWarningMessage,
    this.lowBatteryThreshold = 30,
    this.onSelectScanner,
    this.onChangeDevice,
    this.onTroubleshootNetwork,
    this.onSwitchScanner,
    this.formFactor,
  });

  /// The connected scanner, or `null` when no scanner is selected.
  final HeaderMenuConnectedDevice? device;

  /// Shows a warning badge for a network problem on the trigger.
  final bool hasNetworkAlert;

  /// Shows a critical badge for a battery problem on the trigger.
  final bool hasBatteryAlert;

  /// Shows an information badge signalling that calibration is due.
  final bool hasCalibrationDue;

  /// Whether other scanners are available; adds the "Change device" row at
  /// the bottom of the panel.
  final bool hasMultipleDevices;

  /// When non-null, an "Unstable connection" warning with this body text and
  /// a "Troubleshoot" link is shown under the panel's WiFi row. Also switches
  /// the trigger's network icon to [DSIcons.wifiLow].
  ///
  /// Ignored when [HeaderMenuConnectedDevice.wifiName] is `null`.
  final String? networkWarningMessage;

  /// When non-null, a "Low battery" warning with this body text and a
  /// "Switch scanner" link is shown under the panel's Battery row.
  ///
  /// Ignored when [HeaderMenuConnectedDevice.batteryPercent] is `null`.
  final String? batteryWarningMessage;

  /// Forwarded to [DSBatteryIndicator.lowLevelThreshold]; also colors the
  /// panel's battery row icon critical at or below it. Defaults to 30, the
  /// DS default.
  final int lowBatteryThreshold;

  /// Called when the trigger is pressed while no scanner is selected.
  final VoidCallback? onSelectScanner;

  /// Called (after the panel closes) when "Change device" is pressed.
  final VoidCallback? onChangeDevice;

  /// Called (after the panel closes) when the network warning's
  /// "Troubleshoot" link is pressed.
  final VoidCallback? onTroubleshootNetwork;

  /// Called (after the panel closes) when the battery warning's
  /// "Switch scanner" link is pressed.
  final VoidCallback? onSwitchScanner;

  /// Overrides the form factor used to pick the trigger layout. When `null`
  /// (the default), [DSFormFactor.of] is used.
  final DSFormFactor? formFactor;

  @override
  State<HeaderMenuDevice> createState() => _HeaderMenuDeviceState();
}

class _HeaderMenuDeviceState extends State<HeaderMenuDevice> {
  // Drives the trigger's pressed look while the panel is open.
  bool _open = false;

  _Breakpoint _breakpoint(BuildContext context) =>
      switch (widget.formFactor ?? DSFormFactor.of(context)) {
        DSFormFactor.small => _Breakpoint.s,
        DSFormFactor.medium => _Breakpoint.m,
        DSFormFactor.large || DSFormFactor.extraLarge => _Breakpoint.l,
      };

  bool get _weakNetwork =>
      widget.hasNetworkAlert ||
      (widget.networkWarningMessage != null && widget.device?.wifiName != null);

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final breakpoint = _breakpoint(context);

    final Widget button;
    if (device == null) {
      button = _trigger(
        context,
        tooltip: breakpoint == _Breakpoint.s ? 'Select scanner' : null,
        onPressed: widget.onSelectScanner ?? () {},
        children: _noDeviceContent(context, breakpoint),
      );
    } else {
      button = DSModalPopupAnchor<void>(
        preferredPosition: DSPopupPosition.bottomRight,
        alternativePositions: const [
          DSPopupPosition.bottomLeft,
          DSPopupPosition.topRight,
        ],
        anchorContentBuilder: (context, openPopup) => _trigger(
          context,
          tooltip: breakpoint == _Breakpoint.l ? null : device.name,
          clickableState: _open ? DSClickableState.pressed : null,
          onPressed: () async {
            setState(() => _open = true);
            await openPopup();
            if (mounted) setState(() => _open = false);
          },
          children: _deviceContent(context, breakpoint, device),
        ),
        popupBuilder: (context, _, pop, _) => _DevicePanel(
          device: device,
          hasMultipleDevices: widget.hasMultipleDevices,
          networkWarningMessage: widget.networkWarningMessage,
          batteryWarningMessage: widget.batteryWarningMessage,
          lowBatteryThreshold: widget.lowBatteryThreshold,
          weakNetwork: _weakNetwork,
          // Close the panel first, then notify the host.
          onChangeDevice: () {
            pop();
            widget.onChangeDevice?.call();
          },
          onTroubleshootNetwork: () {
            pop();
            widget.onTroubleshootNetwork?.call();
          },
          onSwitchScanner: () {
            pop();
            widget.onSwitchScanner?.call();
          },
        ),
      );
    }

    final badges = _badges(context);
    if (badges.isEmpty) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: DSTokens.of(context).spacing.component.xxs,
              children: badges,
            ),
          ),
        ),
      ],
    );
  }

  /// The tertiary-styled button chrome shared by both modes.
  ///
  /// Built on [DSCrudeButton] with the tertiary theme — the same primitive and
  /// theme `HeaderMenuSettings` uses — so Default/Hover/Focus/Pressed
  /// backgrounds match the other header buttons.
  Widget _trigger(
    BuildContext context, {
    required String? tooltip,
    required VoidCallback onPressed,
    required List<Widget> children,
    DSClickableState? clickableState,
  }) {
    final tokens = DSTokens.of(context);
    final button = DSCrudeButton(
      clickableState: clickableState,
      themeData: DSCrudeButtonThemeData.tertiary(tokens),
      onPressed: onPressed,
      builder: (context, state) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.component.m,
          vertical: tokens.spacing.component.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.component.xs,
          children: children,
        ),
      ),
    );
    return tooltip == null
        ? button
        : DSTooltip(message: tooltip, child: button);
  }

  List<Widget> _noDeviceContent(BuildContext context, _Breakpoint breakpoint) {
    final tokens = DSTokens.of(context);
    final label = switch (breakpoint) {
      _Breakpoint.l => 'Select scanner',
      _Breakpoint.m => 'Scanner',
      _Breakpoint.s => null,
    };
    return [
      DSIcon(
        iconRef: DSIcons.warning,
        iconSize: tokens.icon.size.m,
        color: tokens.icon.warning,
      ),
      if (label != null) _triggerText(tokens, label),
    ];
  }

  List<Widget> _deviceContent(
    BuildContext context,
    _Breakpoint breakpoint,
    HeaderMenuConnectedDevice device,
  ) {
    final tokens = DSTokens.of(context);
    final batteryPercent = device.batteryPercent;
    return [
      if (breakpoint == _Breakpoint.l)
        Flexible(child: _triggerText(tokens, device.name)),
      DSIcon(
        iconRef: _weakNetwork ? DSIcons.wifiLow : DSIcons.wifiHigh,
        iconSize: tokens.icon.size.m,
      ),
      if (breakpoint != _Breakpoint.s && batteryPercent != null)
        DSBatteryIndicator(
          batteryLevel: batteryPercent,
          lowLevelThreshold: widget.lowBatteryThreshold,
        ),
    ];
  }

  Widget _triggerText(DSTokensData tokens, String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: tokens.text.textAction.copyWith(color: tokens.text.standard),
  );

  List<Widget> _badges(BuildContext context) => [
    if (widget.hasNetworkAlert)
      const _Badge(label: 'Network alert', type: DSNotificationType.warning),
    if (widget.hasBatteryAlert)
      const _Badge(label: 'Battery alert', type: DSNotificationType.critical),
    if (widget.hasCalibrationDue)
      const _Badge(
        label: 'Calibration due',
        type: DSNotificationType.information,
      ),
  ];
}

/// An 8×8 [DSBadge] dot with an accessible label.
///
/// [DSBadge] positions itself via `Positioned.fill` + `Align`, so it is
/// hosted in a Stack of the badge's own standard diameter.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.type});

  final String label;
  final DSNotificationType type;

  static const double _diameter = 8;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SizedBox.square(
      dimension: _diameter,
      child: Stack(
        children: [
          DSBadge.forNotification(
            alignment: Alignment.center,
            notificationType: type,
          ),
        ],
      ),
    ),
  );
}

/// The detail panel opened from the trigger in connected mode.
class _DevicePanel extends StatelessWidget {
  const _DevicePanel({
    required this.device,
    required this.hasMultipleDevices,
    required this.networkWarningMessage,
    required this.batteryWarningMessage,
    required this.lowBatteryThreshold,
    required this.weakNetwork,
    required this.onChangeDevice,
    required this.onTroubleshootNetwork,
    required this.onSwitchScanner,
  });

  final HeaderMenuConnectedDevice device;
  final bool hasMultipleDevices;
  final String? networkWarningMessage;
  final String? batteryWarningMessage;
  final int lowBatteryThreshold;
  final bool weakNetwork;
  final VoidCallback onChangeDevice;
  final VoidCallback onTroubleshootNetwork;
  final VoidCallback onSwitchScanner;

  /// Figma panel width (node 4457:15146, dropdown frame).
  static const double _width = 283;

  static DSIconRef _batteryIcon(int percent) => switch (percent) {
    >= 90 => DSIcons.batteryFull,
    >= 60 => DSIcons.batteryHigh,
    >= 30 => DSIcons.batteryMid,
    > 0 => DSIcons.batteryLow,
    _ => DSIcons.batteryEmpty,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final gap = SizedBox(height: tokens.spacing.component.xs);
    final wifiName = device.wifiName;
    final batteryPercent = device.batteryPercent;
    final networkWarningMessage = this.networkWarningMessage;
    final batteryWarningMessage = this.batteryWarningMessage;

    final sections = <List<Widget>>[
      [_DetailRow(icon: DSIcons.label, headline: 'Name', subtext: device.name)],
      if (wifiName != null)
        [
          _DetailRow(
            icon: weakNetwork ? DSIcons.wifiLow : DSIcons.wifiHigh,
            headline: 'WiFi',
            subtext: wifiName,
          ),
          if (networkWarningMessage != null) ...[
            gap,
            DSInlineNotification(
              notificationType: DSNotificationType.warning,
              title: 'Unstable connection',
              message: networkWarningMessage,
              actions: [
                DSNotificationAction(
                  title: 'Troubleshoot',
                  onTrigger: onTroubleshootNetwork,
                ),
              ],
            ),
          ],
        ],
      if (batteryPercent != null)
        [
          _DetailRow(
            icon: _batteryIcon(batteryPercent),
            iconColor: batteryPercent <= lowBatteryThreshold
                ? tokens.icon.critical
                : null,
            headline: 'Battery',
            subtext: '$batteryPercent%',
          ),
          if (batteryWarningMessage != null) ...[
            gap,
            DSInlineNotification(
              notificationType: DSNotificationType.warning,
              title: 'Low battery',
              message: batteryWarningMessage,
              actions: [
                DSNotificationAction(
                  title: 'Switch scanner',
                  onTrigger: onSwitchScanner,
                ),
              ],
            ),
          ],
        ],
      if (hasMultipleDevices) [_ChangeDeviceRow(onPressed: onChangeDevice)],
    ];

    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      if (i > 0) {
        children
          ..add(gap)
          ..add(const DSDivider.horizontal())
          ..add(gap);
      }
      children.addAll(sections[i]);
    }

    // DS controls inside need a Material ancestor, which the popup route
    // doesn't provide — same treatment as HeaderMenuSettings' panel.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: _width,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Icon + headline + subtext row used by the panel's info sections.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.headline,
    required this.subtext,
    this.iconColor,
  });

  final DSIconRef icon;
  final String headline;
  final String subtext;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.component.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.component.xs,
        children: [
          DSIcon(iconRef: icon, iconSize: tokens.icon.size.m, color: iconColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: tokens.text.textBase.copyWith(
                    color: tokens.text.standard,
                  ),
                ),
                Text(
                  subtext,
                  style: tokens.text.textSm.copyWith(
                    color: tokens.text.subdued,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The single-line, tappable "Change device" row.
class _ChangeDeviceRow extends StatelessWidget {
  const _ChangeDeviceRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    return DSCrudeButton(
      themeData: DSCrudeButtonThemeData.tertiary(tokens),
      onPressed: onPressed,
      builder: (context, state) => Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.component.xs),
        child: Text(
          'Change device',
          style: tokens.text.textBase.copyWith(color: tokens.text.standard),
        ),
      ),
    );
  }
}
