part of 'board_list.dart';

typedef OnContentDragStarted = void Function(int index);
typedef OnContentDragEnded = void Function();
typedef OnContentReorder = void Function(int fromIndex, int toIndex);

class BoardListContentWidget extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnContentDragStarted? onDragStarted;
  final OnContentReorder onReorder;
  final OnContentDragEnded? onDragEnded;
  final OnDeleted onDeleted;
  final OnInserted onInserted;
  final EdgeInsets? padding;
  final Axis direction = Axis.vertical;
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;

  const BoardListContentWidget({
    Key? key,
    this.header,
    this.footer,
    required this.children,
    this.scrollController,
    required this.config,
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onDeleted,
    required this.onInserted,
    // ignore: unused_element
    this.padding,
  }) : super(key: key);

  @override
  State<BoardListContentWidget> createState() => BoardListContentWidgetState();
}

class BoardListContentWidgetState extends State<BoardListContentWidget>
    with BoardMixin, TickerProviderStateMixin<BoardListContentWidget> {
  // Controls scrolls and measures scroll progress.
  late ScrollController _scrollController;
  ScrollPosition? _attachedScrollPosition;
  // Whether or not we are currently scrolling this view to show a widget.
  bool _scrolling = false;

  late DragAnimationController _animationController;
  late DragState _dragState;

  @override
  void initState() {
    _dragState = DragState();
    _animationController = DragAnimationController(
      reorderAnimationDuration: widget.config.reorderAnimationDuration,
      scrollAnimationDuration: widget.config.scrollAnimationDuration,
      entranceAnimateStatusChanged: _onEntranceAnimationStatusChanged,
      vsync: this,
    );

    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_attachedScrollPosition != null) {
      _scrollController.detach(_attachedScrollPosition!);
      _attachedScrollPosition = null;
    }

    _scrollController = widget.scrollController ??
        PrimaryScrollController.of(context) ??
        ScrollController();

    if (_scrollController.hasClients) {
      _attachedScrollPosition = Scrollable.of(context)?.position;
    } else {
      _attachedScrollPosition = null;
    }

    if (_attachedScrollPosition != null) {
      _scrollController.attach(_attachedScrollPosition!);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    if (widget.header != null) {
      children.add(widget.header!);
    }

    for (int i = 0; i < widget.children.length; i += 1) {
      children.add(_wrap(widget.children[i], i));
    }
    if (widget.footer != null) {
      children.add(widget.footer!);
    }

    return _wrapScrollView(
      child: _wrapContainer(children),
    );
  }

  @override
  void dispose() {
    if (_attachedScrollPosition != null) {
      _scrollController.detach(_attachedScrollPosition!);
      _attachedScrollPosition = null;
    }

    _animationController.dispose();
    super.dispose();
  }

  void _onEntranceAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _requestAnimationToNextIndex();
      });
    }
  }

  void _requestAnimationToNextIndex({bool isAcceptingNewTarget = false}) {
    /// Update the dragState and animate to the next index if the current
    /// dragging animation is completed. Otherwise, it will get called again
    /// when the animation finishs.

    if (_animationController.isEntranceAnimationCompleted) {
      _dragState.endGhosting();

      if (!isAcceptingNewTarget && _dragState.didDragTargetMoveToNext()) {
        return;
      }

      _dragState.moveDragTargetToNext();
      _animationController.animateToNext();
    }
  }

  /// [child]: the child will be wrapped with dartTarget
  /// [childIndex]: the index of the child in a list
  Widget _wrap(Widget child, int childIndex) {
    return Builder(builder: (context) {
      final dragTarget = _buildDragTarget(context, child, childIndex);
      int shiftedIndex = childIndex;

      /// Calculate the shiftedIndex if it's ghosting
      if (_dragState.isGhosting()) {
        shiftedIndex = _dragState.calculateShiftedIndex(childIndex);
      }

      final currentIndex = _dragState.currentIndex;
      final ghostIndex = _dragState.ghostIndex;

      if (shiftedIndex == currentIndex || childIndex == ghostIndex) {
        Widget dragSpace = _dragState.draggingWidget == null
            ? SizedBox.fromSize(size: _dragState.dropAreaSize)
            : Opacity(
                opacity: widget.config.draggingWidgetOpacity,
                child: _dragState.draggingWidget,
              );

        /// Return the dragTarget it is not start dragging. The size of the
        /// dragTarget will be the same as the child in the column/row.
        ///
        /// The dragTarget size will become zero if it start dragging. Check the
        /// [BoardDragTarget] for more details.
        if (_dragState.isNotDragging()) {
          debugPrint('index:$childIndex is not dragging');
          return _buildDraggingContainer(children: [dragTarget]);
        }

        /// Determine the size of the drop area to show under the dragging widget.

        final feedbackSize = _dragState.draggingFeedbackSize;
        Widget entranceSpacing = _makeAppearingWidget(dragSpace, feedbackSize);
        Widget ghostSpacing = _makeDisappearingWidget(dragSpace, feedbackSize);

        ///
        if (_dragState.isGhostAboveDragTarget()) {
          //the ghost is moving down, i.e. the tile below the ghost is moving up
          debugPrint('index:$childIndex item moving up / ghost moving down');
          if (shiftedIndex == currentIndex && childIndex == ghostIndex) {
            return _buildDraggingContainer(children: [
              ghostSpacing,
              dragTarget,
              entranceSpacing,
            ]);
          } else if (shiftedIndex == currentIndex) {
            return _buildDraggingContainer(children: [
              dragTarget,
              entranceSpacing,
            ]);
          } else if (childIndex == ghostIndex) {
            return _buildDraggingContainer(
                children: shiftedIndex <= childIndex
                    ? [dragTarget, ghostSpacing]
                    : [ghostSpacing, dragTarget]);
          }
        }

        ///
        if (_dragState.isGhostBelowDragTarget()) {
          //the ghost is moving up, i.e. the tile above the ghost is moving down
          debugPrint('index:$childIndex item moving down / ghost moving up');
          if (shiftedIndex == currentIndex && childIndex == ghostIndex) {
            return _buildDraggingContainer(children: [
              entranceSpacing,
              dragTarget,
              ghostSpacing,
            ]);
          } else if (shiftedIndex == currentIndex) {
            return _buildDraggingContainer(children: [
              entranceSpacing,
              dragTarget,
            ]);
          } else if (childIndex == ghostIndex) {
            return _buildDraggingContainer(
                children: shiftedIndex >= childIndex
                    ? [ghostSpacing, dragTarget]
                    : [dragTarget, ghostSpacing]);
          }
        }

        assert(!_dragState.isGhosting());

        List<Widget> children = [];
        if (_dragState.isDragTargetMovingDown()) {
          children.addAll([dragTarget, entranceSpacing]);
        } else {
          children.addAll([entranceSpacing, dragTarget]);
        }
        return _buildDraggingContainer(children: children);
      }

      //we still wrap dragTarget with a container so that widget's depths are the same and it prevent's layout alignment issue
      return _buildDraggingContainer(children: [dragTarget]);
    });
  }

  Widget _makeAppearingWidget(Widget child, Size? feedbackSize) {
    return makeAppearingWidget(
      child,
      _animationController.entranceController,
      feedbackSize,
      widget.direction,
    );
  }

  Widget _makeDisappearingWidget(Widget child, Size? feedbackSize) {
    return makeDisappearingWidget(
      child,
      _animationController.ghostController,
      feedbackSize,
      widget.direction,
    );
  }

  BoardDragTarget _buildDragTarget(
      BuildContext builderContext, Widget child, int childIndex) {
    return BoardDragTarget(
      draggingData: DraggingData(dragIndex: childIndex, boardList: widget),
      onDragStarted: (draggingWidget, draggingData, size) {
        setState(() {
          _dragState.startDragging(
              draggingWidget, draggingData.dragIndex, size);
          _animationController.startDargging();
        });
        widget.onDragStarted?.call(draggingData.dragIndex);
      },
      onDragEnded: () {
        setState(() {
          _onReordered(
            _dragState.dragStartIndex,
            _dragState.currentIndex,
          );
          _dragState.endDragging();
          widget.onDragEnded?.call();
        });
      },
      onWillAccept: (DraggingData? draggingData) {
        if (widget != draggingData?.boardList) {
          return _onWillAcceptNewItem(builderContext, draggingData, childIndex);
        } else {
          return _onWillAccept(builderContext, draggingData, childIndex);
        }
      },
      child: child,
    );
  }

  bool _onWillAcceptNewItem(
      BuildContext context, DraggingData? draggingData, int childIndex) {
    if (draggingData != null) {
      debugPrint(
          'move ${draggingData.boardList}:${draggingData.dragIndex} data to $widget:$childIndex');

      // final item = draggingData.boardList.onDeleted(draggingData.dragIndex);
      // widget.onInserted(childIndex, item);
    }

    return false;
  }

  bool _onWillAccept(
      BuildContext context, DraggingData? draggingData, int childIndex) {
    /// The [willAccept] will be true if the dargTarget is the widget that gets
    /// dragged and it is dragged on top of the other dragTargets.
    final toAcceptIndex = draggingData?.dragIndex;
    bool willAccept = _dragState.dragStartIndex == toAcceptIndex &&
        toAcceptIndex != childIndex;

    debugPrint("$this: acceptIndex: $toAcceptIndex, childIndex: $childIndex");
    setState(() {
      if (willAccept) {
        int shiftedIndex = _dragState.calculateShiftedIndex(childIndex);
        _dragState.updateNextIndex(shiftedIndex);
      } else {
        _dragState.updateNextIndex(childIndex);
      }

      _requestAnimationToNextIndex(isAcceptingNewTarget: true);
    });

    _scrollTo(context);

    /// If the target is not the original starting point, then we will accept the drop.
    return willAccept;
  }

  void _onReordered(int fromIndex, int toIndex) {
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
    }

    _animationController.performReorderAnimation();
  }

  Widget _wrapScrollView({required Widget child}) {
    if (widget.scrollController != null &&
        PrimaryScrollController.of(context) == null) {
      return child;
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: widget.padding,
        controller: _scrollController,
        child: child,
      );
    }
  }

  Widget _wrapContainer(List<Widget> children) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(children: children);
      case Axis.vertical:
      default:
        return Column(children: children);
    }
  }

  Widget _buildDraggingContainer({required List<Widget> children}) {
    switch (widget.direction) {
      case Axis.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
      case Axis.vertical:
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: children,
        );
    }
  }

