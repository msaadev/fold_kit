import 'package:flutter/material.dart';

import 'fold_kit_scope.dart';

/// An app bar action that can live in a horizontal app bar or a vertical bar.
class FoldAction {
  /// Icon, always shown.
  final IconData icon;

  /// Label: the tooltip, the screen reader text, and the text in the overflow menu.
  final String label;

  /// Called on tap.
  final VoidCallback? onPressed;

  /// Main action of the page (Done, Save); placed first and kept out of the overflow menu.
  final bool prominent;

  /// Higher stays visible longer when the vertical bar runs out of space.
  final int priority;

  /// Creates an action.
  const FoldAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
    this.priority = 0,
  });
}

/// A tab of a [FoldScaffold].
class FoldDestination {
  /// Icon of the tab.
  final IconData icon;

  /// Icon when selected; defaults to [icon].
  final IconData? selectedIcon;

  /// Label of the tab.
  final String label;

  /// Creates a tab.
  const FoldDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
}

/// Where the app bar and the tabs go.
enum FoldBarPlacement {
  /// iPhone Duo rule: vertical bar on the outer display and on the inner display
  /// in landscape; otherwise vertical only on wide landscape windows (tablets).
  auto,

  /// Always a top app bar and bottom tabs.
  bottom,

  /// Always one vertical bar on the trailing edge.
  trailing,
}

/// What leaves the vertical bar first when it is too short.
enum FoldBarCompression {
  /// Actions go into the overflow menu before tabs.
  actionsFirst,

  /// Tabs go into the overflow menu before actions.
  tabsFirst,
}

/// A scaffold whose app bar and tabs move into one vertical bar on the right
/// edge where the system does that for native apps (iPhone Duo outer display,
/// inner display in landscape) — and stay a normal app bar + navigation bar
/// everywhere else. The body keeps its state when the bars move.
class FoldScaffold extends StatefulWidget {
  /// Page title.
  final Widget? title;

  /// Back or close button; defaults to a back button when the route can pop.
  final Widget? leading;

  /// App bar actions.
  final List<FoldAction> actions;

  /// Tabs; empty means no tab bar.
  final List<FoldDestination> destinations;

  /// The selected tab.
  final int selectedIndex;

  /// Called when a tab is tapped.
  final ValueChanged<int>? onDestinationSelected;

  /// Page content.
  final Widget body;

  /// Where the bars go; see [FoldBarPlacement].
  final FoldBarPlacement placement;

  /// What leaves the vertical bar first when it is too short.
  final FoldBarCompression compression;

  /// Floating action button, passed to the inner [Scaffold].
  final Widget? floatingActionButton;

  /// Creates the scaffold.
  const FoldScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions = const [],
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.placement = FoldBarPlacement.auto,
    this.compression = FoldBarCompression.actionsFirst,
    this.floatingActionButton,
  });

  /// Whether the bars are vertical for this window.
  static bool isVertical(BuildContext context, FoldBarPlacement placement) {
    switch (placement) {
      case FoldBarPlacement.bottom:
        return false;
      case FoldBarPlacement.trailing:
        return true;
      case FoldBarPlacement.auto:
        final size = MediaQuery.sizeOf(context);
        final landscape = size.width > size.height;
        return switch (FoldKitScope.statusOf(context)) {
          HingeStatus.closed => true,
          HingeStatus.partiallyOpen || HingeStatus.fullyOpen => landscape,
          HingeStatus.unknown => landscape && size.width >= 840,
        };
    }
  }

  @override
  State<FoldScaffold> createState() => _FoldScaffoldState();
}

class _FoldScaffoldState extends State<FoldScaffold> {
  final _bodyKey = GlobalKey();

  static const double _barWidth = 80;
  static const double _itemExtent = 64;

  @override
  Widget build(BuildContext context) {
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    if (!FoldScaffold.isVertical(context, widget.placement)) {
      return _buildHorizontal(context, body);
    }
    return _buildVertical(context, body);
  }

