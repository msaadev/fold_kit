## 1.1.0

* **`FoldScaffold` reads your native bars**: pass a `NavigationBar`, `BottomNavigationBar` or
  `CupertinoTabBar` as `bottomNavigationBar` and its tabs, selection and tap callback go into the
  vertical bar on iPhone Duo — no `destinations` needed. Renaming `Scaffold` is the whole migration.
* **Vertical bar looks native on iPhone Duo**: it sits in the status strip on the right, below the
  clock (no extra band, the page keeps its width), with icon-only buttons in capsules: back, actions,
  tabs. `FoldBarTheme.backgroundColor` now colors the capsules; `labelStyle` is deprecated.
* **Glass look**: `FoldBarTheme(glass: true)` makes the capsules blurred, see-through glass, and on
  phones turns the tabs built from `destinations` into a floating glass tab bar.
* **Drop-in for big apps**: `FoldScaffold` also takes `bottomSheet`, `floatingActionButtonLocation`,
  `persistentFooterButtons`, `extendBody` and `extendBodyBehindAppBar`, so renaming `Scaffold` compiles.
* Right-to-left languages: the iPhone Duo bar stays in the status strip on the right.
* `FoldDevice.innerPadding`: `FoldPreview` shows the iPhone Duo status strip on the open display too.
* **`FoldTwoPane` options**: `splitWhen` (e.g. split only while half open), `splitWithoutFold`
  (tablets stay one page) and `hinge` (a widget in the fold gap).
* **`FoldLayoutBuilder`**: the fold mapped into any widget (`LocalFold.start` / `end` / `rect`), for
  layouts like "keep the canvas above a tabletop fold".
* **`FoldAngleController`**: live hinge angle for protractor-style features, with `hold()` that
  takes the value from just before the tap.
* `FoldBarTheme.topInset` overrides where the iPhone Duo bar starts below the clock.
* Android: a hinge angle under 15° counts as `closed` (outer display); bars stay at the bottom there.
* Catalog: Pixel 9 Pro Fold (measured on the emulator).
* **Vertical bar is your choice**: `FoldBarPlacement.auto` now also goes vertical on any window 840+
  wide (open Android foldables, tablets in portrait); `verticalWhen` sets your own rule,
  `verticalBarBuilder` draws the whole bar from `FoldBarContent`, `FoldBarTheme.width` sizes it.
* Package rule: every public member is documented (`public_member_api_docs` on).
* **Hinge angle listener**: `FoldListener(onAngleChanged: …)` and `FoldKit.angles` stream.
  `FoldListener.onChanged` is now optional.

## 1.0.0

First stable release: one foldable and large-screen API for every device.

* **`FoldPreview`**: run any screen as iPhone Duo, Galaxy Z Fold or iPad (closed, half open,
  flat, portrait) on any screen or in widget tests, with the fold painted on top and an optional
  toolbar. Build foldable layouts without a foldable.
* **Device catalog** (`FoldDevices`): measured sizes and folds of current foldables and tablets;
  `FoldDevices.refresh()` (opt-in) pulls the latest list from monsware.com/foldkit/models.
* **`dart run fold_kit:audit`**: lists code and settings that break on foldables, tablets and
  Split View (screen-size math, orientation locks, `inactive` pauses, `UIRequiresFullScreen`,
  `screenOrientation`…). `--fatal` for CI.
* **`FoldBuilder`, `FoldListener`, `FoldKit.changes`**: one `FoldState` with posture, hinge angle,
  device (model id + catalog name) and `isOpen` / `isClosed` / `isFoldable` — render your own
  foldable layout when it is open, your normal page otherwise.
* **Easy migration**: `FoldScaffold` keeps your own `appBar` and `bottomNavigationBar` on phones,
  adds no app bar when you have none, takes `Widget` icons (badges work) and reuses your
  `BottomNavigationBarItem`s via `FoldDestination.fromItem`; `FoldBarTheme` matches your colors.
* `FoldKitScope` follows rotation and window resizing (MediaQuery used to keep the first size on
  Android, web and desktop).
* `fold_kit:audit` flags `UIRequiresFullScreen` only when it is `true`.
* `FoldScaffold`: screen readers can press the vertical bar buttons; your own `AppBar`'s title,
  leading and actions show in the vertical layout too; the bar scrolls instead of overflowing on short
  windows; `drawer` and `endDrawer` are passed through, so renaming `Scaffold` works for apps with a drawer.
* `FoldDevice` equality by `id`: `FoldPreview` keeps its selection after `FoldDevices.refresh()`.
* iOS hinge angle is reported in degrees (UIKit gives radians); fully open is 180.
* Everything from 0.1.0 below.

## 0.1.0 (not published, part of 1.0.0)

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
