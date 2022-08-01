import 'package:flutter/material.dart';

abstract class DragTargetData {
  int get draggingIndex;
}

abstract class ReorderDraggableTargetBuilder {
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
  );
}

typedef DragTargetOnStarted = void Function(Widget, int, Size?);
typedef DragTargetOnEnded<T extends DragTargetData> = void Function(
    T dragTargetData);

/// [ReorderDragTarget] is a [DragTarget] that carries the index information of
/// the child.
///
/// The size of the [ReorderDragTarget] will become zero when it start dragging.
///
class ReorderDragTarget<T extends DragTargetData> extends StatefulWidget {
  final Widget child;
  final T dragTargetData;

  final GlobalObjectKey _indexGlobalKey;

  /// Called when dragTarget is being dragging.
  final DragTargetOnStarted onDragStarted;

  final DragTargetOnEnded<T> onDragEnded;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// [toAccept] represents the dragTarget index, which is the value passed in
  /// when creating the [ReorderDragTarget].
  final bool Function(T dragTargetData) onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final void Function(T dragTargetData)? onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final void Function(T dragTargetData)? onLeave;

  final ReorderDraggableTargetBuilder? draggableTargetBuilder;

  ReorderDragTarget({
    Key? key,
    required this.child,
    required this.dragTargetData,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onWillAccept,
    this.onAccept,
    this.onLeave,
    this.draggableTargetBuilder,
  })  : _indexGlobalKey = GlobalObjectKey(child.key!),
        super(key: key);

  @override
  State<ReorderDragTarget<T>> createState() => _ReorderDragTargetState<T>();
}

class _ReorderDragTargetState<T extends DragTargetData>
    extends State<ReorderDragTarget<T>> {
  /// Return the dragTarget's size
  Size? _draggingFeedbackSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    Widget dragTarget = DragTarget<T>(
      builder: _buildDraggableWidget,
      onWillAccept: (dragTargetData) {
        assert(dragTargetData != null);
        if (dragTargetData == null) return false;
        return widget.onWillAccept(dragTargetData);
      },
      onAccept: widget.onAccept,
      onLeave: (dragTargetData) {
        assert(dragTargetData != null);
        if (dragTargetData != null) {
          widget.onLeave?.call(dragTargetData);
        }
      },
    );

    dragTarget = KeyedSubtree(key: widget._indexGlobalKey, child: dragTarget);
    return dragTarget;
  }

  Widget _buildDraggableWidget(
    BuildContext context,
    List<T?> acceptedCandidates,
    List<dynamic> rejectedCandidates,
  ) {
    Widget feedbackBuilder = Builder(builder: (BuildContext context) {
      BoxConstraints contentSizeConstraints =
          BoxConstraints.loose(_draggingFeedbackSize!);
      return _buildDraggableFeedback(
        context,
        contentSizeConstraints,
        widget.child,
      );
    });

    final draggableWidget = widget.draggableTargetBuilder?.build(
          context,
          widget.child,
          widget.onDragStarted,
          widget.onDragEnded,
        ) ??
        LongPressDraggable<DragTargetData>(
          maxSimultaneousDrags: 1,
          data: widget.dragTargetData,
          ignoringFeedbackSemantics: false,
          feedback: feedbackBuilder,
          childWhenDragging: IgnorePointerWidget(child: widget.child),
          onDragStarted: () {
            _draggingFeedbackSize = widget._indexGlobalKey.currentContext?.size;
            widget.onDragStarted(
              widget.child,
              widget.dragTargetData.draggingIndex,
              _draggingFeedbackSize,
            );
          },
          dragAnchorStrategy: childDragAnchorStrategy,

          /// When the drag ends inside a DragTarget widget, the drag
          /// succeeds, and we reorder the widget into position appropriately.
          onDragCompleted: () {
            widget.onDragEnded(widget.dragTargetData);
          },

          /// When the drag does not end inside a DragTarget widget, the
          /// drag fails, but we still reorder the widget to the last position it
          /// had been dragged to.
          onDraggableCanceled: (Velocity velocity, Offset offset) =>
              widget.onDragEnded(widget.dragTargetData),
          child: widget.child,
        );

    return draggableWidget;
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

  // This controls the 'phantom' of the dragging widget, which is left behind
  // where the widget used to be.
  late AnimationController phantomController;

  DragAnimationController({
    required this.reorderAnimationDuration,
    required this.scrollAnimationDuration,
    required TickerProvider vsync,
    required void Function(AnimationStatus) entranceAnimateStatusChanged,
  }) {
    entranceController = AnimationController(
        value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    phantomController = AnimationController(
        value: 0, vsync: vsync, duration: reorderAnimationDuration);
    entranceController.addStatusListener(entranceAnimateStatusChanged);
  }

  bool get isEntranceAnimationCompleted => entranceController.isCompleted;

  void startDargging() {
    entranceController.value = 1.0;
  }

  void animateToNext() {
    phantomController.reverse(from: 1.0);
    entranceController.forward(from: 0.0);
  }

  void reverseAnimation() {
    phantomController.reverse(from: 0.1);
    entranceController.reverse(from: 0.0);
  }

  void dispose() {
    entranceController.dispose();
    phantomController.dispose();
  }
}

class IgnorePointerWidget extends StatelessWidget {
  final Widget? child;
  const IgnorePointerWidget({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0,
        child: SizedBox(width: 0, height: 0, child: child),
      ),
    );
  }
}

class PhantomWidget extends StatelessWidget {
  final Widget? child;
  final double opacity;
  const PhantomWidget({
    this.child,
    this.opacity = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }
}

class PhantomAnimateContorller {
  // How long an animation to reorder an element in the list takes.
  final Duration reorderAnimationDuration;
  late AnimationController appearController;
  late AnimationController disappearController;

  PhantomAnimateContorller({
    required TickerProvider vsync,
    required this.reorderAnimationDuration,
    required void Function(AnimationStatus) appearAnimateStatusChanged,
  }) {
    appearController = AnimationController(
        value: 1.0, vsync: vsync, duration: reorderAnimationDuration);
    disappearController = AnimationController(
        value: 0, vsync: vsync, duration: reorderAnimationDuration);
    appearController.addStatusListener(appearAnimateStatusChanged);
  }

  bool get isAppearAnimationCompleted => appearController.isCompleted;

  void animateToNext() {
    disappearController.reverse(from: 1.0);
    appearController.forward(from: 0.0);
  }

  void performReorderAnimation() {
    disappearController.reverse(from: 0.1);
    appearController.reverse(from: 0.0);
  }

  void dispose() {
    appearController.dispose();
    disappearController.dispose();
  }
}
