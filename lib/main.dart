import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lightning_core_ui/lightning_core_ui.dart';

import 'components/application_loading/application_loading.dart';
import 'components/catalog_card/catalog_card.dart';
import 'components/catalog_list/catalog_list.dart';
import 'components/header_menu_help/header_menu_help.dart';
import 'components/header_menu_more/header_menu_more.dart';
import 'components/header_menu_settings/header_menu_settings.dart';
import 'components/toolbar/toolbar.dart';
import 'components/workflow_assistant/workflow_assistant.dart';

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
  const _ComponentEntry('HeaderMenuHelp', _HeaderMenuHelpPlayground()),
  const _ComponentEntry('HeaderMenuMore', _HeaderMenuMorePlayground()),
  const _ComponentEntry('HeaderMenuSettings', _HeaderMenuSettingsPlayground()),
  const _ComponentEntry('Toolbar', _ToolbarPlayground()),
  const _ComponentEntry('WorkflowAssistant', _WorkflowAssistantPlayground()),
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
  bool _scanModel = false;

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
      scanModel: _scanModel,
      scanModelImage: _scanModel
          ? ColoredBox(
              color: tokens.background.dimmer,
              child: Center(
                child: Text(
                  'Scan',
                  style: tokens.text.textSm.copyWith(color: tokens.text.subdued),
                ),
              ),
            )
          : null,
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
            DSSwitch(
              label: 'Scan model',
              value: _scanModel,
              onChanged: (value) => setState(() => _scanModel = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// Live, controls-driven preview of [CatalogList]: a dropdown selecting which
/// (if any) of the fixed demo items is selected.
///
/// Also simulates the host side of a drag-drop switch: on
/// [CatalogList.onSwitchRequested] both involved cards are marked as
/// [CatalogList.loadingIndices] for 2 s (demo only — no real data reorder).
class _CatalogListPlayground extends StatefulWidget {
  const _CatalogListPlayground();

  @override
  State<_CatalogListPlayground> createState() =>
      _CatalogListPlaygroundState();
}

class _CatalogListPlaygroundState extends State<_CatalogListPlayground> {
  static const _names = ['Upper jaw', 'Lower jaw', 'Bite'];
  static const _subtexts = [
    'Scanned 12 min ago',
    'Scanned 4 min ago',
    'Not scanned',
  ];

  /// Demo duration of the simulated switch operation.
  static const _switchDuration = Duration(seconds: 2);

  int? _selectedIndex = 1;
  bool _scanModel = false;
  Set<int> _loadingIndices = const {};
  Timer? _loadingTimer;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _simulateSwitch(int source, int target) {
    setState(() => _loadingIndices = {source, target});
    _loadingTimer?.cancel();
    _loadingTimer = Timer(_switchDuration, () {
      if (mounted) setState(() => _loadingIndices = const {});
    });
  }

  List<CatalogListItem> _buildItems(DSTokensData tokens) => [
        for (var i = 0; i < _names.length; i++)
          CatalogListItem(
            name: _names[i],
            subtext: _subtexts[i],
            showStatus: i == 1,
            scanModel: _scanModel,
            scanModelImage: _scanModel
                ? ColoredBox(
                    color: tokens.background.dimmer,
                    child: Center(
                      child: Text(
                        'Scan',
                        style: tokens.text.textSm
                            .copyWith(color: tokens.text.subdued),
                      ),
                    ),
                  )
                : null,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final items = _buildItems(tokens);

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
                items: items,
                loadingIndices: _loadingIndices,
                onSelectionChanged: (index) =>
                    setState(() => _selectedIndex = index),
                onSwitchRequested: _simulateSwitch,
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
                  for (var i = 0; i < items.length; i++)
                    DSDropdownItem(value: i, title: items[i].name),
                ],
                value: _selectedIndex,
                onChanged: (value) => setState(() => _selectedIndex = value),
              ),
            ),
            DSSwitch(
              label: 'Scan model',
              value: _scanModel,
              onChanged: (value) => setState(() => _scanModel = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// Live preview of [HeaderMenuHelp]: press the button to open its menu.
class _HeaderMenuHelpPlayground extends StatelessWidget {
  const _HeaderMenuHelpPlayground();

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.layout.l),
      child: _Section(
        title: 'HeaderMenuHelp',
        caption: 'Press the button to open its menu.',
        child: const Center(child: HeaderMenuHelp()),
      ),
    );
  }
}

/// Live preview of [HeaderMenuMore]: press the button to open its menu.
class _HeaderMenuMorePlayground extends StatelessWidget {
  const _HeaderMenuMorePlayground();

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.layout.l),
      child: _Section(
        title: 'HeaderMenuMore',
        caption: 'Press the button to open its menu.',
        child: const Center(child: HeaderMenuMore()),
      ),
    );
  }
}

