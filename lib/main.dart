import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'components/catalog_card/catalog_card.dart';
import 'components/catalog_list/catalog_list.dart';
import 'components/header_menus/header_menus.dart';

void main() {
  runApp(const ComponentPreviewApp());
}

/// Local preview harness for the DI Scan components.
///
/// The components are built on the DS Design System, so they need three
/// ancestors to work:
/// - the DS localization delegates (DS widgets resolve their own strings),
/// - [DSTheme], which provides both the legacy `DSThemeData` and the design
///   tokens (`DSTokensData`) that the components read via `DSTokens.of`,
/// - [DSRegion], which provides region-specific number/date formatting.
///
/// [DSTheme] needs a [MediaQuery] ancestor (for the form-factor-dependent
/// tokens), which is why it is installed through [MaterialApp.builder] rather
/// than above [MaterialApp].
class ComponentPreviewApp extends StatelessWidget {
  const ComponentPreviewApp({super.key, this.dark = false});

  /// Renders the gallery with the dark DS theme instead of the light one.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DI Scan Component Preview',
      debugShowCheckedModeBanner: false,
      // Includes the DS delegate plus the global Material/Cupertino/Widgets
      // delegates that DS widgets rely on (e.g. for DateFormat strings).
      localizationsDelegates: DSCoreUILocalizationDelegates.localizationsDelegates,
      supportedLocales: DSCoreUILocalizationDelegates.supportedLocales,
      builder: (context, child) => DSTheme(
        data: dark ? const DSThemeDataDark() : const DSThemeDataLight(),
        child: DSRegion(
          region: DSRegionDataDE.new,
          child: child!,
        ),
      ),
      home: const ComponentGalleryPage(),
    );
  }
}

/// Renders every migrated component in a few representative states so they can
/// be verified visually in the browser.
class ComponentGalleryPage extends StatelessWidget {
  const ComponentGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.background.standard,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacing.layout.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DI Scan Component Gallery',
                style: tokens.text.headingXl.copyWith(color: tokens.text.standard),
              ),
              SizedBox(height: tokens.spacing.layout.l),
              const _HeaderMenusSection(),
              SizedBox(height: tokens.spacing.layout.xl),
              const _CatalogCardSection(),
              SizedBox(height: tokens.spacing.layout.xl),
              const _CatalogListSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled block with an optional caption, used to group gallery examples.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.caption, required this.child});

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final caption = this.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tokens.text.headingBase.copyWith(color: tokens.text.standard),
        ),
        if (caption != null) ...[
          SizedBox(height: tokens.spacing.component.xxs),
          Text(
            caption,
            style: tokens.text.textSm.copyWith(color: tokens.text.subdued),
          ),
        ],
        SizedBox(height: tokens.spacing.component.m),
        const DSDivider.horizontal(),
        SizedBox(height: tokens.spacing.layout.s),
        child,
      ],
    );
  }
}

/// A single example with a label underneath it.
class _Example extends StatelessWidget {
  const _Example({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        SizedBox(height: tokens.spacing.component.xs),
        Text(
          label,
          style: tokens.text.textSm.copyWith(color: tokens.text.subdued),
        ),
      ],
    );
  }
}

class _HeaderMenusSection extends StatelessWidget {
  const _HeaderMenusSection();

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return _Section(
      title: 'HeaderMenus',
      caption: 'The three named-constructor variants. Press a button to open '
          'its menu.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Example(
            label: '.more',
            child: HeaderMenus.more(),
          ),
          SizedBox(width: tokens.spacing.layout.m),
          const _Example(
            label: '.help',
            child: HeaderMenus.help(),
          ),
          SizedBox(width: tokens.spacing.layout.m),
          const _Example(
            label: '.settings',
            child: HeaderMenus.settings(),
          ),
        ],
      ),
    );
  }
}

class _CatalogCardSection extends StatelessWidget {
  const _CatalogCardSection();

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return _Section(
      title: 'CatalogCard',
      caption: 'Tapping a card toggles between the compact and expanded '
          'layout.',
      child: Wrap(
        spacing: tokens.spacing.layout.m,
        runSpacing: tokens.spacing.layout.m,
        children: [
          _Example(
            label: 'not selected',
            child: CatalogCard(
              name: 'Upper jaw',
              subtext: 'Scanned 12 min ago',
              onRemovePressed: () {},
            ),
          ),
          _Example(
            label: 'selected (expanded)',
            child: CatalogCard(
              name: 'Lower jaw',
              subtext: 'Scanned 4 min ago',
              selected: true,
              showStatus: true,
              onRemovePressed: () {},
            ),
          ),
          const _Example(
            label: 'disabled',
            child: CatalogCard(
              name: 'Bite',
              subtext: 'Not scanned',
              disabled: true,
            ),
          ),
          const _Example(
            label: 'loading',
            child: CatalogCard(
              name: 'Switching…',
              showSubtext: false,
              isLoading: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogListSection extends StatelessWidget {
  const _CatalogListSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: 'CatalogList',
      caption: 'Single-selection list. Long-press a card to drag it onto '
          'another one.',
      child: CatalogList(
        selectedIndex: 1,
        items: [
          CatalogListItem(name: 'Upper jaw', subtext: 'Scanned 12 min ago'),
          CatalogListItem(
            name: 'Lower jaw',
            subtext: 'Scanned 4 min ago',
            showStatus: true,
          ),
          CatalogListItem(name: 'Bite', subtext: 'Not scanned'),
        ],
      ),
    );
  }
}
