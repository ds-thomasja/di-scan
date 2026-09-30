import 'dart:ui' show Size;

import 'package:flutter/material.dart' show MaterialApp, Tooltip, Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'package:di_scan/components/application_loading/application_loading.dart';
import 'package:di_scan/components/catalog_card/catalog_card.dart';
import 'package:di_scan/components/catalog_list/catalog_list.dart';
import 'package:di_scan/components/header_menu_device/header_menu_device.dart';
import 'package:di_scan/components/header_menu_help/header_menu_help.dart';
import 'package:di_scan/components/header_menu_more/header_menu_more.dart';
import 'package:di_scan/components/header_menu_settings/header_menu_settings.dart';
import 'package:di_scan/components/toolbar/toolbar.dart';
import 'package:di_scan/components/workflow_assistant/workflow_assistant.dart';
import 'package:di_scan/main.dart';

void main() {
  testWidgets('Component gallery shows one live, controls-driven component at a '
      'time via the sidebar', (WidgetTester tester) async {
    // A viewport large enough to lay out the sidebar, preview and controls
    // panel without overflowing.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The sidebar lists every component, alphabetically.
    expect(find.text('CatalogCard'), findsOneWidget);
    expect(find.text('CatalogList'), findsOneWidget);
    expect(find.text('HeaderMenuDevice'), findsOneWidget);
    expect(find.text('HeaderMenuHelp'), findsOneWidget);
    expect(find.text('HeaderMenuMore'), findsOneWidget);
    expect(find.text('HeaderMenuSettings'), findsOneWidget);
    expect(find.text('Toolbar'), findsOneWidget);
    expect(find.text('WorkflowAssistant'), findsOneWidget);

    // ApplicationLoading is first alphabetically, so it's selected by default:
    // its label appears both in the sidebar and as the content heading.
    expect(find.text('ApplicationLoading'), findsNWidgets(2));
    expect(find.byType(ApplicationLoading), findsOneWidget);
    expect(find.byType(CatalogCard), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(HeaderMenuHelp), findsNothing);
    expect(find.byType(HeaderMenuMore), findsNothing);
    expect(find.byType(HeaderMenuSettings), findsNothing);
    expect(find.byType(Toolbar), findsNothing);

    // Selecting CatalogCard in the sidebar swaps the main content.
    await tester.tap(find.text('CatalogCard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CatalogCard'), findsNWidgets(2));
    expect(find.byType(CatalogCard), findsOneWidget);
    expect(find.byType(ApplicationLoading), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(HeaderMenuMore), findsNothing);

    // Selecting CatalogList in the sidebar swaps the main content.
    await tester.tap(find.text('CatalogList'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CatalogList'), findsNWidgets(2));
    expect(find.byType(CatalogList), findsOneWidget);
    expect(find.byType(CatalogCard), findsNWidgets(3)); // inside CatalogList
    expect(find.byType(HeaderMenuMore), findsNothing);

    // Selecting HeaderMenuMore in the sidebar swaps the main content again.
    await tester.tap(find.text('HeaderMenuMore'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenuMore'), findsNWidgets(2));
    expect(find.byType(HeaderMenuMore), findsOneWidget);
    expect(find.byType(CatalogCard), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(HeaderMenuHelp), findsNothing);
    expect(find.byType(HeaderMenuSettings), findsNothing);
    expect(find.byType(Toolbar), findsNothing);

    // Selecting HeaderMenuHelp in the sidebar swaps the main content again.
    await tester.tap(find.text('HeaderMenuHelp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenuHelp'), findsNWidgets(2));
    expect(find.byType(HeaderMenuHelp), findsOneWidget);
    expect(find.byType(HeaderMenuMore), findsNothing);
    expect(find.byType(HeaderMenuSettings), findsNothing);

    // Selecting HeaderMenuSettings in the sidebar swaps the main content again.
    await tester.tap(find.text('HeaderMenuSettings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenuSettings'), findsNWidgets(2));
    expect(find.byType(HeaderMenuSettings), findsOneWidget);
    expect(find.byType(HeaderMenuHelp), findsNothing);

    // Selecting HeaderMenuDevice in the sidebar swaps the main content again.
    await tester.tap(find.text('HeaderMenuDevice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenuDevice'), findsNWidgets(2));
    expect(find.byType(HeaderMenuDevice), findsOneWidget);
    expect(find.byType(HeaderMenuSettings), findsNothing);

    // Selecting Toolbar in the sidebar swaps the main content again.
    await tester.tap(find.text('Toolbar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Toolbar'), findsNWidgets(2));
    expect(find.byType(Toolbar), findsOneWidget);
    expect(find.byType(HeaderMenuSettings), findsNothing);
  });

  group('HeaderMenuDevice', () {
    // Hosts the widget directly (not via the gallery) with the same DS
    // bootstrap as ComponentPreviewApp, so the tests don't also match the
    // playground's DSInput controls showing the same strings.
    Future<void> pumpDevice(WidgetTester tester, Widget menu) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              DSCoreUILocalizationDelegates.localizationsDelegates,
          supportedLocales: DSCoreUILocalizationDelegates.supportedLocales,
          builder: (context, child) => DSTheme(
            data: const DSThemeDataLight(),
            child: DSRegion(region: DSRegionDataDE.new, child: child!),
          ),
          home: menu,
        ),
      );
      await tester.pump();
    }

    const device = HeaderMenuConnectedDevice(
      name: 'Device name',
      wifiName: 'Wi-Fi Dentsply Sirona',
      batteryPercent: 35,
    );

    Finder battery() => find.byType(DSBatteryIndicator);
    Finder wifiIcon() => find.byWidgetPredicate(
      (w) => w is DSIcon && w.iconRef == DSIcons.wifiHigh,
    );
    Finder warningIcon() => find.byWidgetPredicate(
      (w) => w is DSIcon && w.iconRef == DSIcons.warning,
    );
    Finder deviceIcon() => find.byWidgetPredicate(
      (w) => w is DSIcon && w.iconRef == DSIcons.deviceDSPrimescanNeo,
    );

    testWidgets('no-device mode shortens its label per breakpoint and only '
        'fires onSelectScanner', (tester) async {
      var selected = 0;
      Widget menu(DSFormFactor f) =>
          HeaderMenuDevice(formFactor: f, onSelectScanner: () => selected++);

      await pumpDevice(tester, menu(DSFormFactor.large));
      expect(find.text('Select scanner'), findsOneWidget);
      expect(warningIcon(), findsOneWidget);

      await pumpDevice(tester, menu(DSFormFactor.medium));
      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('Select scanner'), findsNothing);

      await pumpDevice(tester, menu(DSFormFactor.small));
      expect(find.text('Scanner'), findsNothing);
      expect(find.text('Select scanner'), findsNothing);
      expect(warningIcon(), findsOneWidget);

      await tester.tap(find.byType(HeaderMenuDevice));
      await tester.pump(const Duration(milliseconds: 500));
      expect(selected, 1);
      // No panel in this mode.
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('connected mode shows name/wifi/battery per breakpoint', (
      tester,
    ) async {
      await pumpDevice(
        tester,
        const HeaderMenuDevice(device: device, formFactor: DSFormFactor.large),
      );
      expect(find.text('Device name'), findsOneWidget);
      expect(wifiIcon(), findsOneWidget);
      expect(battery(), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);

      await pumpDevice(
        tester,
        const HeaderMenuDevice(device: device, formFactor: DSFormFactor.medium),
      );
      expect(find.text('Device name'), findsNothing);
      expect(wifiIcon(), findsOneWidget);
      expect(battery(), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);

      await pumpDevice(
        tester,
        const HeaderMenuDevice(device: device, formFactor: DSFormFactor.small),
      );
      expect(find.text('Device name'), findsNothing);
      expect(wifiIcon(), findsOneWidget);
      // formFactor only overrides HeaderMenuDevice's own breakpoint choice;
      // DSBatteryIndicator reads the *real* DSFormFactor.of(context) (this
      // test's 1600px window, i.e. large) for its own percentage text, so
      // "35%" still renders here despite the small trigger layout.
      expect(battery(), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      expect(deviceIcon(), findsNothing);
    });

    testWidgets('wifi icon and battery indicator are each independently '
        'tied to whether the device has that data', (tester) async {
      const wifiOnly = HeaderMenuConnectedDevice(
        name: 'Device name',
        wifiName: 'Wi-Fi Dentsply Sirona',
      );
      const batteryOnly = HeaderMenuConnectedDevice(
        name: 'Device name',
        batteryPercent: 35,
      );
      const neither = HeaderMenuConnectedDevice(name: 'Device name');

      await pumpDevice(
        tester,
        const HeaderMenuDevice(
          device: wifiOnly,
          formFactor: DSFormFactor.large,
        ),
      );
      expect(wifiIcon(), findsOneWidget);
      expect(battery(), findsNothing);

      await pumpDevice(
        tester,
        const HeaderMenuDevice(
          device: batteryOnly,
          formFactor: DSFormFactor.large,
        ),
      );
      expect(wifiIcon(), findsNothing);
      expect(battery(), findsOneWidget);

      await pumpDevice(
        tester,
        const HeaderMenuDevice(device: neither, formFactor: DSFormFactor.large),
      );
      expect(wifiIcon(), findsNothing);
      expect(battery(), findsNothing);
      expect(find.text('Device name'), findsOneWidget);
      expect(deviceIcon(), findsOneWidget);
    });

    testWidgets(
      'device icon fallback shows at every breakpoint when neither wifi nor '
      'battery is present, alongside the name where visible',
      (tester) async {
        const neither = HeaderMenuConnectedDevice(name: 'Device name');

        for (final breakpoint in DSFormFactor.values) {
          await pumpDevice(
            tester,
            HeaderMenuDevice(device: neither, formFactor: breakpoint),
          );
          expect(wifiIcon(), findsNothing);
          expect(battery(), findsNothing);
          expect(deviceIcon(), findsOneWidget);
        }

        // Only shown when the device truly has neither Wi-Fi nor battery.
        await pumpDevice(
          tester,
          const HeaderMenuDevice(device: device, formFactor: DSFormFactor.small),
        );
        expect(deviceIcon(), findsNothing);
      },
    );

    testWidgets('badges render independently', (tester) async {
      await pumpDevice(tester, const HeaderMenuDevice(device: device));
      expect(find.byType(DSBadge), findsNothing);

      await pumpDevice(
        tester,
        const HeaderMenuDevice(
          device: device,
          hasNetworkAlert: true,
          hasCalibrationDue: true,
        ),
      );
      expect(find.byType(DSBadge), findsNWidgets(2));
      expect(find.bySemanticsLabel('Network alert'), findsOneWidget);
      expect(find.bySemanticsLabel('Calibration due'), findsOneWidget);
      expect(find.bySemanticsLabel('Battery alert'), findsNothing);
    });

    testWidgets('panel lists rows and warnings, and links close it before '
        'firing their callbacks', (tester) async {
      final actions = <String>[];
      await pumpDevice(
        tester,
        HeaderMenuDevice(
          device: device,
          hasMultipleDevices: true,
          networkWarningMessage: 'Weak signal.',
          batteryWarningMessage: 'Charge soon.',
          onTroubleshootNetwork: () => actions.add('troubleshoot'),
          onSwitchScanner: () => actions.add('switch'),
          onChangeDevice: () => actions.add('change'),
        ),
      );

      await tester.tap(find.byType(HeaderMenuDevice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Name'), findsOneWidget);
      // Trigger label + panel subtext.
      expect(find.text('Device name'), findsNWidgets(2));
      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('Wi-Fi Dentsply Sirona'), findsOneWidget);
      expect(find.text('Battery'), findsOneWidget);
      expect(find.text('35%'), findsNWidgets(2)); // trigger + panel
      expect(find.byType(DSInlineNotification), findsNWidgets(2));
      expect(find.text('Unstable connection'), findsOneWidget);
      expect(find.text('Low battery'), findsOneWidget);
      expect(find.text('Change device'), findsOneWidget);

      await tester.tap(find.text('Troubleshoot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(actions, ['troubleshoot']);
      expect(find.text('Name'), findsNothing);

      await tester.tap(find.byType(HeaderMenuDevice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Switch scanner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(HeaderMenuDevice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Change device'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(actions, ['troubleshoot', 'switch', 'change']);
    });

    testWidgets('panel omits optional rows', (tester) async {
      await pumpDevice(
        tester,
        const HeaderMenuDevice(
          device: HeaderMenuConnectedDevice(name: 'Device name'),
          networkWarningMessage: 'ignored without wifi',
        ),
      );
      expect(battery(), findsNothing);
      expect(wifiIcon(), findsNothing);

      await tester.tap(find.byType(HeaderMenuDevice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('WiFi'), findsNothing);
      expect(find.text('Battery'), findsNothing);
      expect(find.text('Change device'), findsNothing);
      expect(find.byType(DSInlineNotification), findsNothing);
    });
  });

  testWidgets("HeaderMenuHelp's popup lists About DI Scan, Give feedback and "
      'Show onboarding, in that order', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('HeaderMenuHelp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(HeaderMenuHelp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('About DI Scan'), findsOneWidget);
    expect(find.text('Give feedback'), findsOneWidget);
    expect(find.text('Show onboarding'), findsOneWidget);
  });

  testWidgets(
      "HeaderMenuHelp's Onboarding row shows Hide onboarding once the "
      "playground's Onboarding visible switch is toggled on",
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('HeaderMenuHelp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(DSSwitch));
    await tester.pump();

    await tester.tap(find.byType(HeaderMenuHelp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hide onboarding'), findsOneWidget);
    expect(find.text('Show onboarding'), findsNothing);
  });

  testWidgets(
      "Selecting HeaderMenuHelp's onboarding row toggles its own label "
      'between Show onboarding and Hide onboarding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('HeaderMenuHelp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(HeaderMenuHelp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Show onboarding'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(HeaderMenuHelp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hide onboarding'), findsOneWidget);
    expect(find.text('Show onboarding'), findsNothing);

    await tester.tap(find.text('Hide onboarding'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(HeaderMenuHelp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Show onboarding'), findsOneWidget);
    expect(find.text('Hide onboarding'), findsNothing);
  });

  testWidgets(
    'Toolbar playground renders both pills, toggles them and reports icon '
    'button actions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ComponentPreviewApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Toolbar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Everything below is scoped to the Toolbar itself, so the gallery's own
      // chrome (sidebar, section divider, control switches) can't be counted by
      // accident.
      Finder inToolbar(Finder matching) =>
          find.descendant(of: find.byType(Toolbar), matching: matching);

      // The Assistant pill is on by default, so both pills render six buttons
      // in total: three DSToggleButtons plus three plain icon buttons, which are
      // DSCrudeButtons too — as is each DSToggleButton internally, hence 6.
      expect(inToolbar(find.byType(DSToggleButton)), findsNWidgets(3));
      expect(inToolbar(find.byType(DSCrudeButton)), findsNWidgets(6));
      // The main pill's three groups are separated by two vertical dividers;
      // the single-group Assistant pill has none.
      expect(inToolbar(find.byType(DSDivider)), findsNWidgets(2));

      // Every button carries its design-definition tooltip message.
      for (final message in [
        'Assistant',
        'Cut scan',
        'Reset selected scan data',
        'Change appearance',
        'Toggle autorotation',
        'Toggle live view',
      ]) {
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == message,
          ),
          findsOneWidget,
          reason: 'expected a Tooltip with message "$message"',
        );
      }

      // Turning the "Assistant pill" switch off drops the Assistant pill, so
      // only the main pill and its two toggles remain.
      await tester.tap(find.text('Assistant pill'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(inToolbar(find.byType(DSToggleButton)), findsNWidgets(2));
      expect(inToolbar(find.byType(DSCrudeButton)), findsNWidgets(5));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Tooltip && widget.message == 'Assistant',
        ),
        findsNothing,
      );

      // The toggles are host-owned: the sidebar switches drive their selected
      // state straight through to DSToggleButton.selected. The tooltip message
      // is now on the wrapping Tooltip (see _ToolbarTooltip), not on
      // DSToggleButton.tooltip, so look up the DSToggleButton descendant of the
      // Tooltip carrying that message instead.
      DSToggleButton toggleWithTooltip(String message) => tester.widget(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == message,
          ),
          matching: find.byType(DSToggleButton),
        ),
      );

      expect(toggleWithTooltip('Toggle live view').selected, isFalse);
      await tester.tap(find.text('Video-View active'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(toggleWithTooltip('Toggle live view').selected, isTrue);

      expect(toggleWithTooltip('Toggle autorotation').selected, isFalse);
      await tester.tap(find.text('Autorotation active'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(toggleWithTooltip('Toggle autorotation').selected, isTrue);

      // The plain icon buttons fire their VoidCallback, which the playground
      // surfaces in its "last action" caption.
      expect(find.text('No action triggered yet'), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is Tooltip && widget.message == 'Cut scan',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Last action: Cut-Tool'), findsOneWidget);
      expect(find.text('No action triggered yet'), findsNothing);
    },
  );

  testWidgets(
    "ApplicationLoading playground's Loading-above-3-minutes and Timeout "
    'switches select mutually exclusive screens',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ComponentPreviewApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ApplicationLoading is selected by default, in its loading/countdown
      // state: no notification, timeline shown. 'Takes a few seconds'
      // matches both the Subline control's initial value and the preview's
      // own subline text.
      expect(find.text('Preparing scan...'), findsOneWidget);
      expect(find.text('Takes a few seconds'), findsNWidgets(2));
      expect(find.text('Setting up workspace…'), findsOneWidget);
      expect(find.text('Scan data'), findsOneWidget);
      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        find.text('Keep this screen open. Refreshing restarts loading.'),
        findsNothing,
      );

      // Turning "Loading above 3 minutes" on switches to the delayed screen:
      // fixed 2-line subline, info notification, no timeline.
      await tester.tap(find.text('Loading above 3 minutes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Preparing scan...'), findsOneWidget);
      expect(
        find.text(
          'Takes several minutes.\nThe delay is server-side, not on this '
          'device.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Keep this screen open. Refreshing restarts loading.'),
        findsOneWidget,
      );
      expect(find.text('Setting up workspace…'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);

      // Turning "Timeout" on switches to the timeout screen and — since the
      // two switches are mutually exclusive — turns "Loading above 3
      // minutes" back off.
      await tester.tap(find.text('Timeout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Preparing scan...'), findsNothing);
      expect(find.text("Couldn't prepare scan"), findsOneWidget);
      expect(
        find.text(
          'Takes several minutes.\nThe delay is server-side, not on this '
          'device.',
        ),
        findsNothing,
      );
      // The notification's message and "Try again" link are two TextSpans
      // inside one Text.rich, not separate Text widgets — findRichText is
      // needed to search inside it.
      expect(
        find.textContaining(
          'Server-side issue. Scan data remains safe.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Try again', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Setting up workspace…'), findsNothing);

      // Turning "Timeout" back off returns to the default loading screen.
      await tester.tap(find.text('Timeout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Preparing scan...'), findsOneWidget);
      expect(find.text('Setting up workspace…'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text("Couldn't prepare scan"), findsNothing);
    },
  );

  testWidgets(
    "ApplicationLoading's subline swaps text without animating height "
    'when the new text wraps to the same number of lines, but does '
    'animate height when the line count changes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ComponentPreviewApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final sublineFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_AnimatedSubline',
      );
      final initialHeight = tester.getSize(sublineFinder).height;

      // Same line count ("Takes a few seconds" -> "Ready in about 30
      // seconds", both one line): height must not move mid-transition.
      await tester.enterText(find.byType(DSInput), 'Ready in about 30 seconds');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.getSize(sublineFinder).height, closeTo(initialHeight, 0.5));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Ready in about 30 seconds'), findsNWidgets(2));
      expect(tester.getSize(sublineFinder).height, closeTo(initialHeight, 0.5));

      // A line-count change (one line -> several lines): height does move
      // mid-transition, settling on a taller box than the one-line height.
      await tester.enterText(
        find.byType(DSInput),
        'Ready in about this really rather unusually long stretch of extra '
        'time before the scan is likely to actually finish loading up',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      final midHeight = tester.getSize(sublineFinder).height;
      expect(midHeight, isNot(closeTo(initialHeight, 0.5)));
      await tester.pump(const Duration(milliseconds: 200));
      final finalHeight = tester.getSize(sublineFinder).height;
      expect(finalHeight, greaterThan(initialHeight));
    },
  );

  testWidgets('WorkflowAssistant playground switches variant and toggles its '
      'optional content slots', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('WorkflowAssistant'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('WorkflowAssistant'), findsNWidgets(2));
    expect(find.byType(WorkflowAssistant), findsOneWidget);

    // Everything below is scoped to the preview instance itself, so the
    // gallery's own chrome (sidebar, section heading, control inputs and
    // switches) can't be counted by accident — several of them happen to
    // show the exact same initial text as the preview (e.g. both the
    // Description input and the Button-label input default to text also
    // used inside the card).
    Finder inAssistant(Finder matching) =>
        find.descendant(of: find.byType(WorkflowAssistant), matching: matching);

    // All optional slots are on by default: description, media, the 4
    // bullets, the toggle and the button.
    expect(inAssistant(find.text('Description\nDescription')), findsOneWidget);
    expect(inAssistant(find.text('Media')), findsOneWidget);
    expect(inAssistant(find.text('Bullet')), findsNWidgets(4));
    expect(inAssistant(find.byType(DSSwitch)), findsOneWidget);
    expect(inAssistant(find.byType(DSButton)), findsNWidgets(2)); // + close

    // Switching to the Success variant swaps the indicator's icon color.
    // The Type dropdown's button shows the currently-selected item's own
    // title ('Default'); tapping it opens the popup listing both options.
    await tester.tap(find.text('Default'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The close button also renders its own DSIcon internally, so match on
    // iconRef rather than assuming there's only one DSIcon descendant.
    expect(
      inAssistant(
        find.byWidgetPredicate(
          (widget) => widget is DSIcon && widget.iconRef == DSIcons.check,
        ),
      ),
      findsOneWidget,
    );
    expect(
      inAssistant(
        find.byWidgetPredicate(
          (widget) => widget is DSIcon && widget.iconRef == DSIcons.activity,
        ),
      ),
      findsNothing,
    );

    // Turning each optional-slot switch off removes it from the preview.
    await tester.tap(find.text('Description'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(inAssistant(find.text('Description\nDescription')), findsNothing);

    // 'Media' matches both the preview's own placeholder text and the
    // Media switch's label; the switch (added to the tree after the
    // preview) is the last match.
    await tester.tap(find.text('Media').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(inAssistant(find.text('Media')), findsNothing);

    await tester.tap(find.text('Bullet list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(inAssistant(find.text('Bullet')), findsNothing);

    await tester.tap(find.text('Toggle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(inAssistant(find.byType(DSSwitch)), findsNothing);

    await tester.tap(find.text('Button'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.descendant(
        of: find.byType(WorkflowAssistant),
        matching: find.byType(DSButton),
      ),
      findsOneWidget, // only the always-visible close button remains
    );
  });

  testWidgets('Component gallery renders with the dark DS theme', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp(dark: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ComponentGalleryPage), findsOneWidget);
  });
}
