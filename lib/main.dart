import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'components/application_loading/application_loading.dart';
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

/// One entry in the component sidebar: a display name plus the playground
/// widget that renders that component's live, controls-driven preview.
class _ComponentEntry {
  const _ComponentEntry(this.name, this.playground);

  final String name;
  final Widget playground;
}

/// The components available in this gallery, ordered alphabetically by name
/// so the sidebar list order stays deterministic as components are added.
final List<_ComponentEntry> _componentEntries = [
  const _ComponentEntry('ApplicationLoading', _ApplicationLoadingPlayground()),
  const _ComponentEntry('CatalogCard', _CatalogCardPlayground()),
  const _ComponentEntry('CatalogList', _CatalogListPlayground()),
  const _ComponentEntry('HeaderMenus', _HeaderMenusPlayground()),
]..sort((a, b) => a.name.compareTo(b.name));

/// Shows one component at a time, selected from a sidebar listing every
/// component in the gallery. The first component (alphabetically) is
/// selected by default.
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final selected = _componentEntries[_selectedIndex];

    return Scaffold(
      backgroundColor: tokens.background.standard,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ComponentSidebar(
              entries: _componentEntries,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(tokens.spacing.layout.l),
                    child: Text(
                      'DI Scan Component Gallery',
                      style: tokens.text.headingXl
                          .copyWith(color: tokens.text.standard),
                    ),
                  ),
                  Expanded(
                    // Each entry's playground owns both the live preview
                    // (center) and the parameter controls (right sidebar) so
                    // the two stay in sync via one shared piece of state.
                    child: selected.playground,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The left-hand navigation listing every component in the gallery.
class _ComponentSidebar extends StatelessWidget {
  const _ComponentSidebar({
    required this.entries,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ComponentEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return SizedBox(
      width: 240,
      child: ColoredBox(
        color: tokens.background.dimmer,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.layout.s),
          children: [
            for (var i = 0; i < entries.length; i++)
              _ComponentSidebarItem(
                label: entries[i].name,
                selected: i == selectedIndex,
                onPressed: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComponentSidebarItem extends StatelessWidget {
  const _ComponentSidebarItem({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.component.xs,
        vertical: tokens.spacing.component.xxs,
      ),
      child: Material(
        color: selected ? tokens.surfaceSelected.standard : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.border.radius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.border.radius.small),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.component.m,
              vertical: tokens.spacing.component.s,
            ),
            child: Text(
              label,
              style: (selected
                      ? tokens.text.textBaseStrong
                      : tokens.text.textBase)
                  .copyWith(
                color: selected ? tokens.text.interactive : tokens.text.standard,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled block with an optional caption, used to introduce a component's
/// live preview area.
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

/// The fixed-width right-hand sidebar holding a component's live parameter
/// controls (text inputs, dropdowns, toggles, ...).
class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return SizedBox(
      width: 280,
      child: ColoredBox(
        color: tokens.background.dimmer,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spacing.layout.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Controls',
                style: tokens.text.headingBase
                    .copyWith(color: tokens.text.standard),
              ),
              SizedBox(height: tokens.spacing.layout.s),
              for (final child in children) ...[
                child,
                SizedBox(height: tokens.spacing.component.l),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single labeled control (text input, dropdown, ...) in a [_ControlsPanel].
class _ControlField extends StatelessWidget {
  const _ControlField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSLabel(label: label),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// Live, controls-driven preview of [ApplicationLoading]: an input for the
/// subline text and switches for the optional inline notification and the
/// timeline stepper card.
class _ApplicationLoadingPlayground extends StatefulWidget {
  const _ApplicationLoadingPlayground();

  @override
  State<_ApplicationLoadingPlayground> createState() =>
      _ApplicationLoadingPlaygroundState();
}

class _ApplicationLoadingPlaygroundState
    extends State<_ApplicationLoadingPlayground> {
  late final _sublineController =
      TextEditingController(text: 'This may take a few seconds');
  bool _notification = true;
  bool _timeline = true;

  @override
  void dispose() {
    _sublineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'ApplicationLoading',
              caption: 'A full loading screen (1600×1024 in Figma), so the '
                  'preview is given a fixed height here. Toggle its optional '
                  'blocks on the right.',
              // The component fills whatever box it is given; without an
              // explicit height it would try to grow unbounded inside this
              // scroll view.
              child: SizedBox(
                height: 900,
                child: ApplicationLoading(
                  subline: _sublineController.text,
                  notification: _notification,
                  timeline: _timeline,
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            _ControlField(
              label: 'Subline',
              child: DSInput(
                controller: _sublineController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            DSSwitch(
              label: 'Notification',
              value: _notification,
              onChanged: (value) => setState(() => _notification = value),
            ),
            DSSwitch(
              label: 'Timeline',
              value: _timeline,
              onChanged: (value) => setState(() => _timeline = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// The demo states offered by [CatalogCard]'s "State" dropdown, covering its
/// selected/disabled/loading variants.
enum _CatalogCardDemoState { default_, selected, disabled, loading }

extension on _CatalogCardDemoState {
  String get label => switch (this) {
        _CatalogCardDemoState.default_ => 'Default',
        _CatalogCardDemoState.selected => 'Selected',
        _CatalogCardDemoState.disabled => 'Disabled',
        _CatalogCardDemoState.loading => 'Loading',
      };
}

/// Live, controls-driven preview of [CatalogCard]: name/subtext text inputs,
/// a subtext visibility toggle, a state dropdown (default/selected/disabled/
/// loading), and a status-icon toggle.
class _CatalogCardPlayground extends StatefulWidget {
  const _CatalogCardPlayground();

  @override
  State<_CatalogCardPlayground> createState() =>
      _CatalogCardPlaygroundState();
}

class _CatalogCardPlaygroundState extends State<_CatalogCardPlayground> {
  late final _nameController = TextEditingController(text: 'Upper jaw');
  late final _subtextController =
      TextEditingController(text: 'Scanned 12 min ago');
  bool _showSubtext = true;
  _CatalogCardDemoState _state = _CatalogCardDemoState.default_;
  bool _showStatus = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    final preview = CatalogCard(
      name: _nameController.text,
      subtext: _subtextController.text,
      showSubtext: _showSubtext,
      selected: _state == _CatalogCardDemoState.selected,
      disabled: _state == _CatalogCardDemoState.disabled,
      isLoading: _state == _CatalogCardDemoState.loading,
      showStatus: _showStatus,
      onRemovePressed: () {},
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'CatalogCard',
              caption: 'Edit the parameters on the right to update the '
                  'preview live.',
              child: Center(child: preview),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            _ControlField(
              label: 'Name',
              child: DSInput(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            _ControlField(
              label: 'Subtext',
              child: DSInput(
                controller: _subtextController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            DSSwitch(
              label: 'Show subtext',
              value: _showSubtext,
              onChanged: (value) => setState(() => _showSubtext = value),
            ),
            _ControlField(
              label: 'State',
              child: DSDropdown<_CatalogCardDemoState>(
                items: [
                  for (final state in _CatalogCardDemoState.values)
                    DSDropdownItem(value: state, title: state.label),
                ],
                value: _state,
                onChanged: (value) =>
                    setState(() => _state = value ?? _state),
              ),
            ),
            DSSwitch(
              label: 'Show status icon',
              value: _showStatus,
              onChanged: (value) => setState(() => _showStatus = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// Live, controls-driven preview of [CatalogList]: a dropdown selecting which
/// (if any) of the fixed demo items is selected.
class _CatalogListPlayground extends StatefulWidget {
  const _CatalogListPlayground();

  @override
  State<_CatalogListPlayground> createState() =>
      _CatalogListPlaygroundState();
}

class _CatalogListPlaygroundState extends State<_CatalogListPlayground> {
  static const _items = [
    CatalogListItem(name: 'Upper jaw', subtext: 'Scanned 12 min ago'),
    CatalogListItem(
      name: 'Lower jaw',
      subtext: 'Scanned 4 min ago',
      showStatus: true,
    ),
    CatalogListItem(name: 'Bite', subtext: 'Not scanned'),
  ];

  int? _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'CatalogList',
              caption: 'Long-press a card to drag it onto another one. '
                  'Choose the selected card on the right.',
              child: CatalogList(
                selectedIndex: _selectedIndex,
                items: _items,
                onSelectionChanged: (index) =>
                    setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            _ControlField(
              label: 'Selected',
              child: DSDropdown<int?>(
                items: [
                  DSDropdownItem(value: null, title: 'None'),
                  for (var i = 0; i < _items.length; i++)
                    DSDropdownItem(value: i, title: _items[i].name),
                ],
                value: _selectedIndex,
                onChanged: (value) => setState(() => _selectedIndex = value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The three named-constructor variants offered by [HeaderMenus]'s "Type"
/// dropdown.
enum _HeaderMenusDemoType { more, help, settings }

extension on _HeaderMenusDemoType {
  String get label => switch (this) {
        _HeaderMenusDemoType.more => 'More',
        _HeaderMenusDemoType.help => 'Help',
        _HeaderMenusDemoType.settings => 'Settings',
      };
}

/// Live, controls-driven preview of [HeaderMenus]: a dropdown selecting which
/// of the three named-constructor variants (more/help/settings) to render.
class _HeaderMenusPlayground extends StatefulWidget {
  const _HeaderMenusPlayground();

  @override
  State<_HeaderMenusPlayground> createState() =>
      _HeaderMenusPlaygroundState();
}

class _HeaderMenusPlaygroundState extends State<_HeaderMenusPlayground> {
  _HeaderMenusDemoType _type = _HeaderMenusDemoType.more;

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    final preview = switch (_type) {
      _HeaderMenusDemoType.more => const HeaderMenus.more(),
      _HeaderMenusDemoType.help => const HeaderMenus.help(),
      _HeaderMenusDemoType.settings => const HeaderMenus.settings(),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'HeaderMenus',
              caption: 'Press the button to open its menu. Choose the '
                  'variant on the right.',
              child: Center(child: preview),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            _ControlField(
              label: 'Type',
              child: DSDropdown<_HeaderMenusDemoType>(
                items: [
                  for (final type in _HeaderMenusDemoType.values)
                    DSDropdownItem(value: type, title: type.label),
                ],
                value: _type,
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