// Scrolls to a target context if that context is not on the screen.
  void _scrollTo(BuildContext context) {
    if (_scrolling) return;
    final RenderObject contextObject = context.findRenderObject()!;
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(contextObject)!;
    // If and only if the current scroll offset falls in-between the offsets
    // necessary to reveal the selected context at the top or bottom of the
    // screen, then it is already on-screen.
    final double margin = widget.direction == Axis.horizontal
        ? _dragState.dropAreaSize.width
        : _dragState.dropAreaSize.height;
    if (_scrollController.hasClients) {
      final double scrollOffset = _scrollController.offset;
      final double topOffset = max(
        _scrollController.position.minScrollExtent,
        viewport.getOffsetToReveal(contextObject, 0.0).offset - margin,
      );
      final double bottomOffset = min(
        _scrollController.position.maxScrollExtent,
        viewport.getOffsetToReveal(contextObject, 1.0).offset + margin,
      );
      final bool onScreen =
          scrollOffset <= topOffset && scrollOffset >= bottomOffset;

      // If the context is off screen, then we request a scroll to make it visible.
      if (!onScreen) {
        _scrolling = true;
        _scrollController.position
            .animateTo(
          scrollOffset < bottomOffset ? bottomOffset : topOffset,
          duration: _animationController.scrollAnimationDuration,
          curve: Curves.easeInOut,
        )
            .then((void value) {
          setState(() {
            _scrolling = false;
          });
        });
      }
    }
  }
}
