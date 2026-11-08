import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

void main() {
  runApp(const PageTurnExampleApp());
}

// =============================================================================
// App
// =============================================================================

/// Example app for the page_turn_animation package: a few pages to turn by
/// dragging them from anywhere, or with Next and Previous. The Single Page tab
/// turns a page over the hinge chosen above it; the Book tab turns the
/// right-hand page of a spread over the spine onto the facing page, and each
/// page's back is the next left-hand page. Dragging the left-hand page turns
/// it back.
class PageTurnExampleApp extends StatelessWidget {
  const PageTurnExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Page Turn Animation Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
        scaffoldBackgroundColor: _Palette.desk,
        appBarTheme: const AppBarTheme(
          backgroundColor: _Palette.bar,
          foregroundColor: _Palette.light,
        ),
      ),
      home: const ExampleHome(),
    );
  }
}

/// The app's colours: a desk, its bar, and light and muted text on them.
abstract final class _Palette {
  static const desk = Color(0xFF3E2723);
  static const bar = Color(0xFF4E342E);
  static const light = Color(0xFFEFEBE9);
  static const muted = Color(0xFFBCAAA4);
  static const spine = Color(0xFF6D4C41);
  static const reverse = Color(0xFFFAF3E8);
}

// =============================================================================
// Home
// =============================================================================

/// The two tabs.
class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page Turn Animation'),
          bottom: const TabBar(
            labelColor: _Palette.light,
            unselectedLabelColor: _Palette.muted,
            indicatorColor: _Palette.light,
            tabs: [
              Tab(text: 'Single Page'),
              Tab(text: 'Book'),
            ],
          ),
        ),
        // Drags turn pages, so the tabs do not swipe.
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [BookViewer(), BookViewer(book: true)],
        ),
      ),
    );
  }
}

// =============================================================================
// Book page data
// =============================================================================

