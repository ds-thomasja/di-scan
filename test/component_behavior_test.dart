import 'dart:ui' show PointerDeviceKind, Size;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'package:di_scan/components/catalog_card/catalog_card.dart';
import 'package:di_scan/components/catalog_list/catalog_list.dart';
import 'package:di_scan/components/header_menu_settings/header_menu_settings.dart';
import 'package:di_scan/components/toolbar/toolbar.dart';
import 'package:di_scan/components/workflow_assistant/workflow_assistant.dart';
import 'package:di_scan/main.dart';

/// Pumps [child] inside the same DS ancestors the gallery app uses
/// (localizations, [DSTheme], [DSRegion]) at a [width]×900 logical-px window.
Future<void> _pumpDS(
  WidgetTester tester,
  Widget child, {
  double width = 1600,
}) async {
  tester.view.physicalSize = Size(width, 900);
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
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('HeaderMenuSettings', () {
    DSSwitch switchLabeled(WidgetTester tester, String label) => tester.widget(
      find.byWidgetPredicate((w) => w is DSSwitch && w.label == label),
    );

    DSRadio<SeatPosition> radioLabeled(WidgetTester tester, String label) =>
        tester.widget(
          find.byWidgetPredicate(
            (w) => w is DSRadio<SeatPosition> && w.label == label,
          ),
        );

    testWidgets('keeps changed values after closing and reopening the panel', (
      tester,
    ) async {
      await _pumpDS(tester, const HeaderMenuSettings());

      await tester.tap(find.byType(HeaderMenuSettings));
      await _settle(tester);

      // Typo fixed: the label reads "Autorotation".
      expect(find.text('Autotoration'), findsNothing);
      expect(switchLabeled(tester, 'Autorotation').value, isTrue);
      expect(
        radioLabeled(tester, 'Always behind').groupValue,
        SeatPosition.facingForLowerBehindForUpper,
      );

      await tester.tap(find.text('Autorotation'));
      await tester.tap(find.text('Always behind'));
      await _settle(tester);
      expect(switchLabeled(tester, 'Autorotation').value, isFalse);
      expect(
        radioLabeled(tester, 'Always behind').groupValue,
        SeatPosition.alwaysBehind,
      );

      // Close via Escape (modal popup dismiss) and verify it is gone.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.text('Autorotation'), findsNothing);

      // Reopen: the changed values are still there.
      await tester.tap(find.byType(HeaderMenuSettings));
      await _settle(tester);
      expect(switchLabeled(tester, 'Autorotation').value, isFalse);
      expect(
        radioLabeled(tester, 'Always behind').groupValue,
        SeatPosition.alwaysBehind,
      );
    });
  });

  group('CatalogCard', () {
    testWidgets('Enter and Space on the focused card toggle selection', (
      tester,
    ) async {
      final changes = <bool>[];
      await _pumpDS(tester, CatalogCard(onSelectedChanged: changes.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(changes, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);
      expect(changes, [true, false]);
    });

    testWidgets('disabled card ignores keyboard activation', (tester) async {
      final changes = <bool>[];
      await _pumpDS(
        tester,
        CatalogCard(disabled: true, onSelectedChanged: changes.add),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(changes, isEmpty);
    });

    testWidgets('exposes button + selected semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDS(
        tester,
        const CatalogCard(name: 'Upper jaw', selected: true),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Upper jaw'))),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    for (final width in [600.0, 1600.0]) {
      testWidgets(
        'compact card is 96 px high at a ${width.toInt()} px window',
        (tester) async {
          await _pumpDS(tester, const CatalogCard(), width: width);
          expect(tester.getSize(find.byType(CatalogCard)), const Size(288, 96));
        },
      );
    }

    testWidgets(
      'tapping or holding the ⋮ actions button neither toggles selection '
      'nor press-scales the card',
      (tester) async {
        final changes = <bool>[];
        await _pumpDS(
          tester,
          CatalogCard(
            selected: true,
            onRemovePressed: () {},
            onSelectedChanged: changes.add,
          ),
        );

        double cardScale() =>
            tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

        // Touch press-and-hold past the tap-down deadline (no hover on touch).
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(DSActionsButton)),
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(cardScale(), 1.0);
        await gesture.up();
        await _settle(tester);
        expect(changes, isEmpty);

        // Dismiss the actions menu the tap opened, then a plain tap.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _settle(tester);
        await tester.tap(find.byType(DSActionsButton));
        await _settle(tester);
        expect(changes, isEmpty);
      },
    );

    testWidgets('holding the card body still press-scales it', (tester) async {
      await _pumpDS(tester, const CatalogCard());
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CatalogCard)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.97,
      );
      await gesture.up();
      await _settle(tester);
    });
  });

  group('CatalogList', () {
    const items = [
      CatalogListItem(name: 'Upper jaw', subtext: 'a', showStatus: true),
      CatalogListItem(name: 'Lower jaw', subtext: 'b', showStatus: true),
      CatalogListItem(name: 'Bite', subtext: 'c'),
    ];

    testWidgets(
      'long-press dragging a card onto another reports onSwitchRequested',
      (tester) async {
        final requests = <(int, int)>[];
        await _pumpDS(
          tester,
          CatalogList(
            items: items,
            onSwitchRequested: (s, t) => requests.add((s, t)),
          ),
        );

        final cards = find.byType(CatalogCard);
        final source = tester.getCenter(cards.at(0));
        final target = tester.getCenter(cards.at(2));

        final gesture = await tester.startGesture(source);
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await gesture.moveTo(target);
        await tester.pump();

        // Floating copy is a 4th CatalogCard (compact, no status check).
        final copy = find.byType(CatalogCard).last;
        expect(find.byType(CatalogCard), findsNWidgets(4));
        expect(tester.getSize(copy), const Size(288, 96));
        expect(
          find.descendant(
            of: copy,
            matching: find.byWidgetPredicate(
              (w) => w is DSIcon && w.iconRef == DSIcons.checkCircleFilled,
            ),
          ),
          findsNothing,
        );
        // Source/target flags are set on the right cards.
        expect(tester.widget<CatalogCard>(cards.at(0)).isDragSource, isTrue);
        expect(tester.widget<CatalogCard>(cards.at(2)).isDragTarget, isTrue);

        await gesture.up();
        await _settle(tester);

        expect(requests, [(0, 2)]);
        expect(find.byType(CatalogCard), findsNWidgets(3));
        // The list does not simulate loading itself any more.
        expect(find.byType(DSProgressCircle), findsNothing);
      },
    );

    testWidgets('host-owned loadingIndices show spinners and block drags', (
      tester,
    ) async {
      final requests = <(int, int)>[];
      await _pumpDS(
        tester,
        CatalogList(
          items: items,
          loadingIndices: const {1},
          onSwitchRequested: (s, t) => requests.add((s, t)),
        ),
      );

      expect(find.byType(DSProgressCircle), findsOneWidget);

      final cards = find.byType(CatalogCard);
      final gesture = await tester.startGesture(tester.getCenter(cards.at(1)));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(cards.at(2)));
      await tester.pump();
      expect(find.byType(CatalogCard), findsNWidgets(3)); // no drag copy
      await gesture.up();
      await _settle(tester);
      expect(requests, isEmpty);
    });
  });

  testWidgets('CatalogList playground simulates a 2 s switch after a drop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    await _settle(tester);
    await tester.tap(find.text('CatalogList'));
    await _settle(tester);

    final cards = find.byType(CatalogCard);
    final gesture = await tester.startGesture(tester.getCenter(cards.at(0)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(cards.at(2)));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byType(DSProgressCircle), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(DSProgressCircle), findsNothing);
  });

  group('WorkflowAssistant', () {
    for (final width in [600.0, 1600.0]) {
      testWidgets('slot gaps are fixed at a ${width.toInt()} px window', (
        tester,
      ) async {
        await _pumpDS(
          tester,
          WorkflowAssistant(
            title: 'Title',
            description: 'Description',
            bullets: const ['Bullet'],
            switchLabel: 'Toggle',
            buttonLabel: 'Button',
            onClose: () {},
          ),
          width: width,
        );
        final top = tester.getTopLeft(find.byType(WorkflowAssistant)).dy;
        // Indicator 32 + 16 gap → title starts 24 (padding) + 48 below top.
        expect(tester.getTopLeft(find.text('Title')).dy - top, 24 + 32 + 16);
        // Bullet → switch gap is 24 px (component.l).
        final bulletBottom = tester.getBottomLeft(find.text('Bullet')).dy;
        final switchTop = tester.getTopLeft(find.byType(DSSwitch)).dy;
        expect(switchTop - bulletBottom, 24);
      });
    }
  });

  group('Toolbar', () {
    testWidgets('announces each button exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpDS(
        tester,
        Toolbar(
          onAssistantPressed: () {},
          onCutTool: () {},
          onTrash: () {},
          onColorMode: () {},
          onAutorotationPressed: () {},
          onVideoViewPressed: () {},
        ),
      );
      for (final label in [
        'Workflow Assistant',
        'Cut Tool',
        'Delete scan',
        'Color Mode',
        'Autorotation',
        'Video View',
      ]) {
        expect(
          find.bySemanticsLabel(RegExp('^$label\$|^$label\n')),
          findsOneWidget,
          reason: 'expected a single semantics node for "$label"',
        );
      }
      handle.dispose();
    });
  });
}
