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

## FoldScaffold: iPhone Duo-style bars in one line

```dart
FoldScaffold(
  title: const Text('Rides'),
  actions: [
    FoldAction(icon: Icons.add, label: 'New', prominent: true, onPressed: create),
    FoldAction(icon: Icons.search, label: 'Search', onPressed: search),
  ],
  destinations: const [
    FoldDestination(icon: Icons.list_alt, label: 'Rides'),
    FoldDestination(icon: Icons.person, label: 'Profile'),
  ],
  selectedIndex: tab,
  onDestinationSelected: (i) => setState(() => tab = i),
  body: page,
)
```

On iPhone Duo the system moves native app bars and tab bars into a vertical bar on the right.
Flutter draws its own bars, so they would stay horizontal; `FoldScaffold` does the same move.

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