  Widget _buildHorizontal(BuildContext context, Widget body) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.leading,
        title: widget.title,
        actions: [
          for (final action in _orderedActions)
            IconButton(
              icon: Icon(action.icon),
              tooltip: action.label,
              onPressed: action.onPressed,
            ),
        ],
      ),
      body: body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.destinations.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              destinations: [
                for (final d in widget.destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon ?? d.icon),
                    label: d.label,
                  ),
              ],
            ),
    );
  }

  Widget _buildVertical(BuildContext context, Widget body) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          Expanded(
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: DefaultTextStyle(
                        style: textTheme.titleLarge!,
                        child: widget.title!,
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
          _buildBar(context),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        left: false,
        child: SizedBox(
          width: _barWidth,
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: _buildBarItems(context, constraints.maxHeight),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBarItems(BuildContext context, double height) {
    final leading =
        widget.leading ??
        (ModalRoute.of(context)?.canPop ?? false ? const BackButton() : null);
    final capacity = (height / _itemExtent).floor() - (leading == null ? 0 : 1);
    final actions = _orderedActions;
    final tabs = [for (var i = 0; i < widget.destinations.length; i++) i];
    final shownActions = [...actions];
    final shownTabs = [...tabs];
    final hiddenActions = <FoldAction>[];
    final hiddenTabs = <int>[];
    var needsMenu = false;
    while (shownActions.length + shownTabs.length + (needsMenu ? 1 : 0) >
        capacity) {
      needsMenu = true;
      final droppableAction = shownActions.lastWhereOrNull((a) => !a.prominent);
      final droppableTab = shownTabs.lastWhereOrNull(
        (i) => i != widget.selectedIndex,
      );
      final preferAction =
          widget.compression == FoldBarCompression.actionsFirst ||
          droppableTab == null;
      if (droppableAction != null && preferAction) {
        shownActions.remove(droppableAction);
        hiddenActions.insert(0, droppableAction);
      } else if (droppableTab != null) {
        shownTabs.remove(droppableTab);
        hiddenTabs.insert(0, droppableTab);
      } else {
        break;
      }
    }
    return [
      if (leading != null)
        SizedBox(
          height: _itemExtent,
          child: Center(child: leading),
        ),
      for (final action in shownActions)
        _BarButton(
          icon: action.icon,
          label: action.label,
          onPressed: action.onPressed,
          prominent: action.prominent,
        ),
      if (needsMenu) _buildOverflow(hiddenActions, hiddenTabs),
      const Spacer(),
      for (final i in shownTabs)
        _BarButton(
          icon: i == widget.selectedIndex
              ? widget.destinations[i].selectedIcon ??
                    widget.destinations[i].icon
              : widget.destinations[i].icon,
          label: widget.destinations[i].label,
          selected: i == widget.selectedIndex,
          onPressed: () => widget.onDestinationSelected?.call(i),
        ),
    ];
  }

  Widget _buildOverflow(List<FoldAction> actions, List<int> tabs) {
    return SizedBox(
      height: _itemExtent,
      child: PopupMenuButton<VoidCallback>(
        icon: const Icon(Icons.more_horiz),
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        onSelected: (run) => run(),
        itemBuilder: (_) => [
          for (final a in actions)
            PopupMenuItem(
              value: a.onPressed ?? () {},
              enabled: a.onPressed != null,
              child: ListTile(leading: Icon(a.icon), title: Text(a.label)),
            ),
          for (final i in tabs)
            PopupMenuItem(
              value: () => widget.onDestinationSelected?.call(i),
              child: ListTile(
                leading: Icon(widget.destinations[i].icon),
                title: Text(widget.destinations[i].label),
              ),
            ),
        ],
      ),
    );
  }

  List<FoldAction> get _orderedActions => [
    ...widget.actions.where((a) => a.prominent),
    ...widget.actions.where((a) => !a.prominent).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority)),
  ];
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool prominent;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected || prominent
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return SizedBox(
      height: 64,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? scheme.secondaryContainer : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
