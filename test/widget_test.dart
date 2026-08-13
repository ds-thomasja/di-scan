import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:di_scan/components/catalog_card/catalog_card.dart';
import 'package:di_scan/components/catalog_list/catalog_list.dart';
import 'package:di_scan/components/header_menus/header_menus.dart';
import 'package:di_scan/main.dart';

void main() {
  testWidgets(
      'Component gallery shows one component at a time via the sidebar',
      (WidgetTester tester) async {
    // A viewport large enough to lay out the sidebar plus content without
    // the horizontal Row/Wrap sections overflowing.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    // Not pumpAndSettle: the loading CatalogCard shows an indeterminate
    // DSProgressCircle, which never stops animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The sidebar lists every component, alphabetically.
    expect(find.text('CatalogList'), findsOneWidget);
    expect(find.text('HeaderMenus'), findsOneWidget);

    // CatalogCard is first alphabetically, so it's selected by default: its
    // label appears both in the sidebar and as the content heading.
    expect(find.text('CatalogCard'), findsNWidgets(2));
    expect(find.byType(CatalogCard), findsNWidgets(4));
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
    await tester.tap(find.text('HeaderMenus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HeaderMenus'), findsNWidgets(2));
    expect(find.byType(HeaderMenus), findsNWidgets(3));
    expect(find.byType(CatalogCard), findsNothing);
    expect(find.byType(CatalogList), findsNothing);
  });

  testWidgets('Component gallery renders with the dark DS theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp(dark: true));
    // Not pumpAndSettle: the loading CatalogCard shows an indeterminate
    // DSProgressCircle, which never stops animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ComponentGalleryPage), findsOneWidget);
  });
}
