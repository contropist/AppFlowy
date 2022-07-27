import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'board_overlay.dart';
import 'board_mixin.dart';
import 'drag_target.dart';
import 'dart:math';

part 'board_list_content.dart';

typedef OnDragStarted = void Function(int index);
typedef OnDragCompleted = void Function();
typedef OnDragEnded = void Function();
typedef OnDargUpdated = void Function(int fromIndex, int toIndex);

class BoardListConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);

  const BoardListConfig();
}

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnDargUpdated? onDragUpdated;
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
    this.onDragUpdated,
    this.onDragCompleted,
    this.onDragEnded,
  })  : assert(
          children.every((Widget widget) => widget.key != null),
        ),
        super(key: key);

  @override
  State<BoardList> createState() => _BoardListState();
}

final GlobalKey _overlayKey = GlobalKey(debugLabel: '$BoardList overlay key');

class _BoardListState extends State<BoardList> {
  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          return _BoardListContentWidget(
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: widget.onDragStarted,
            onDargUpdated: widget.onDragUpdated,
            onDragCompleted: widget.onDragCompleted,
            onDragEnded: widget.onDragEnded,
            children: widget.children,
          );
        },
        opaque: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _overlayKey,
      initialEntries: [_overlayEntry],
    );
  }
}
