import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:di_scan/components/catalog_card/catalog_card.dart';
import 'package:di_scan/components/catalog_list/catalog_list.dart';
import 'package:di_scan/components/header_menus/header_menus.dart';
import 'package:di_scan/main.dart';

void main() {
  testWidgets('Component gallery renders all migrated components',
      (WidgetTester tester) async {
    // A viewport large enough to lay out the whole gallery without the
    // horizontal Row/Wrap sections overflowing.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComponentPreviewApp());
    // Not pumpAndSettle: the loading CatalogCard shows an indeterminate
    // DSProgressCircle, which never stops animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The three HeaderMenus variants.
    expect(find.byType(HeaderMenus), findsNWidgets(3));

    // Four standalone CatalogCards plus the three inside the CatalogList.
    expect(find.byType(CatalogList), findsOneWidget);
    expect(find.byType(CatalogCard), findsNWidgets(7));

    // The section headings.
    expect(find.text('HeaderMenus'), findsOneWidget);
    expect(find.text('CatalogCard'), findsOneWidget);
    expect(find.text('CatalogList'), findsOneWidget);
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
