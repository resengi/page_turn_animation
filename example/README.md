# Page Turn Animation — Example

A demo app for the `page_turn_animation` package: a few pages to turn by
dragging them from anywhere, or with Next and Previous.

## Running the Example

Make sure you are in the example directory, then run:

```bash
flutter pub get
flutter run
```

## What It Demonstrates

- **Single Page**: a page turned over the hinge chosen above it (top, bottom,
  left or right), landing on the back of the stack.
- **Book**: a spread whose right-hand page turns over the spine onto the
  left-hand page (`completionAngle: 180`), with a `backImage`: the back of each
  page is the next left-hand page. Dragging the left-hand page turns it back
  over the spine.
- **Dragging** with `PageTurnDragProgress`, which keeps the spot the finger
  pressed under the finger. Let go once the finger has come half a page and
  the page turns; before that it falls back. A flick decides by its direction.
- **Next and Previous**: timed turns, `PageTurnDirection.forward` and
  `PageTurnDirection.backward`.
- **Widget-to-image capture** using `RepaintBoundary` and `toImage()`.

## How It Works

Each turn goes through three phases:

1. **Idle**: the current page is shown as a normal widget.
2. **Capturing**: the pages the turn shows are drawn in `RepaintBoundary`
   widgets and captured as `ui.Image` objects.
3. **Animating**: the captured images are handed to `PageTurnAnimation`,
   driven by a `CurvedAnimation` for Next and Previous, or by the drag. When
   the turn ends, the page changes if it completed, and the images are
   disposed.

The pages in this demo are simple colored cards, but you can use any Flutter
widget.
