/// Direction of the page turn animation.
///
/// The direction determines whether the page animates away from view
/// or into view, independent of which [PageTurnEdge] is selected.
///
/// When combined with [PageTurnEdge], you get full control over the animation:
///
/// | Edge | Direction | Visual Effect |
/// |------|-----------|---------------|
/// | top | forward | Page curls up and away |
/// | top | backward | Page curls down into view |
/// | bottom | forward | Page curls down and away |
/// | bottom | backward | Page curls up into view |
/// | left | forward | Page curls left and away |
/// | left | backward | Page curls right into view |
/// | right | forward | Page curls right and away |
/// | right | backward | Page curls left into view |
enum PageTurnDirection {
  /// Page curls away from view, revealing content beneath.
  ///
  /// Use this when animating from the current content to new content,
  /// such as moving forward in time, navigating to the next item,
  /// or dismissing a page.
  ///
  /// The exact visual direction depends on the [PageTurnEdge]:
  /// - [PageTurnEdge.top]: curls up
  /// - [PageTurnEdge.bottom]: curls down
  /// - [PageTurnEdge.left]: curls left
  /// - [PageTurnEdge.right]: curls right
  forward,

  /// Page curls into view, covering content beneath.
  ///
  /// Use this when animating to reveal previous content,
  /// such as moving backward in time, navigating to a previous item,
  /// or presenting a page.
  ///
  /// The exact visual direction depends on the [PageTurnEdge]:
  /// - [PageTurnEdge.top]: curls down into view
  /// - [PageTurnEdge.bottom]: curls up into view
  /// - [PageTurnEdge.left]: curls right into view
  /// - [PageTurnEdge.right]: curls left into view
  backward,
}
