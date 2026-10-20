# fold_kit

Foldable and large-screen toolkit for Flutter: fold position, posture, hinge angle and
iPhone Duo-style vertical bars, on iOS and Android.

> Work in progress — not published yet. Plan and docs: [monsware.com/foldkit](https://monsware.com/foldkit/).

## Planned for 0.1

- `FoldInfo.of(context)`: fold rect, axis, posture (closed / half open / flat), window size class.
- iPhone Duo fold reported in `MediaQuery.displayFeatures` (Flutter only does this on Android today).
- `FoldScaffold`: app bar and tabs move into a vertical bar on the right, like system apps on iPhone Duo.
- Hinge angle stream (iPhone Duo, Android foldables).
- `FoldTwoPane`, `FoldAvoid`, a remote device catalog and test helpers.

Made by [Monsware](https://monsware.com). MIT license.
