## 0.1.0

* **iPhone Duo**: `FoldKitScope` reads the fold (reserved division region) and the hinge status on
  iOS 27.1 and puts the fold into `MediaQuery.displayFeatures`, like Flutter does on Android.
  `FoldInfo.posture` now reports `closed` and `flat` too. Builds with Xcode 27.0 as well (no-op there).
* **`FoldScaffold`**: app bar and tabs move into one vertical bar on the right where iOS does that
  for native apps (Duo outer display, inner display in landscape); normal app bar + navigation bar
  elsewhere. Overflow menu, prominent actions, priorities; the body keeps its state.
* **`FoldTwoPane`**: two panes split exactly at the fold (book or tabletop), by ratio on wide
  windows without a fold, one pane on phones.
* **`FoldAvoid`**: keeps hand-positioned buttons off the hinge.
* **Hinge angle**: `FoldKitScope.angleOf(context)` on iPhone Duo and Android foldables (API 30+ hinge sensor).
* New logo.

## 0.0.1

* `FoldInfo.of(context)`: fold rect, axis, posture (none / closed / halfOpen / flat) and window size class.
* `WindowSizeClass` (compact / medium / expanded, Material 3 breakpoints).
* Android foldables supported through Flutter's display features; iPhone Duo support comes in 0.1.
