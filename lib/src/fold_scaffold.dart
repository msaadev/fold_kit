import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoTabBar;
import 'package:flutter/material.dart';

import 'fold_kit_scope.dart';
import 'fold_state.dart';

/// An app bar action that can live in a horizontal app bar or a vertical bar.
class FoldAction {
  /// Icon, always shown (usually an [Icon]; a [Badge] works too).
  final Widget icon;

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
  /// Icon of the tab (usually an [Icon]; a [Badge] works too).
  final Widget icon;

  /// Icon when selected; defaults to [icon].
  final Widget? selectedIcon;

  /// Label of the tab.
  final String label;

  /// Creates a tab.
  const FoldDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  /// Reuses an existing [BottomNavigationBarItem], so tabs are defined once.
  factory FoldDestination.fromItem(BottomNavigationBarItem item) =>
      FoldDestination(
        icon: item.icon,
        selectedIcon: item.activeIcon,
        label: item.label ?? '',
      );
}

/// Colors of the vertical bar, to match your app's own bars.
@immutable
class FoldBarTheme {
  /// Background of the capsules that hold the buttons. Defaults to the
  /// theme's surfaceContainerLowest.
  final Color? backgroundColor;

  /// Selected tab and prominent action color. Defaults to the primary color.
  final Color? selectedColor;

  /// Other items. Defaults to onSurfaceVariant.
  final Color? unselectedColor;

  /// Circle behind the selected tab. Defaults to secondaryContainer; use
  /// `Colors.transparent` for none.
  final Color? indicatorColor;

  /// Distance from the top of the iPhone Duo status strip to the bar, below
  /// the clock. Defaults to the value measured on iOS 27.1 (170 closed, 120
  /// open); set it if a future iOS moves the clock.
  final double? topInset;

  /// Width of the vertical bar where there is no iPhone Duo status strip
  /// (Android foldables, tablets). Defaults to 72.
  final double? width;

  /// Liquid Glass look: blurred, see-through capsules with a light rim. Also
  /// turns the tabs built from `destinations` into a floating glass tab bar on
  /// phones (your own `bottomNavigationBar` is kept as it is).
  final bool glass;

  /// Unused: the vertical bar shows icons only, like the native one.
  @Deprecated('The vertical bar shows icons only; the label is the tooltip.')
  final TextStyle? labelStyle;

  /// Creates a bar theme.
  const FoldBarTheme({
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.glass = false,
    this.topInset,
    this.width,
    @Deprecated('The vertical bar shows icons only; the label is the tooltip.')
    this.labelStyle,
  });
}

/// What the vertical bar shows, handed to [FoldScaffold.verticalBarBuilder]
/// so you can draw the bar any way you like.
@immutable
class FoldBarContent {
  /// Back or close button, `null` when there is none.
  final Widget? leading;

  /// Actions given as [FoldAction]s (prominent first, then by priority).
  final List<FoldAction> actions;

  /// Action widgets read from your own `AppBar.actions`.
  final List<Widget> appBarActions;

  /// The tabs.
  final List<FoldDestination> destinations;

  /// Index of the selected tab.
  final int selectedIndex;

  /// Call with a tab index to select it.
  final ValueChanged<int>? onDestinationSelected;