/// Live, controls-driven preview of [HeaderMenuSettings]: press the button
/// to open its panel, then use the switches on the right to show/hide each
/// of the panel's four sections.
class _HeaderMenuSettingsPlayground extends StatefulWidget {
  const _HeaderMenuSettingsPlayground();

  @override
  State<_HeaderMenuSettingsPlayground> createState() =>
      _HeaderMenuSettingsPlaygroundState();
}

class _HeaderMenuSettingsPlaygroundState
    extends State<_HeaderMenuSettingsPlayground> {
  bool _showRenderStyle = true;
  bool _showSound = true;
  bool _showView = true;
  bool _showHolesDetection = true;

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
              title: 'HeaderMenuSettings',
              caption: 'Press the button to open its panel.',
              child: Center(
                child: HeaderMenuSettings(
                  showRenderStyle: _showRenderStyle,
                  showSound: _showSound,
                  showView: _showView,
                  showHolesDetection: _showHolesDetection,
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            DSSwitch(
              label: 'Render style section',
              value: _showRenderStyle,
              onChanged: (value) => setState(() => _showRenderStyle = value),
            ),
            DSSwitch(
              label: 'Sound section',
              value: _showSound,
              onChanged: (value) => setState(() => _showSound = value),
            ),
            DSSwitch(
              label: 'View section',
              value: _showView,
              onChanged: (value) => setState(() => _showView = value),
            ),
            DSSwitch(
              label: 'Holes detection section',
              value: _showHolesDetection,
              onChanged: (value) => setState(() => _showHolesDetection = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// Live, controls-driven preview of [Toolbar]: a switch for the optional
/// Assistant pill plus one switch per toggle button, since the toolbar's
/// toggles are host-owned rather than internally stateful.
///
/// The three plain icon buttons (Cut-Tool, Trash, Color-Mode) have no
/// parameters to drive, so instead of no-op callbacks they report into a
/// small "last action" caption under the preview — that is the only way to
/// see in the gallery that they actually fire.
class _ToolbarPlayground extends StatefulWidget {
  const _ToolbarPlayground();

  @override
  State<_ToolbarPlayground> createState() => _ToolbarPlaygroundState();
}

class _ToolbarPlaygroundState extends State<_ToolbarPlayground> {
  bool _assistant = true;
  bool _assistantActive = false;
  bool _autorotationActive = false;
  bool _videoViewActive = false;
  String? _lastAction;

  void _report(String action) => setState(() => _lastAction = action);

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);
    final lastAction = _lastAction;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'Toolbar',
              caption: 'A floating overlay normally pinned to the bottom '
                  'centre of the 3D viewport. Hover a button for its '
                  'tooltip; the toggles are driven from the right.',
              child: Column(
                children: [
                  Center(
                    child: Toolbar(
                      assistant: _assistant,
                      assistantActive: _assistantActive,
                      onAssistantPressed: () => setState(
                          () => _assistantActive = !_assistantActive),
                      onCutTool: () => _report('Cut-Tool'),
                      onTrash: () => _report('Trash'),
                      onColorMode: () => _report('Color-Mode'),
                      autorotationActive: _autorotationActive,
                      onAutorotationPressed: () => setState(
                          () => _autorotationActive = !_autorotationActive),
                      videoViewActive: _videoViewActive,
                      onVideoViewPressed: () => setState(
                          () => _videoViewActive = !_videoViewActive),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.layout.s),
                  Text(
                    lastAction == null
                        ? 'No action triggered yet'
                        : 'Last action: $lastAction',
                    style: tokens.text.textSm
                        .copyWith(color: tokens.text.subdued),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            DSSwitch(
              label: 'Assistant pill',
              value: _assistant,
              onChanged: (value) => setState(() => _assistant = value),
            ),
            DSSwitch(
              label: 'Assistant active',
              value: _assistantActive,
              onChanged: (value) => setState(() => _assistantActive = value),
            ),
            DSSwitch(
              label: 'Autorotation active',
              value: _autorotationActive,
              onChanged: (value) =>
                  setState(() => _autorotationActive = value),
            ),
            DSSwitch(
              label: 'Video-View active',
              value: _videoViewActive,
              onChanged: (value) => setState(() => _videoViewActive = value),
            ),
          ],
        ),
      ],
    );
  }
}

/// Live, controls-driven preview of [WorkflowAssistant]: text inputs for
/// title/description/bullets, switches for the variant and the optional
/// media/bullets/toggle/button slots, driving one instance of the card.
class _WorkflowAssistantPlayground extends StatefulWidget {
  const _WorkflowAssistantPlayground();

  @override
  State<_WorkflowAssistantPlayground> createState() =>
      _WorkflowAssistantPlaygroundState();
}

class _WorkflowAssistantPlaygroundState
    extends State<_WorkflowAssistantPlayground> {
  late final _titleController = TextEditingController(text: 'Title');
  late final _descriptionController =
      TextEditingController(text: 'Description\nDescription');
  late final _switchLabelController = TextEditingController(text: 'Label');
  late final _buttonLabelController = TextEditingController(text: 'Label');
  WorkflowAssistantVariant _variant = WorkflowAssistantVariant.standard;
  bool _showDescription = true;
  bool _showMedia = true;
  bool _showBullets = true;
  bool _showToggle = true;
  bool _showButton = true;
  bool _switchValue = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _switchLabelController.dispose();
    _buttonLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DSTokens.of(context);

    final preview = WorkflowAssistant(
      variant: _variant,
      title: _titleController.text,
      description: _showDescription ? _descriptionController.text : null,
      media: _showMedia
          ? ColoredBox(
              color: tokens.background.dimmer,
              child: Center(
                child: Text(
                  'Media',
                  style: tokens.text.textSm.copyWith(color: tokens.text.subdued),
                ),
              ),
            )
          : null,
      bullets: _showBullets
          ? const ['Bullet', 'Bullet', 'Bullet', 'Bullet']
          : const [],
      switchLabel: _showToggle ? _switchLabelController.text : null,
      switchValue: _switchValue,
      onSwitchChanged: (value) => setState(() => _switchValue = value),
      buttonLabel: _showButton ? _buttonLabelController.text : null,
      onButtonPressed: () {},
      onClose: () {},
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spacing.layout.l),
            child: _Section(
              title: 'WorkflowAssistant',
              caption: 'A floating panel opened from the Toolbar\'s '
                  'Assistant pill. Toggle its content slots on the right; '
                  'the close/button callbacks are no-ops here.',
              child: Center(child: preview),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        _ControlsPanel(
          children: [
            _ControlField(
              label: 'Type',
              child: DSDropdown<WorkflowAssistantVariant>(
                items: [
                  for (final variant in WorkflowAssistantVariant.values)
                    DSDropdownItem(
                      value: variant,
                      title: variant == WorkflowAssistantVariant.standard
                          ? 'Default'
                          : 'Success',
                    ),
                ],
                value: _variant,
                onChanged: (value) =>
                    setState(() => _variant = value ?? _variant),
              ),
            ),
            _ControlField(
              label: 'Title',
              child: DSInput(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            DSSwitch(
              label: 'Description',
              value: _showDescription,
              onChanged: (value) => setState(() => _showDescription = value),
            ),
            if (_showDescription)
              _ControlField(
                label: 'Description text',
                child: DSInput(
                  controller: _descriptionController,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            DSSwitch(
              label: 'Media',
              value: _showMedia,
              onChanged: (value) => setState(() => _showMedia = value),
            ),
            DSSwitch(
              label: 'Bullet list',
              value: _showBullets,
              onChanged: (value) => setState(() => _showBullets = value),
            ),
            DSSwitch(
              label: 'Toggle',
              value: _showToggle,
              onChanged: (value) => setState(() => _showToggle = value),
            ),
            if (_showToggle)
              _ControlField(
                label: 'Toggle label',
                child: DSInput(
                  controller: _switchLabelController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            DSSwitch(
              label: 'Button',
              value: _showButton,
              onChanged: (value) => setState(() => _showButton = value),
            ),
            if (_showButton)
              _ControlField(
                label: 'Button label',
                child: DSInput(
                  controller: _buttonLabelController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
