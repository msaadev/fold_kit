# fold_kit

[![pub package](https://img.shields.io/pub/v/fold_kit.svg)](https://pub.dev/packages/fold_kit)

**Foldable and large-screen toolkit for Flutter.** Know where the fold is, how the device is
held and which window size class you are in, on **iPhone Duo, Samsung Galaxy Z Fold, Google
Pixel Fold**, flip phones, tablets and iPad. Build adaptive, responsive, dual-screen layouts
that never put a button on the hinge.

**Docs and device list:** [monsware.com/foldkit](https://monsware.com/foldkit/)

## One API for every device and platform

Write your layout once. `fold_kit` answers the same questions everywhere, so the same code runs on
a phone, a foldable, a tablet, the web and desktop:

| Device | Fold position & posture | Window size class |
|---|---|---|
| Samsung Galaxy Z Fold / Flip, Pixel Fold, other Android foldables | ✅ | ✅ |
| iPhone Duo (iOS 27.1) | 🔜 0.1 | ✅ |
| iPad, Android tablets | — (no fold, reported as `none`) | ✅ |
| Phones, web, macOS, Windows, Linux | — (no fold, reported as `none`) | ✅ |

Other packages cover one device (for example only iPhone Duo). `fold_kit` is cross-platform by design:
one `FoldInfo`, one set of widgets, every platform.

## What works today (0.0.x)

```dart
import 'package:fold_kit/fold_kit.dart';

final fold = FoldInfo.of(context);

fold.hasFold;          // a fold or hinge is in view
fold.rect;             // where it is, in logical pixels
fold.axis;             // FoldAxis.vertical (book) or .horizontal (tabletop)
fold.posture;          // none, closed, halfOpen, flat
fold.windowSizeClass;  // compact (< 600), medium (< 840), expanded
```

Fold data comes from Flutter's `MediaQuery.displayFeatures`, which Flutter fills on Android
foldables today.

## Coming in 0.1: less code for adaptive layouts

- **iPhone Duo**: the fold and posture on iOS 27.1 (Flutter does not report them on iOS yet).
- **`FoldScaffold`**: app bar and tabs move into a vertical bar on the right, like system apps on iPhone Duo.
- **Hinge angle** stream (iPhone Duo, Android foldables).
- **`FoldTwoPane`** and **`FoldAvoid`**: split at the fold, keep buttons off the hinge.
- A live **device catalog** of current foldables and test helpers for every posture.

## Keywords

Flutter foldable · iPhone Duo · Galaxy Z Fold · Pixel Fold · hinge · dual screen · two pane ·
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
