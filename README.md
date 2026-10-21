<p align="center"><img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/logo/logo.png" width="128" alt="fold_kit logo"></p>

# fold_kit

[![pub package](https://img.shields.io/pub/v/fold_kit.svg)](https://pub.dev/packages/fold_kit)

**Foldable and large-screen toolkit for Flutter.** Know where the fold is, how the device is
held and which window size class you are in, on **iPhone Duo, Samsung Galaxy Z Fold, Google
Pixel Fold**, flip phones, tablets and iPad. Build adaptive, responsive, dual-screen layouts
that never put a button on the hinge.

**Docs and device list:** [monsware.com/foldkit](https://monsware.com/foldkit/)

## One API for every device and platform

Write your layout once. `fold_kit` answers the same questions everywhere and gives you widgets that
do the adaptive work for you:

| Device | Fold & posture | Hinge angle | Vertical bars | Size class |
|---|---|---|---|---|
| iPhone Duo (iOS 27.1) | ✅ | ✅ | ✅ | ✅ |
| Galaxy Z Fold / Flip, Pixel Fold, Android foldables | ✅ | ✅ (API 30+) | on wide landscape | ✅ |
| iPad, Android tablets | — (`none`) | — | on wide landscape | ✅ |
| Phones, web, macOS, Windows, Linux | — (`none`) | — | — | ✅ |

Other packages cover one device (for example only iPhone Duo). `fold_kit` is cross-platform by design.

<p align="center">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/preview_duo_half_open.png" width="520" alt="Flutter FoldTwoPane split at the iPhone Duo fold">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/duo_closed.png" width="190" alt="fold_kit on iPhone Duo outer display: vertical bar like iOS">
</p>

## Setup

```dart
void main() => runApp(const FoldKitScope(child: MyApp()));
```

`FoldKitScope` adds the iPhone Duo fold and the hinge angle; on other platforms it passes through.
Build your iOS app with Xcode 27.1 to get the iPhone Duo data.

## Your page when folded, your fold layout when open

```dart
FoldBuilder(
  builder: (context, fold) => fold.isOpen ? const BookingWide() : const BookingPage(),
)

FoldListener(
  onChanged: (fold) => analytics.log('fold', {
    'posture': fold.posture.name,     // closed · halfOpen · flat · none
    'angle': fold.angle,              // degrees, null without a hinge sensor
    'device': fold.device?.name,      // "iPhone Duo", "Galaxy Z Fold7"…
    'model': fold.model,              // "iPhone19,4", "SM-F966B"…
  }),
  child: app,
)

FoldKit.changes.listen((fold) { ... }); // outside widgets
```

## Hinge angle

```dart
FoldListener(
  onAngleChanged: (angle) => setState(() => hinge = angle), // degrees: 0 shut, 180 flat
  child: page,
)

FoldKitScope.angleOf(context);        // read it in build (rebuilds on change)
FoldKit.angles.listen((angle) { ... }); // outside widgets
```

`null` means no hinge sensor (phones, tablets, Android below API 30). Use it for interaction
(a protractor, a camera stand mode), not for layout: layout follows the posture.

## FoldScaffold: rename `Scaffold`, done

On iPhone Duo, iOS moves a native app's tab bar and toolbar buttons into a vertical bar on the
right (outer display, and the inner display in landscape). Flutter draws its own bars, so they
would stay at the bottom. Rename `Scaffold` to `FoldScaffold` and they move the same way:

```dart
FoldScaffold(                       // was: Scaffold(
  appBar: AppBar(
    title: const Text('Rides'),
    actions: [IconButton(icon: const Icon(Icons.search), onPressed: search)],
  ),
  bottomNavigationBar: NavigationBar(  // or BottomNavigationBar / CupertinoTabBar
    selectedIndex: tab,
    onDestinationSelected: (i) => setState(() => tab = i),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.list_alt), label: 'Rides'),
      NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    ],
  ),
  body: page,
)
```

Phones look exactly the same. Where iOS would go vertical, the title, back button, actions and
tabs go into one bar on the right (on iPhone Duo inside the status strip, below the clock, like
native apps), with the same selection and taps. The body keeps its state.
Pass the bar directly (not wrapped in another widget) so it can be read; otherwise give
`destinations`, `selectedIndex` and `onDestinationSelected` yourself.

Want tooltip and screen reader labels, a prominent "Done" button and an overflow menu when the bar is short? Use
`FoldAction`s instead of an `AppBar`:

```dart
FoldScaffold(
  title: const Text('Rides'),
  actions: [
    FoldAction(icon: Icon(Icons.add), label: 'New', prominent: true, onPressed: create),
    FoldAction(icon: Icon(Icons.search), label: 'Search', onPressed: search),
  ],
  barTheme: const FoldBarTheme(selectedColor: brandYellow),
  ...
)
```

<p align="center">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/native_duo_closed.png" width="200" alt="Native SwiftUI app on iPhone Duo outer display">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/duo_closed.png" width="200" alt="FoldScaffold on iPhone Duo outer display, same place as native">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/duo_closed_glass.png" width="200" alt="FoldScaffold with glass capsules on iPhone Duo">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/iphone17_glass.png" width="134" alt="Floating glass tab bar on iPhone 17">
<br><sub>Native SwiftUI · FoldScaffold · FoldScaffold glass · glass tab bar on iPhone 17</sub>
</p>

### Glass look

```dart
FoldScaffold(
  destinations: tabs,                 // tabs built by FoldScaffold
  selectedIndex: tab,
  onDestinationSelected: (i) => setState(() => tab = i),
  barTheme: const FoldBarTheme(glass: true),
  body: page,
)
```

The vertical bar's capsules turn into blurred, see-through glass with a light rim, and on phones the
tabs become a floating glass capsule over the page (the body scrolls under it). If you pass your own
`bottomNavigationBar`, phones keep it as it is. This is a Flutter approximation of Liquid Glass (blur
+ tint + rim), not Apple's refraction, and it adds no dependency.

### Vertical or bottom: your choice

<p align="center">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/android_fold_bottom.png" width="300" alt="Pixel 9 Pro Fold open with a bottom bar: the bar takes a wide strip">
<img src="https://raw.githubusercontent.com/msaadev/fold_kit/main/screen_shots/android_fold_vertical.png" width="300" alt="Pixel 9 Pro Fold open with the vertical bar: the page gets the full height">
<br><sub>Pixel 9 Pro Fold open: bottom bar vs vertical bar. The vertical bar gives the page its full height.</sub>
</p>

On a big screen a bottom bar spans the whole width for three icons. The vertical bar uses one
narrow column and gives the page its full height, so it is **on by default** wherever it helps:

| `placement` | Bars |
|---|---|
| `FoldBarPlacement.auto` (default) | iPhone Duo: vertical on the outer display and in landscape, like native apps. Everywhere else: vertical on windows 840+ wide (open Android foldables, tablets), bottom on phones. |
| `FoldBarPlacement.bottom` | Always your app bar + bottom bar. |
| `FoldBarPlacement.trailing` | Always the vertical bar, phones too (iPhone 17, Pixel): no app bar and no bottom bar, the page gets the whole screen. |

Let your users pick it in settings, it is just a value:

```dart
FoldScaffold(
  placement: settings.barPlacement,   // auto / bottom / trailing, saved by your app
  ...
)
```

Change the rule, the look, or the whole bar:

```dart
FoldScaffold(
  // your own rule for `auto`
  verticalWhen: (fold) => fold.isOpen || fold.info.windowSizeClass == WindowSizeClass.expanded,
  // colors, glass, width, where it starts below the Duo clock
  barTheme: const FoldBarTheme(glass: true, width: 88, selectedColor: brandYellow),
  // or draw the bar yourself: tabs, actions, back button and callbacks are handed to you
  verticalBarBuilder: (context, bar) => MyRail(
    tabs: bar.destinations,
    selected: bar.selectedIndex,
    onTap: bar.onDestinationSelected,
    actions: bar.actions,
  ),
  ...
)
```

`FoldScaffold.isVertical(context, placement)` tells you which layout is on screen, e.g. to move a
FAB or hide a duplicate button.

### Which button goes where

| What | Put it in | On phones | In the vertical bar |
|---|---|---|---|
| 2–5 main sections of the app | `bottomNavigationBar` (or `destinations`) | bottom bar | bottom capsule, icon only |
| Back / close | `AppBar.leading` or `leading` (default: back when the route can pop) | app bar, left | own capsule at the top |
| Actions for this page (search, add, share) | `AppBar.actions` or `actions: [FoldAction]` | app bar, right | top capsule, icon only |
| The one main action (Done, Save) | `FoldAction(prominent: true)` | first action | first, colored, never in the overflow |
| Page title | `AppBar.title` or `title` | app bar | top of the page |
| Create something (FAB) | `floatingActionButton` | unchanged | unchanged |

Rules that keep the vertical bar clean:

- **Every button needs an icon and a label.** The vertical bar shows only the icon; the label is the
  tooltip and what screen readers say. With `IconButton`, set `tooltip`.
- **Tabs are places, actions are verbs.** Don't put "Profile" in `actions` or "Share" in the tabs.
- **Keep actions to 2–3.** When the bar is short, extra actions (lowest `priority` first) move into a
  "…" menu; with `compression: FoldBarCompression.tabsFirst` tabs go first instead.
- **Don't wrap the bar.** Pass `NavigationBar` / `BottomNavigationBar` / `CupertinoTabBar` directly so
  its tabs can be read; a custom bottom bar needs `destinations` + `selectedIndex` +
  `onDestinationSelected`.
- **Custom app bars** (`SliverAppBar`, your own widget): give `title`, `leading` and `actions`
  to `FoldScaffold` so the vertical bar can show them.

## Adding it to a large existing app

You don't migrate the app, you migrate **one screen**: the one that owns the tabs. Every other
screen keeps its `Scaffold` and works as before.

1. `fold_kit` in `pubspec.yaml`, wrap the app once: `runApp(FoldKitScope(child: MyApp()))`.
   Nothing changes on phones; it only adds fold data.
2. In the shell screen (tabs), rename `Scaffold` to `FoldScaffold`. It takes the same parameters
   (`appBar`, `body`, `bottomNavigationBar`, `floatingActionButton`, `floatingActionButtonLocation`,
   `drawer`, `endDrawer`, `bottomSheet`, `persistentFooterButtons`, `backgroundColor`,
   `extendBody`, `extendBodyBehindAppBar`, `resizeToAvoidBottomInset`), so it compiles as is.
   Phones look exactly the same because your own bars are used.
3. `dart run fold_kit:audit` lists what breaks on foldables (mostly `MediaQuery.of(context).size`
   → `MediaQuery.sizeOf(context)`). Add `--fatal` in CI so new ones don't come back.
4. Later, screen by screen: rename the `Scaffold` of pages with toolbar buttons (detail, editor) so
   their buttons move too, and use `FoldBuilder` / `FoldTwoPane` where a wide layout helps.

A dry run on a production taxi app took about 30 minutes for steps 1–2 (~30 changed lines).

## FoldTwoPane: split at the fold

```dart
FoldTwoPane(start: RideList(), end: RideDetail())
```

Book posture: split exactly at the hinge. Tabletop: top and bottom. Tablet: side by side. Phone: one pane.

## FoldInfo and FoldAvoid

```dart
final fold = FoldInfo.of(context);
fold.posture;          // none, closed, halfOpen, flat
fold.rect;             // the fold in logical pixels
fold.windowSizeClass;  // compact, medium, expanded

FoldAvoid(child: FloatingActionButton(onPressed: go)); // never on the hinge
FoldKitScope.angleOf(context);                          // hinge angle in degrees
```

## FoldPreview: build for foldables without a foldable

```dart
// Any device, any posture, on your laptop, in tests and in screenshots:
FoldPreview(controls: true, child: MyHomePage())

// In a widget test:
await tester.pumpWidget(MaterialApp(
  home: FoldPreview(
    device: FoldDevices.byId('iphone-duo'),
    posture: FoldPosture.halfOpen,
    child: const MyHomePage(),
  ),
));
```

The window size, the fold, the hinge status and the safe area are faked, so `FoldInfo`,
`FoldScaffold` and `FoldTwoPane` behave exactly like on the device.

## Device catalog

```dart
FoldDevices.all;                    // iPhone Duo, Galaxy Z Fold7, iPads, a reference phone
FoldDevices.byId('galaxy-z-fold7');
await FoldDevices.refresh();        // opt-in: latest list from monsware.com/foldkit/models
```

`refresh()` is a plain GET with no data sent, but like any request it reveals the device's IP
address to monsware.com — mention it in your privacy policy if you turn it on. Layout never
depends on the catalog: the fold always comes from the OS.

## Audit your app

```bash
dart run fold_kit:audit          # lists file:line + what to change
dart run fold_kit:audit --fatal  # non-zero exit for CI
```

## Moving from dual_screen

| dual_screen | fold_kit |
|---|---|
| `TwoPane(startPane:, endPane:, paneProportion:)` | `FoldTwoPane(start:, end:, ratio:)` |
| `DualScreenInfo.hingeAngleEvents` | `FoldKitScope.angleOf(context)` |
| `DualScreenInfo.hasHingeAngleSensor` | `FoldKitScope.angleOf(context) != null` |
| Surface Duo only | Android foldables, iPhone Duo, tablets, phones, web, desktop |

## Keywords

Flutter foldable · iPhone Duo · Galaxy Z Fold · Pixel Fold · hinge angle · dual screen · two pane · dual_screen alternative ·
adaptive layout · responsive layout · window size class · tablet · iPad.

Issues and ideas: [GitHub](https://github.com/msaadev/fold_kit/issues).

## About the author

Made with ❤️ by **[Muhammed Şamil Demir](https://monsware.com)**, Flutter & iOS developer and founder of
**[Monsware](https://monsware.com)**. Free and open source (see LICENSE).

- 🌐 Website: [monsware.com](https://monsware.com) · GitHub: [@msaadev](https://github.com/msaadev)
- 📱 Apps by Monsware: [Triangle Calculator](https://apps.apple.com/app/id1600108278) ·
  [Circle Calculator](https://apps.apple.com/app/id1607441563)
- 📦 More Flutter packages: [awesome_stepper](https://pub.dev/packages/awesome_stepper) ·
  [regex_ui](https://pub.dev/packages/regex_ui) · [fold_kit](https://pub.dev/packages/fold_kit)
- 💼 Need a Flutter or iOS app built? [Get in touch](https://monsware.com/contact)

If this package saves you time, a ⭐ on GitHub and a 👍 on pub.dev help a lot.
