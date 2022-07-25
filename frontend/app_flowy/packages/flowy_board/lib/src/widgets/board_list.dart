import 'package:flutter/material.dart';
import 'board_overlay.dart';

typedef OnDragStarted = void Function();
typedef OnDragCompleted = void Function();
typedef OnDragEnded = void Function();
typedef OnDargUpdated = void Function();

class BoardListConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(microseconds: 250);

  const BoardListConfig();
}

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnDargUpdated? onDargUpdated;
  final OnDragCompleted? onDragCompleted;
  final OnDragEnded? onDragEnded;

  BoardList({
    Key? key,
    this.header,
    this.footer,
    required this.children,
    this.scrollController,
    this.config = const BoardListConfig(),
    this.onDragStarted,
    this.onDargUpdated,
    this.onDragCompleted,
    this.onDragEnded,
  })  : assert(
          children.every((Widget widget) => widget.key != null),
        ),
        super(key: key);

  @override
  State<BoardList> createState() => _BoardListState();
}

class _BoardListState extends State<BoardList> {
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          return Container();
        },
        opaque: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
