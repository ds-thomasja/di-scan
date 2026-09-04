import 'dart:ui' show Size;

import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter_test/flutter_test.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'package:di_scan/components/application_loading/application_loading.dart';
import 'package:di_scan/components/catalog_card/catalog_card.dart';
import 'package:di_scan/components/catalog_list/catalog_list.dart';
import 'package:di_scan/components/header_menus/header_menus.dart';
import 'package:di_scan/components/toolbar/toolbar.dart';
import 'package:di_scan/main.dart';

void main() {
  testWidgets(
      'Component gallery shows one live, controls-driven component at a '
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
    expect(find.text('HeaderMenus'), findsOneWidget);
    expect(find.text('Toolbar'), findsOneWidget);

    // ApplicationLoading is first alphabetically, so it's selected by default:
    // its label appears both in the sidebar and as the content heading.
    expect(find.text('ApplicationLoading'), findsNWidgets(2));
    expect(find.byType(ApplicationLoading), findsOneWidget);
    expect(find.byType(CatalogCard), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(HeaderMenus), findsNothing);
    expect(find.byType(Toolbar), findsNothing);

    // Selecting CatalogCard in the sidebar swaps the main content.
    await tester.tap(find.text('CatalogCard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CatalogCard'), findsNWidgets(2));
    expect(find.byType(CatalogCard), findsOneWidget);
    expect(find.byType(ApplicationLoading), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(HeaderMenus), findsNothing);

    // Selecting CatalogList in the sidebar swaps the main content.
    await tester.tap(find.text('CatalogList'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CatalogList'), findsNWidgets(2));
    expect(find.byType(CatalogList), findsOneWidget);
    expect(find.byType(CatalogCard), findsNWidgets(3)); // inside CatalogList
    expect(find.byType(HeaderMenus), findsNothing);

    // Selecting HeaderMenus in the sidebar swaps the main content again.
    // It defaults to the "More" variant, driven by the Type dropdown.
    await tester.tap(find.text('HeaderMenus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenus'), findsNWidgets(2));
    expect(find.byType(HeaderMenus), findsOneWidget);
    expect(find.byType(CatalogCard), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
    expect(find.byType(Toolbar), findsNothing);

    // Selecting Toolbar in the sidebar swaps the main content again.
    await tester.tap(find.text('Toolbar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Toolbar'), findsNWidgets(2));
    expect(find.byType(Toolbar), findsOneWidget);
    expect(find.byType(HeaderMenus), findsNothing);
  });

  testWidgets(
      'Toolbar playground renders both pills, toggles them and reports icon '
      'button actions', (WidgetTester tester) async {
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
            (widget) => widget is Tooltip && widget.message == message),
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
          (widget) => widget is Tooltip && widget.message == 'Assistant'),
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
                (widget) => widget is Tooltip && widget.message == message),
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

    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Cut scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Last action: Cut-Tool'), findsOneWidget);
    expect(find.text('No action triggered yet'), findsNothing);
  });

  testWidgets(
      'ApplicationLoading playground toggles the notification and timeline '
      'blocks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // ApplicationLoading is selected by default, with both optional blocks on.
    // 'This may take a few seconds' matches both the Subline control's
    // initial value and the preview's own subline text.
    expect(find.text('Loading scan...'), findsOneWidget);
    expect(find.text('This may take a few seconds'), findsNWidgets(2));
    expect(find.text('Taking a little longer than usual'), findsOneWidget);
    expect(find.text('Preparing workspace…'), findsOneWidget);
    expect(find.text('Fetch scan data'), findsOneWidget);
    expect(find.text('Start application'), findsOneWidget);
    expect(find.text('Cancel loading'), findsOneWidget);

    // Turning the "Notification" switch off hides the inline notification but
    // keeps the timeline stepper.
    await tester.tap(find.text('Notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Taking a little longer than usual'), findsNothing);
    expect(find.text('Preparing workspace…'), findsOneWidget);

    // Turning the "Timeline" switch off hides the stepper card as well.
    await tester.tap(find.text('Timeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Preparing workspace…'), findsNothing);
    expect(find.text('Fetch scan data'), findsNothing);
    expect(find.text('Start application'), findsNothing);

    // The heading, subtext and cancel button are always present.
    expect(find.text('Loading scan...'), findsOneWidget);
    expect(find.text('Cancel loading'), findsOneWidget);
  });

  testWidgets(
      "ApplicationLoading's subline swaps text without animating height "
      'when the new text wraps to the same number of lines, but does '
      'animate height when the line count changes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final sublineFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_AnimatedSubline');
    final initialHeight = tester.getSize(sublineFinder).height;

    // Same line count ("This may take a few seconds" -> "Ready in about 30
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
  });

  testWidgets('Component gallery renders with the dark DS theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp(dark: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ComponentGalleryPage), findsOneWidget);
  });
}
