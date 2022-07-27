import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'board_overlay.dart';
import 'board_mixin.dart';
import 'drag_target.dart';
import 'dart:math';

part 'board_list_content.dart';

typedef OnDragStarted = void Function(BoardList list, int index);
typedef OnDragEnded = void Function(BoardList list);
typedef OnReorder = void Function(int fromIndex, int toIndex);
typedef OnDeleted = BoardListItem Function(int deletedIndex);
typedef OnInserted = void Function(int insertedIndex, BoardListItem newItem);

class BoardListConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);
  const BoardListConfig();
}

abstract class BoardListItem {}

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final OnDeleted onDeleted;
  final OnInserted onInserted;

  BoardList({
    Key? key,
    this.header,
    this.footer,
    required this.children,
    this.scrollController,
    this.config = const BoardListConfig(),
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onDeleted,
    required this.onInserted,
  })  : assert(
          children.every((Widget widget) => widget.key != null),
        ),
        super(key: key);

  @override
  State<BoardList> createState() => _BoardListState();
}

class _BoardListState extends State<BoardList> {
  final GlobalKey _overlayKey = GlobalKey(debugLabel: '$BoardList overlay key');

  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          return BoardListContentWidget(
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {
              widget.onDragStarted?.call(widget, index);
            },
            onReorder: widget.onReorder,
            onDragEnded: () {
              widget.onDragEnded?.call(widget);
            },
            onDeleted: widget.onDeleted,
            onInserted: widget.onInserted,
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