class BookPage {
  const BookPage({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
}

const List<BookPage> _pages = [
  BookPage(
    title: 'Page Turn Animation',
    body:
        'Drag this page from anywhere to turn it: the spot you press stays '
        'under your finger until it reaches the hinge. Let go past halfway '
        'and the page turns; before that it falls back. Next and Previous '
        'turn it for you.',
    color: Color(0xFFFFF3E0),
    icon: Icons.auto_stories,
  ),
  BookPage(
    title: 'Turn From Anywhere',
    body:
        'Where your drag begins is the finger start. Near the free edge the '
        'page peels straight up; from further in, your finger first pushes '
        'the page into an arch, then it lifts off and turns. '
        'PageTurnDragProgress keeps the pressed spot under the finger.',
    color: Color(0xFFE8F5E9),
    icon: Icons.touch_app,
  ),
  BookPage(
    title: 'Any Edge, Any Landing',
    body:
        'Choose the hinge above the page: top for a notepad or wall '
        'calendar, bottom for a pad bound at the bottom, left for a book read '
        'left to right, right for one read right to left. Here the page lands '
        'on the back of the stack (360°); completionAngle lays it down '
        'anywhere from there to flat beside the stack (180°), as on the Book '
        'tab.',
    color: Color(0xFFE1F5FE),
    icon: Icons.swap_horiz,
  ),
  BookPage(
    title: 'Light and Shadow',
    body:
        'The page casts its shadow as from a lamp over the hinge, on the page '
        'beneath, on where it lands and on itself, and is shaded where it '
        'turns away from the light. PageTurnStyle sets the shadows\' opacity '
        'and softness and the lamp\'s distance; an opacity of 0 turns the '
        'shadows off.',
    color: Color(0xFFFFF8E1),
    icon: Icons.light_mode,
  ),
  BookPage(
    title: 'Tips & Best Practices',
    body:
        'Capture images at the device\'s pixel ratio for crisp results, and '
        'dispose of them when done. Give timed turns a CurvedAnimation, and '
        'drags none. Lower the segment count (50–80) on budget devices.',
    color: Color(0xFFFCE4EC),
    icon: Icons.lightbulb_outline,
  ),
];

/// The Book tab's left-hand pages: the backs of its pages, the first on the
/// back of the first page. The last page is not turned, so it has none.
const List<BookPage> _backs = [
  BookPage(
    title: 'The Back of the Page',
    body:
        'You are reading the back of the page you just turned. Give '
        'PageTurnAnimation a backImage and it shows wherever the page\'s back '
        'faces you as it turns, stretched over the page like the front, with '
        'the shadows over it.',
    color: Color(0xFFF3E5F5),
    icon: Icons.flip,
  ),
  BookPage(
    title: 'The Right Way Round',
    body:
        'The back image reads correctly once the page has turned over and '
        'lies beside the stack, over any edge: here, the next left-hand page.',
    color: Color(0xFFE0F2F1),
    icon: Icons.menu_book,
  ),
  BookPage(
    title: 'Either Way',
    body:
        'Press Previous and this page lifts off again, its back showing '
        'first: in either direction, it is the back of the page that turns.',
    color: Color(0xFFFFFDE7),
    icon: Icons.sync_alt,
  ),
  BookPage(
    title: 'Or Plain Paper',
    body:
        'Without a backImage the back is PageTurnStyle\'s plain '
        'backgroundColor, as on the Single Page tab.',
    color: Color(0xFFEFEBE9),
    icon: Icons.crop_portrait,
  ),
];

// =============================================================================
// Animation phases
// =============================================================================

/// [idle]      — show the current page normally.
/// [capturing] — both current and target pages render in RepaintBoundary
///               widgets so their pixels can be captured.
/// [animating] — captured images drive the PageTurnAnimation widget.
enum _Phase { idle, capturing, animating }

// =============================================================================
// BookViewer
// =============================================================================

/// The pages, turned by dragging them or with Next and Previous.
class BookViewer extends StatefulWidget {
  const BookViewer({this.book = false, super.key});

  /// Whether this is the Book tab: a spread whose right-hand page turns over
  /// the spine onto the left-hand page (a completion angle of 180), and whose
  /// left-hand page can be dragged back over it.
  final bool book;

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _targetIndex = 0;
  bool _isForward = true;
  _Phase _phase = _Phase.idle;

  /// Whether the turning page is the Book tab's left-hand page, dragged back
  /// over the spine. It turns forward over its right edge: its front is the
  /// left-hand page, its back the right-hand page before it.
  bool _leftPage = false;

  /// The Single Page tab's hinge, chosen above the page.
  PageTurnEdge _hinge = PageTurnEdge.left;

  /// The edge the page turns over: on the Book tab the spine, the right-hand
  /// page's left edge or the left-hand page's right edge.
  PageTurnEdge get _edge => widget.book
      ? (_leftPage ? PageTurnEdge.right : PageTurnEdge.left)
      : _hinge;

  /// The completion angle: 180 on the Book tab, where a page lies down on the
  /// facing page, and on the Single Page tab the standard 360, the back of the
  /// stack.
  double get _completionAngle =>
      widget.book ? 180 : PageTurnInputs.standardCompletionAngle;

  /// The package's standard style, with the page's plain back paper-coloured.
  static const PageTurnStyle _style = PageTurnStyle(
    backgroundColor: _Palette.reverse,
  );

  // Captured images; on the Book tab, also the turning page's back.
  ui.Image? _currentImage;
  ui.Image? _targetImage;
  ui.Image? _backImage;

  // Keys for the RepaintBoundary captures
  final GlobalKey _currentKey = GlobalKey();
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey _backKey = GlobalKey();

  // Animation
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.decelerate,
  );

  // Dragging the page toward the edge it turns over turns it forward.
  PageTurnDragProgress? _drag;
  bool _dragging = false;

  /// Whether the turn on screen follows a drag: the controller's value is
  /// then the turn's progress itself, with no curve.
  bool _dragTurn = false;

  /// The page area's size when the drag began.
  Size _dragArea = Size.zero;

  /// The turning page's length along the turn when the drag began, in
  /// logical pixels.
  double _dragPageLength = 0;

  /// How far the finger is from the hinge along the turning page, in logical
  /// pixels: negative past it.
  double _fingerFromHinge = 0;

  /// Where the drag holds the page: how far from the hinge, in logical pixels,
  /// the spot the turn keeps under the finger lay before the turn. While the
  /// page lies flat it follows the finger away from the hinge, up to the free
  /// edge, so the turn starts from wherever the finger starts toward the hinge.
  double _heldFromHinge = 0;

  /// How far the finger has moved toward the hinge from where it holds the
  /// page, in logical pixels: 0 or less while the page lies flat.
  double get _travel => _heldFromHinge - _fingerFromHinge;

  /// The finger start of the turn on screen: where its drag holds the page, or
  /// the standard finger start (the free edge) for Next and Previous.
  double _fingerStart = PageTurnInputs.standardFingerStart;

  /// Whether a drag that ended before its images were captured completes.
  bool? _releasePending;

  /// A release faster than this, in logical pixels per second, decides the
  /// turn by its direction: toward the hinge completes it.
  static const double _flickSpeed = 700;

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    _disposeImages();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image capture
  // ---------------------------------------------------------------------------

  /// Captures the pages the turn shows and hands them to the turn: the current
  /// and target pages, and on the Book tab the left-hand page of the later
  /// spread. The left-hand page's turn shows only its two sides: that
  /// left-hand page and the target page.
  ///
  /// Returns whether the turn has them all and the widget is still here; if
  /// not, the images captured are disposed, also when a capture throws.
  Future<bool> _captureImages() async {
    if (!mounted) return false;
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    Future<ui.Image?> capture(GlobalKey key) async {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      return boundary?.toImage(pixelRatio: pixelRatio);
    }

    ui.Image? current, target, back;
    var handedOver = false;
    try {
      if (!_leftPage) current = await capture(_currentKey);
      target = await capture(_targetKey);
      if (widget.book) back = await capture(_backKey);
      handedOver =
          mounted &&
          (_leftPage || current != null) &&
          target != null &&
          (!widget.book || back != null);
      if (handedOver) {
        _currentImage = current;
        _targetImage = target;
        _backImage = back;
      }
      return handedOver;
    } finally {
      if (!handedOver) {
        current?.dispose();
        target?.dispose();
        back?.dispose();
      }
    }
  }

  void _disposeImages() {
    _currentImage?.dispose();
    _targetImage?.dispose();
    _backImage?.dispose();
    _currentImage = null;
    _targetImage = null;
    _backImage = null;
  }

  // ---------------------------------------------------------------------------
  // Next and Previous
  // ---------------------------------------------------------------------------

  Future<void> _turnForward() async {
    if (_phase != _Phase.idle || _currentIndex >= _pages.length - 1) return;
    _fingerStart = PageTurnInputs.standardFingerStart;
    _isForward = true;
    _targetIndex = _currentIndex + 1;
    await _runPageTurn();
  }

  Future<void> _turnBackward() async {
    if (_phase != _Phase.idle || _currentIndex <= 0) return;
    _fingerStart = PageTurnInputs.standardFingerStart;
    _isForward = false;
    _targetIndex = _currentIndex - 1;
    await _runPageTurn();
  }

  /// Full capture → animate → commit lifecycle.
  Future<void> _runPageTurn() async {
    // 1. Render both pages for image capture.
    setState(() => _phase = _Phase.capturing);
    await SchedulerBinding.instance.endOfFrame;

    // 2. Capture the pages the turn shows. If a capture throws, the turn
    // ends and the error is passed on.
    final bool captured;
    try {
      captured = await _captureImages();
    } catch (_) {
      _cleanup();
      rethrow;
    }
    if (!captured) {
      _cleanup();
      return;
    }

    // 3. Animate.
    setState(() => _phase = _Phase.animating);
    await _controller.forward();

    if (!mounted) return;

    // 4. Commit page change.
    setState(() => _currentIndex = _targetIndex);
    _cleanup();
  }

  /// Ends the turn: disposes its images and clears the drag, and while the
  /// widget is here shows the current page again.
  void _cleanup() {
    _disposeImages();
    _drag = null;
    _dragging = false;
    _dragTurn = false;
    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _leftPage = false;
    });
    _controller.reset();
  }

  // ---------------------------------------------------------------------------
  // Dragging the page
  // ---------------------------------------------------------------------------

  /// The part of a drag's [delta] that moves toward the hinge: up for the top
  /// edge, down for the bottom, left for the left and right for the right.
  double _towardHinge(double delta) =>
      _edge.requiresCoordinateFlip ? delta : -delta;

  /// How far [position] in the page area is from the hinge along the turning
  /// page, in logical pixels, negative past it: on the Book tab from the spine
  /// in the middle, otherwise from the far side of the area for the bottom and
  /// right edges.
  double _fromHinge(Offset position) {
    final vertical = _edge.isVerticalAxis;
    final along = vertical ? position.dy : position.dx;
    final areaLength = vertical ? _dragArea.height : _dragArea.width;
    if (widget.book) {
      return _leftPage ? _dragPageLength - along : along - _dragPageLength;
    }
    return _edge.requiresCoordinateFlip ? areaLength - along : along;
  }

  /// Holds the page [fromHinge] logical pixels from the hinge: the finger
  /// start there, as a share of the page's length from its free edge, within
  /// the accepted range.
  void _holdAt(double fromHinge) {
    _heldFromHinge = fromHinge;
    _fingerStart = (1 - fromHinge / _dragPageLength).clamp(
      PageTurnInputs.minFingerStart,
      PageTurnInputs.maxFingerStart,
    );
  }

  /// Starts a drag in the page [area], whose turning page is [pageLength]
  /// logical pixels long.
  void _onDragStart(DragStartDetails details, Size area, double pageLength) {
    if (_phase != _Phase.idle) return;
    // On the Book tab a drag on the left-hand page turns it back.
    final leftPage = widget.book && details.localPosition.dx < pageLength;
    final targetIndex = leftPage ? _currentIndex - 1 : _currentIndex + 1;
    if (targetIndex < 0 || targetIndex >= _pages.length) return;
    _leftPage = leftPage;
    _dragArea = area;
    _dragPageLength = pageLength;
    _fingerFromHinge = _fromHinge(details.localPosition);
    _holdAt(_fingerFromHinge);
    _dragging = true;
    _dragTurn = true;
    _releasePending = null;
    _isForward = !leftPage;
    _targetIndex = targetIndex;
    _startDragTurn();
  }

  /// Captures both pages, then lets the drag drive the turn.
  Future<void> _startDragTurn() async {
    setState(() => _phase = _Phase.capturing);
    await SchedulerBinding.instance.endOfFrame;
    // If a capture throws, the turn ends and the error is passed on.
    final bool captured;
    try {
      captured = await _captureImages();
    } catch (_) {
      _cleanup();
      rethrow;
    }
    if (!captured) {
      _cleanup();
      return;
    }
    _drag = PageTurnDragProgress(
      pageLength: _dragPageLength,
      style: _style,
      completionAngle: _completionAngle,
      fingerStart: _fingerStart,
    );
    setState(() => _phase = _Phase.animating);
    _followFinger();
    final completes = _releasePending;
    if (completes != null) _release(completes);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _fingerFromHinge = _fromHinge(details.localPosition);
    // Further from the hinge than where it holds the page, the finger moves
    // the held spot with it, up to the free edge; the page lies flat, and is
    // drawn with the finger start there.
    if (_fingerFromHinge > _heldFromHinge) {
      setState(() => _holdAt(math.min(_fingerFromHinge, _dragPageLength)));
    }
    _followFinger();
  }

  /// Sets the turn to the progress that keeps the held spot under the finger,
  /// with the drag progress for where the page is now held.
  void _followFinger() {
    var drag = _drag;
    if (drag == null || _phase != _Phase.animating) return;
    if (_travel <= 0) {
      _controller.value = 0;
      return;
    }
    if (drag.fingerStart != _fingerStart) {
      drag = _drag = PageTurnDragProgress(
        pageLength: _dragPageLength,
        style: _style,
        completionAngle: _completionAngle,
        fingerStart: _fingerStart,
      );
    }
    _controller.value = drag.progressFor(_travel, current: _controller.value);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    // A flick decides by its direction; otherwise the turn completes once the
    // finger has come half a page.
    final velocity = _towardHinge(details.primaryVelocity ?? 0);
    final completes = velocity.abs() > _flickSpeed
        ? velocity > 0
        : _travel >= _dragPageLength / 2;
    if (_drag != null && _phase == _Phase.animating) {
      _release(completes);
    } else {
      _releasePending = completes;
    }
  }

  /// Runs the rest of the turn, or back, from where the drag left it.
  Future<void> _release(bool completes) async {
    _releasePending = null;
    if (completes) {
      await _controller.animateTo(1, curve: Curves.decelerate);
    } else {
      await _controller.animateBack(0, curve: Curves.decelerate);
    }
    if (!mounted) return;
    if (completes) setState(() => _currentIndex = _targetIndex);
    _cleanup();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: _Palette.muted);
    final idle = _phase == _Phase.idle;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Text(
                widget.book
                    ? 'Drag the right-hand page from anywhere toward the spine '
                          'to turn forward, or the left-hand page to turn '
                          'back.'
                    : 'Choose the hinge, then drag the page from anywhere '
                          'toward it.',
                style: small,
                textAlign: TextAlign.center,
              ),
              if (!widget.book) ...[
                const SizedBox(height: 8),
                SegmentedButton<PageTurnEdge>(
                  segments: const [
                    ButtonSegment(value: PageTurnEdge.top, label: Text('Top')),
                    ButtonSegment(
                      value: PageTurnEdge.bottom,
                      label: Text('Bottom'),
                    ),
                    ButtonSegment(
                      value: PageTurnEdge.left,
                      label: Text('Left'),
                    ),
                    ButtonSegment(
                      value: PageTurnEdge.right,
                      label: Text('Right'),
                    ),
                  ],
                  selected: {_hinge},
                  showSelectedIcon: false,
                  // The hinge changes between turns, like Previous and Next.
                  onSelectionChanged: idle
                      ? (hinges) => setState(() => _hinge = hinges.single)
                      : null,
                  // The chosen hinge stays marked while a turn disables the
                  // choice.
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? _Palette.light
                          : null,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? _Palette.desk
                          : states.contains(WidgetState.disabled)
                          ? _Palette.muted
                          : _Palette.light,
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: _Palette.muted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Page area, with room around it across the turn: a turning page is
        // seen larger the higher it rises, up to a third larger.
        Expanded(
          child: LayoutBuilder(
            builder: (context, outer) {
              final across = _edge.isVerticalAxis
                  ? outer.maxWidth
                  : outer.maxHeight;
              final room = across / 10;
              return Padding(
                padding: _edge.isVerticalAxis
                    ? EdgeInsets.symmetric(horizontal: room, vertical: 8)
                    : EdgeInsets.symmetric(horizontal: 16, vertical: room),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = _edge.isVerticalAxis;
                    final area = constraints.biggest;
                    // On the Book tab the turning page is the right half.
                    final pageLength = widget.book
                        ? area.width / 2
                        : vertical
                        ? area.height
                        : area.width;
                    void start(DragStartDetails details) =>
                        _onDragStart(details, area, pageLength);
                    // The page fills its area in every phase, so the turning
                    // page's edge is drawn where the finger took it.
                    final page = SizedBox.expand(child: _buildForPhase());
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: vertical ? null : start,
                      onHorizontalDragUpdate: vertical ? null : _onDragUpdate,
                      onHorizontalDragEnd: vertical ? null : _onDragEnd,
                      onVerticalDragStart: vertical ? start : null,
                      onVerticalDragUpdate: vertical ? _onDragUpdate : null,
                      onVerticalDragEnd: vertical ? _onDragEnd : null,
                      child: widget.book
                          ? _buildSpread(page, pageLength)
                          : page,
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Page indicator and Previous / Next
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _currentIndex > 0 && idle ? _turnBackward : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              Expanded(
                child: Text(
                  '${(idle ? _currentIndex : _targetIndex) + 1} / '
                  '${_pages.length}',
                  style: small,
                  textAlign: TextAlign.center,
                ),
              ),
              FilledButton.icon(
                onPressed: _currentIndex < _pages.length - 1 && idle
                    ? _turnForward
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForPhase() {
    switch (_phase) {
      // Both pages rendered with RepaintBoundary for image capture.
      // Current page on top so the screen doesn't visually flash.
      case _Phase.capturing:
        return Stack(
          children: [
            // On the Book tab, the turning page's back: the left-hand page of
            // the later spread.
            if (widget.book)
              Positioned.fill(
                child: RepaintBoundary(
                  key: _backKey,
                  child: _buildLeftPage(math.max(_currentIndex, _targetIndex)),
                ),
              ),
            Positioned.fill(
              child: RepaintBoundary(
                key: _targetKey,
                child: _buildPage(_targetIndex),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                key: _currentKey,
                child: _buildPage(_currentIndex),
              ),
            ),
          ],
        );

      // Hand captured images to PageTurnAnimation.
      case _Phase.animating:
        // The left-hand page turns over this one, which stays as it is.
        if (_leftPage) return _buildPage(_currentIndex);
        return Stack(
          children: [
            // Bottom layer: the destination page.
            Positioned.fill(child: _buildPage(_targetIndex)),

            // Forward: current page turns away, revealing the destination.
            if (_isForward && _currentImage != null)
              PageTurnAnimation(
                image: _currentImage!,
                animation: _dragTurn ? _controller : _curve,
                direction: PageTurnDirection.forward,
                edge: _edge,
                backImage: _backImage,
                completionAngle: _completionAngle,
                fingerStart: _fingerStart,
                style: _style,
              ),

            // Backward: static current-page image hides the destination,
            // then the target-page image turns into view on top.
            if (!_isForward) ...[
              if (_currentImage != null)
                Positioned.fill(
                  child: RawImage(image: _currentImage, fit: BoxFit.fill),
                ),
              if (_targetImage != null)
                PageTurnAnimation(
                  image: _targetImage!,
                  animation: _curve,
                  direction: PageTurnDirection.backward,
                  edge: _edge,
                  backImage: _backImage,
                  completionAngle: _completionAngle,
                  fingerStart: _fingerStart,
                  style: _style,
                ),
            ],
          ],
        );

      case _Phase.idle:
        return _buildPage(_currentIndex);
    }
  }

  /// The Book tab's spread: the left-hand page and the right-hand [page],
  /// each [pageLength] logical pixels wide. The half whose page turns is drawn
  /// last, so the page turns over the other half.
  Widget _buildSpread(Widget page, double pageLength) {
    final left = Positioned(
      key: const ValueKey('left'),
      left: 0,
      top: 0,
      bottom: 0,
      width: pageLength,
      child: _buildLeftHalf(),
    );
    final right = Positioned(
      key: const ValueKey('right'),
      left: pageLength,
      top: 0,
      bottom: 0,
      width: pageLength,
      child: page,
    );
    return Stack(children: _leftPage ? [right, left] : [left, right]);
  }

  /// The Book tab's left-hand page, with the spine at its right: the back of
  /// the page turned last. While a page turns, the one under it: the earlier
  /// spread's. When it is itself dragged back, it turns over the spine.
  Widget _buildLeftHalf() {
    final animating = _phase == _Phase.animating;
    final leftPage = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _Palette.spine, width: 2)),
      ),
      child: _buildLeftPage(
        animating ? math.min(_currentIndex, _targetIndex) : _currentIndex,
      ),
    );
    final front = _backImage;
    if (!animating || !_leftPage || front == null) return leftPage;
    return Stack(
      children: [
        Positioned.fill(child: leftPage),
        PageTurnAnimation(
          image: front,
          backImage: _targetImage,
          animation: _controller,
          direction: PageTurnDirection.forward,
          edge: _edge,
          completionAngle: _completionAngle,
          fingerStart: _fingerStart,
          style: _style,
        ),
      ],
    );
  }

  Widget _buildPage(int index) => _buildContent(_pages[index]);

  /// The Book tab's left-hand page of a spread: the back of the page before
  /// it, or before the first page the plain inside of the cover.
  Widget _buildLeftPage(int spread) => spread == 0
      ? ColoredBox(color: _style.backgroundColor)
      : _buildContent(_backs[spread - 1]);

  Widget _buildContent(BookPage page) {
    return ColoredBox(
      color: page.color,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: widget.book ? 320 : 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(page.icon, size: 56, color: Colors.brown.shade400),
                  const SizedBox(height: 20),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.brown.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