  /// Creates the content.
  const FoldBarContent({
    required this.leading,
    required this.actions,
    required this.appBarActions,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
}

/// Where the app bar and the tabs go.
enum FoldBarPlacement {
  /// Vertical where it saves room: on iPhone Duo the outer display and the
  /// inner display in landscape (like native apps); elsewhere any window 840
  /// or wider (open Android foldables, tablets). Phones keep bottom bars.
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
/// inner display in landscape) — and stay your normal app bar + bottom bar
/// everywhere else. The body keeps its state when the bars move.
///
/// Migrating an existing screen: rename `Scaffold` to `FoldScaffold`. Your
/// `AppBar` (title, leading, actions) and your `NavigationBar`,
/// `BottomNavigationBar` or `CupertinoTabBar` are read as they are, so phones
/// look exactly the same and the vertical bar gets the same tabs and buttons.
class FoldScaffold extends StatefulWidget {
  /// Page title.
  final Widget? title;

  /// Back or close button; defaults to a back button when the route can pop.
  final Widget? leading;

  /// App bar actions.
  final List<FoldAction> actions;

  /// Tabs; when empty they are read from [bottomNavigationBar].
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

  /// Your own app bar for the horizontal layout (phones). When `null`, an
  /// [AppBar] is built from [title], [leading] and [actions] — or none at all
  /// when those are empty.
  final PreferredSizeWidget? appBar;

  /// Your own bottom bar for the horizontal layout, so phones keep their exact
  /// look. A [NavigationBar], [BottomNavigationBar] or [CupertinoTabBar] also
  /// gives the vertical bar its tabs, selection and tap callback. When `null`,
  /// a [NavigationBar] is built from [destinations].
  final Widget? bottomNavigationBar;

  /// Colors of the vertical bar.
  final FoldBarTheme? barTheme;

  /// With [FoldBarPlacement.auto]: your own rule for when the bars go
  /// vertical, e.g. `(fold) => fold.info.windowSizeClass != WindowSizeClass.compact`.
  /// Defaults to the rule described on [FoldBarPlacement.auto].
  final bool Function(FoldState fold)? verticalWhen;

  /// Draws the whole vertical bar yourself from its [FoldBarContent]. It gets
  /// the bar's column (the iPhone Duo status strip, or [FoldBarTheme.width]).
  final Widget Function(BuildContext context, FoldBarContent bar)?
  verticalBarBuilder;

  /// Passed to the inner [Scaffold].
  final Color? backgroundColor;

  /// Passed to the inner [Scaffold].
  final bool? resizeToAvoidBottomInset;

  /// Passed to the inner [Scaffold].
  final Widget? drawer, endDrawer;

  /// Passed to the inner [Scaffold].
  final Widget? bottomSheet;

  /// Passed to the inner [Scaffold].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Passed to the inner [Scaffold].
  final List<Widget>? persistentFooterButtons;

  /// Passed to the inner [Scaffold]; the glass tab bar turns [extendBody] on.
  final bool extendBody, extendBodyBehindAppBar;

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
    this.appBar,
    this.bottomNavigationBar,
    this.barTheme,
    this.verticalWhen,
    this.verticalBarBuilder,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  /// Whether the bars are vertical for this window with [placement] and an
  /// optional [verticalWhen] rule (see [FoldScaffold.verticalWhen]).
  static bool isVertical(
    BuildContext context,
    FoldBarPlacement placement, {
    bool Function(FoldState fold)? verticalWhen,
  }) {
    switch (placement) {
      case FoldBarPlacement.bottom:
        return false;
      case FoldBarPlacement.trailing:
        return true;
      case FoldBarPlacement.auto:
        if (verticalWhen != null) return verticalWhen(FoldKit.of(context));
        final size = MediaQuery.sizeOf(context);
        final landscape = size.width > size.height;
        return switch (FoldKitScope.statusOf(context)) {
          HingeStatus.closed => true,
          HingeStatus.partiallyOpen || HingeStatus.fullyOpen => landscape,
          HingeStatus.unknown => size.width >= 840,
        };
    }
  }

  @override
  State<FoldScaffold> createState() => _FoldScaffoldState();
}

class _FoldScaffoldState extends State<FoldScaffold> {
  final _bodyKey = GlobalKey();

  static const double _barWidth = 72;
  static const double _itemExtent = 50;
  static const double _capsuleWidth = 48;
  static const double _groupGap = 12;
  static const double _minStripWidth = 56;

  @override
  Widget build(BuildContext context) {
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    final vertical = FoldScaffold.isVertical(
      context,
      widget.placement,
      verticalWhen: widget.verticalWhen,
    );
    if (!vertical) {
      return _buildHorizontal(context, body);
    }
    return _buildVertical(context, body);
  }

  Widget _buildHorizontal(BuildContext context, Widget body) {
    final glassTabs =
        widget.bottomNavigationBar == null && (widget.barTheme?.glass ?? false);
    return Scaffold(
      extendBody: glassTabs || widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      bottomSheet: widget.bottomSheet,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      persistentFooterButtons: widget.persistentFooterButtons,
      appBar: widget.appBar ?? _buildAppBar(),
      body: body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar:
          widget.bottomNavigationBar ??
          (glassTabs ? _buildGlassTabBar() : _buildNavigationBar()),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    final empty =
        widget.title == null &&
        widget.leading == null &&
        widget.actions.isEmpty;
    if (empty) return null;
    return AppBar(
      leading: widget.leading,
      title: widget.title,
      actions: [
        for (final action in _orderedActions)
          IconButton(
            icon: action.icon,
            tooltip: action.label,
            onPressed: action.onPressed,
          ),
      ],
    );
  }

  Widget? _buildNavigationBar() {
    if (widget.destinations.isEmpty) return null;
    return NavigationBar(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      destinations: [
        for (final d in widget.destinations)
          NavigationDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon ?? d.icon,
            label: d.label,
          ),
      ],
    );
  }

  Widget? _buildGlassTabBar() {
    if (widget.destinations.isEmpty) return null;
    final tabs = widget.destinations;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: _Glass(
        theme: widget.barTheme,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _BarButton(
                    icon: i == widget.selectedIndex
                        ? tabs[i].selectedIcon ?? tabs[i].icon
                        : tabs[i].icon,
                    label: tabs[i].label,
                    selected: i == widget.selectedIndex,
                    onPressed: () => widget.onDestinationSelected?.call(i),
                    theme: widget.barTheme,
                    showsLabel: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVertical(BuildContext context, Widget body) {
    final textTheme = Theme.of(context).textTheme;
    final title = widget.title ?? _ownAppBar?.title;
    final padding = MediaQuery.paddingOf(context);
    final inStrip = _usesStatusStrip(context);
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      bottomSheet: widget.bottomSheet,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      persistentFooterButtons: widget.persistentFooterButtons,
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        // The Duo status strip is on the right in every language.
        textDirection: inStrip ? TextDirection.ltr : null,
        children: [
          Expanded(
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: DefaultTextStyle(
                        style: textTheme.titleLarge!,
                        child: title,
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
          SizedBox(
            width: inStrip
                ? padding.right
                : padding.right + (widget.barTheme?.width ?? _barWidth),
            child: widget.verticalBarBuilder == null
                ? _buildBar(context, inStrip)
                : widget.verticalBarBuilder!(context, _barContent(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, bool inStrip) {
    final padding = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        top: inStrip ? _statusHeight(context) : padding.top + 8,
        bottom: padding.bottom + 8,
        right: inStrip ? 0 : padding.right,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: _buildBarGroups(context, constraints.maxHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBarGroups(BuildContext context, double height) {
    final content = _barContent(context);
    final leading = content.leading;
    final ownActions = content.appBarActions;
    // Room left after the gaps between the capsules and their inner padding.
    final capacity =
        ((height - 2 * _groupGap - 3 * 8) / _itemExtent).floor() -
        (leading == null ? 0 : 1) -
        ownActions.length;
    final shownActions = [..._orderedActions];
    final tabs = _tabs;
    final selected = _selectedIndex;
    final shownTabs = [for (var i = 0; i < tabs.length; i++) i];
    final hiddenActions = <FoldAction>[];
    final hiddenTabs = <int>[];
    var needsMenu = false;
    while (shownActions.length + shownTabs.length + (needsMenu ? 1 : 0) >
        capacity) {
      needsMenu = true;
      final droppableAction = shownActions.lastWhereOrNull((a) => !a.prominent);
      final droppableTab = shownTabs.lastWhereOrNull((i) => i != selected);
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
    final actionItems = [
      for (final action in shownActions)
        _BarButton(
          icon: action.icon,
          label: action.label,
          onPressed: action.onPressed,
          prominent: action.prominent,
          theme: widget.barTheme,
        ),
      for (final w in ownActions)
        SizedBox(
          height: _itemExtent,
          child: Center(child: w),
        ),
      if (needsMenu) _buildOverflow(hiddenActions, hiddenTabs, tabs),
    ];
    return [
      if (leading != null) ...[
        _buildCapsule(context, [
          SizedBox(
            height: _itemExtent,
            child: Center(child: leading),
          ),
        ]),
        const SizedBox(height: _groupGap),
      ],
      if (actionItems.isNotEmpty) _buildCapsule(context, actionItems),
      const Spacer(),
      if (shownTabs.isNotEmpty) ...[
        const SizedBox(height: _groupGap),
        _buildCapsule(context, [
          for (final i in shownTabs)
            _BarButton(
              icon: i == selected
                  ? tabs[i].selectedIcon ?? tabs[i].icon
                  : tabs[i].icon,
              label: tabs[i].label,
              selected: i == selected,
              onPressed: () => _onSelected?.call(i),
              theme: widget.barTheme,
            ),
        ]),
      ],
    ];
  }

  Widget _buildCapsule(BuildContext context, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.barTheme?.glass ?? false) {
      return _Glass(
        theme: widget.barTheme,
        child: Container(
          width: _capsuleWidth,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
    }
    return Container(
      width: _capsuleWidth,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: ShapeDecoration(
        color:
            widget.barTheme?.backgroundColor ?? scheme.surfaceContainerLowest,
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildOverflow(
    List<FoldAction> actions,
    List<int> hiddenTabs,
    List<FoldDestination> tabs,
  ) {
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
              child: ListTile(leading: a.icon, title: Text(a.label)),
            ),
          for (final i in hiddenTabs)
            PopupMenuItem(
              value: () => _onSelected?.call(i),
              child: ListTile(
                leading: tabs[i].icon,
                title: Text(tabs[i].label),
              ),
            ),
        ],
      ),
    );
  }

  FoldBarContent _barContent(BuildContext context) => FoldBarContent(
    leading:
        widget.leading ??
        _ownAppBar?.leading ??
        (ModalRoute.of(context)?.canPop ?? false ? const BackButton() : null),
    actions: _orderedActions,
    appBarActions: widget.actions.isEmpty
        ? _ownAppBar?.actions ?? const <Widget>[]
        : const <Widget>[],
    destinations: _tabs,
    selectedIndex: _selectedIndex,
    onDestinationSelected: _onSelected,
  );

  /// iPhone Duo keeps the status indicators in a strip on the right edge, and
  /// native apps put their vertical bar in that strip below them.
  bool _usesStatusStrip(BuildContext context) =>
      FoldKitScope.statusOf(context) != HingeStatus.unknown &&
      MediaQuery.paddingOf(context).right >= _minStripWidth;

  // shortcut: measured on the iPhone Duo simulator (iOS 27.1); read the status
  // strip frame from the platform once iOS exposes it.
  double _statusHeight(BuildContext context) =>
      widget.barTheme?.topInset ??
      (FoldKitScope.statusOf(context) == HingeStatus.closed ? 170 : 120);

  AppBar? get _ownAppBar => switch (widget.appBar) {
    final AppBar bar => bar,
    _ => null,
  };

  List<FoldDestination> get _tabs {
    if (widget.destinations.isNotEmpty) return widget.destinations;
    return switch (widget.bottomNavigationBar) {
      final NavigationBar bar => [
        for (final d in bar.destinations)
          if (d case final NavigationDestination n)
            FoldDestination(
              icon: n.icon,
              selectedIcon: n.selectedIcon,
              label: n.label,
            ),
      ],
      final BottomNavigationBar bar => [
        for (final item in bar.items) FoldDestination.fromItem(item),
      ],
      final CupertinoTabBar bar => [
        for (final item in bar.items) FoldDestination.fromItem(item),
      ],
      _ => const [],
    };
  }

  int get _selectedIndex => widget.destinations.isNotEmpty
      ? widget.selectedIndex
      : switch (widget.bottomNavigationBar) {
          final NavigationBar bar => bar.selectedIndex,
          final BottomNavigationBar bar => bar.currentIndex,
          final CupertinoTabBar bar => bar.currentIndex,
          _ => widget.selectedIndex,
        };

  ValueChanged<int>? get _onSelected =>
      widget.onDestinationSelected ??
      switch (widget.bottomNavigationBar) {
        final NavigationBar bar => bar.onDestinationSelected,
        final BottomNavigationBar bar => bar.onTap,
        final CupertinoTabBar bar => bar.onTap,
        _ => null,
      };

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
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool prominent;
  final FoldBarTheme? theme;
  final bool showsLabel;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.prominent = false,
    this.theme,
    this.showsLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected || prominent
        ? theme?.selectedColor ?? scheme.primary
        : theme?.unselectedColor ?? scheme.onSurfaceVariant;
    final indicator = selected
        ? ShapeDecoration(
            color: theme?.indicatorColor ?? scheme.secondaryContainer,
            shape: const StadiumBorder(),
          )
        : null;
    final iconWidget = IconTheme.merge(
      data: IconThemeData(color: color),
      child: icon,
    );
    return SizedBox(
      height: showsLabel ? 56 : _FoldScaffoldState._itemExtent,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        enabled: onPressed != null,
        onTap: onPressed,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: showsLabel
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: indicator,
                        child: iconWidget,
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
                  )
                : Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: indicator,
                      child: Center(child: iconWidget),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final FoldBarTheme? theme;

  const _Glass({required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint =
        theme?.backgroundColor ?? Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: StadiumBorder()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: dark ? 0.45 : 0.7),
                  tint.withValues(alpha: dark ? 0.25 : 0.45),
                ],
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.18 : 0.8),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
