import 'package:flutter/material.dart';

/// [BoardDragTarget] is a [DragTarget] that carries the index information of
/// the child.
///
/// The size of the [BoardDragTarget] will become zero when it start dragging.
///
class BoardDragTarget extends StatefulWidget {
  final int index;
  final Widget child;
  final Axis direction;

  final GlobalObjectKey _indexGlobalKey;

  /// Called when dragTarget is being dragging.
  final void Function(Widget, int, Size?) onDragStarted;

  final void Function() onDragEnded;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [BoardDragTarget].
  final bool Function(int? toAccept) onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final void Function(int)? onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(int?)? onLeave;

  BoardDragTarget({
    Key? key,
    required this.child,
    required this.direction,
    required this.index,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onWillAccept,
    this.onAccept,
    this.onLeave,
  })  : _indexGlobalKey = GlobalObjectKey(child.key!),
        super(key: key);

  @override
  State<BoardDragTarget> createState() => _BoardDragTargetState();
}

class _BoardDragTargetState extends State<BoardDragTarget> {
  /// Return the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<int>(
      builder: _buildDraggableWidget,
      onWillAccept: widget.onWillAccept,
      onAccept: widget.onAccept,
      onLeave: widget.onLeave,
    );

    dragTarget = KeyedSubtree(key: widget._indexGlobalKey, child: dragTarget);
    return dragTarget;
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    List<int?> acceptedCandidates,
    List<dynamic> rejectedCandidates,
  ) {
    Widget feedbackBuilder = Builder(builder: (BuildContext context) {
      BoxConstraints contentSizeConstraints =
          BoxConstraints.loose(_draggingFeedbackSize!);
      return _buildDraggableFeedback(
        context,
        contentSizeConstraints,
        // Container(color: Colors.red, width: 100, height: 50),
        widget.child,
      );
    });

    return LongPressDraggable<int>(
      maxSimultaneousDrags: 1,
      axis: widget.direction,
      data: widget.index,
      ignoringFeedbackSemantics: false,
      feedback: feedbackBuilder,
      childWhenDragging: _buildNoSizedDraggingWidget(widget.child),
      onDragStarted: () {
        _draggingFeedbackSize = widget._indexGlobalKey.currentContext?.size;
        widget.onDragStarted(widget.child, widget.index, _draggingFeedbackSize);
      },
      dragAnchorStrategy: childDragAnchorStrategy,
      // When the drag ends inside a DragTarget widget, the drag
      // succeeds, and we reorder the widget into position appropriately.
      onDragCompleted: widget.onDragEnded,
      // When the drag does not end inside a DragTarget widget, the
      // drag fails, but we still reorder the widget to the last position it
      // had been dragged to.
      onDraggableCanceled: (Velocity velocity, Offset offset) =>
          widget.onDragEnded(),
      child: widget.child,
    );
  }

  Widget _buildNoSizedDraggingWidget(Widget child) {
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0,
        child: SizedBox(width: 0, height: 0, child: child),
      ),
    );
  }

  Widget _buildDraggableFeedback(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return Transform(
      transform: Matrix4.rotationZ(0),
      alignment: FractionalOffset.topLeft,
      child: Material(
        elevation: 3.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: ConstrainedBox(constraints: constraints, child: child),
      ),
    );
  }
}

class DragAnimationController {
  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;

  // How long an animation to scroll to an off-screen element in the
  // list takes.
  final Duration scrollAnimationDuration;

  // This controls the entrance of the dragging widget into a new place.
  late AnimationController entranceController;

  // This controls the 'ghost' of the dragging widget, which is left behind
  // where the widget used to be.
  late AnimationController ghostController;

  DragAnimationController({
    required this.reorderAnimationDuration,
    required this.scrollAnimationDuration,
    required TickerProvider vsync,
    required void Function(AnimationStatus) entranceAnimateStatusChanged,
  }) {
    entranceController = AnimationController(
        value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    ghostController = AnimationController(
        value: 0, vsync: vsync, duration: reorderAnimationDuration);
    entranceController.addStatusListener(entranceAnimateStatusChanged);
  }

  bool get isEntranceAnimationCompleted => entranceController.isCompleted;

  void startDargging() {
    entranceController.value = 1.0;
  }

  void animateToNext() {
    ghostController.reverse(from: 1.0);
    entranceController.forward(from: 0.0);
  }

  void performReorderAnimation() {
    ghostController.reverse(from: 0.1);
    entranceController.reverse(from: 0.0);
  }

  void dispose() {
    entranceController.dispose();
    ghostController.dispose();
  }
}

class DragState {
  // The member of widget.children currently being dragged.
  //
  // Null if no drag is underway.
  Widget? draggingWidget;

  // The last computed size of the feedback widget being dragged.
  Size? draggingFeedbackSize = Size.zero;

  // The location that the dragging widget occupied before it started to drag.
  int dragStartIndex = -1;

  // The index that the dragging widget most recently left.
  // This is used to show an animation of the widget's position.
  int ghostIndex = -1;

  // The index that the dragging widget currently occupies.
  int currentIndex = -1;

  // The widget to move the dragging widget too after the current index.
  int nextIndex = 0;

  // Whether or not we are currently scrolling this view to show a widget.
  bool scrolling = false;

  // The additional margin to place around a computed drop area.
  static const double _dropAreaMargin = 0.0;

  Size get dropAreaSize {
    if (draggingFeedbackSize == null) {
      return Size.zero;
    }
    return draggingFeedbackSize! +
        const Offset(_dropAreaMargin, _dropAreaMargin);
  }

  void startDragging(Widget draggingWidget, int draggingWidgetIndex,
      Size? draggingWidgetSize) {
    this.draggingWidget = draggingWidget;
    ghostIndex = draggingWidgetIndex;
    dragStartIndex = draggingWidgetIndex;
    currentIndex = draggingWidgetIndex;
    draggingFeedbackSize = draggingWidgetSize;
  }

  void endDragging() {
    dragStartIndex = -1;
    ghostIndex = -1;
    currentIndex = -1;
    draggingWidget = null;
  }

  /// When the ghostIndex and currentIndex are the same, it means the dragging
  /// widget did move to the destination location.
  void endGhosting() {
    ghostIndex = currentIndex;
  }

  /// The dragging widget overlaps with the ghost widget.
  bool isGhosting() {
    return currentIndex != ghostIndex;
  }

  bool isGhostAboveDragTarget() {
    return currentIndex > ghostIndex;
  }

  bool isGhostBelowDragTarget() {
    return currentIndex < ghostIndex;
  }

  bool didDragTargetMoveToNext() {
    return currentIndex == nextIndex;
  }

  /// Set the currentIndex to nextIndex
  void moveDragTargetToNext() {
    currentIndex = nextIndex;
  }

  void updateNextIndex(int index) {
    assert(index >= 0);

    nextIndex = index;
  }

  bool isNotDragging() {
    return dragStartIndex == -1;
  }

  /// When the _dragStartIndex less than the _currentIndex, it means the
  /// dragTarget is going down to the end of the list.
  bool isDragTargetMovingDown() {
    return dragStartIndex < currentIndex;
  }

  /// The index represents the widget original index of the list.
  int calculateShiftedIndex(int index) {
    int shiftedIndex = index;
    if (index == dragStartIndex) {
      shiftedIndex = ghostIndex;
    } else if (index > dragStartIndex && index <= ghostIndex) {
      /// ghost move up
      shiftedIndex--;
    } else if (index < dragStartIndex && index >= ghostIndex) {
      /// ghost move down
      shiftedIndex++;
    }
    return shiftedIndex;
  }
}
