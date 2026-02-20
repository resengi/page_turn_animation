# Page Turn Animation — Example

A demo app showcasing the `page_turn_animation` package. It simulates a simple
book viewer where pages can be turned forward and backward with realistic curl
animations.

## Running the Example

Make sure you are in the example directory, then run:

```bash
flutter pub get
flutter run
```

## What It Demonstrates

- **Forward and backward page turns** using `PageTurnDirection`
- **All four edge directions** (top, bottom, left, right) via a dropdown selector
- **Widget-to-image capture** using `RepaintBoundary` and `toImage()`
- **Animation lifecycle**: capture → animate → commit, managed with a simple
  `_Phase` enum
- **Custom styling** via `PageTurnStyle` (background color, shadow, segments,
  curl intensity)

## How It Works

The example uses a three-phase approach:

1. **Idle** — displays the current page as a normal widget.
2. **Capturing** — renders both the current and target pages in
   `RepaintBoundary` widgets and captures them as `ui.Image` objects.
3. **Animating** — hands the captured images to `PageTurnAnimation`, which
   performs the curl effect. Once complete, the page index updates and the
   cycle resets.

This pattern can be adapted for any content — the pages in this demo are
simple colored cards, but you can use any Flutter widget.