import 'package:flutter/material.dart';

import '../../rendering/board_overlay.dart';
import '../../utils/log.dart';
import '../flex/reorder_flex.dart';
import '../flex/drag_state.dart';
import '../flex/drag_target.dart';
import '../flex/reorder_flex_ext.dart';
import 'board_column_data.dart';
import 'board_phantom.dart';

class BoardColumnConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);
  const BoardColumnConfig();
}

typedef OnDragStarted = void Function(int index);
typedef OnDragEnded = void Function(String listId);
typedef OnReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnDeleted = void Function(String listId, int deletedIndex);
typedef OnInserted = void Function(String listId, int insertedIndex);
typedef OnPassedInPhantom = void Function(
    String listId, FlexDragTargetData dragTargetData, int phantomIndex);

typedef BoardColumnItemWidgetBuilder = Widget Function(
    BuildContext context, ColumnItem item);

class BoardColumn extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardColumnDataController dataController;
  final ScrollController? scrollController;
  final BoardColumnConfig config;

  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;

  final BoardPassthroughPhantomController phantomController;

  String get columnId => dataController.columnId;
  final BoardColumnItemWidgetBuilder _builder;

  BoardColumn({
    Key? key,
    this.header,
    this.footer,
    required this.dataController,
    required BoardColumnItemWidgetBuilder builder,
    this.scrollController,
    this.config = const BoardColumnConfig(),
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.phantomController,
  })  : _builder = ((BuildContext context, ColumnItem item) {
          if (item is BoardListPhantomItem) {
            return PassthroughPhantomWidget(
              key: UniqueKey(),
              opacity: config.draggingWidgetOpacity,
              passthroughPhantom: item.phantomContext,
            );
          } else {
            return builder(context, item);
          }
        }),
        super(key: key);

  @override
  State<BoardColumn> createState() => _BoardColumnState();
}

class _BoardColumnState extends State<BoardColumn> {
  final GlobalKey _overlayKey =
      GlobalKey(debugLabel: '$BoardColumn overlay key');

  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          final children = widget.dataController.items
              .map((item) => widget._builder(context, item))
              .toList();

          final dragTargetExtension = DragTargetExtension(
            columnId: widget.columnId,
            newDragTargetData: (dragTargetData, phantomIndex) {
              widget.phantomController.newPassthroughPhantom(
                widget.columnId,
                dragTargetData,
                phantomIndex,
              );
            },
            updateDragTargetData: (dragTargetData, index) {
              widget.phantomController.updatePassedInPhantom(
                  widget.columnId, dragTargetData, index);
            },
            draggableTargetBuilder: PhantomReorderDraggableBuilder(),
          );

          return ReorderFlex(
            key: widget.key,
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {
              Log.debug("${widget.columnId} start dragging");
              widget.onDragStarted?.call(index);
            },
            onReorder: ((fromIndex, toIndex) {
              widget.onReorder(widget.columnId, fromIndex, toIndex);
            }),
            onDragEnded: () {
              Log.debug("${widget.columnId} end dragging");
              widget.onDragEnded?.call(widget.columnId);
              widget.phantomController.removePassedInPhantom();
              widget.phantomController.swapListDataIfNeed();
            },
            dataSource: widget.dataController,
            builder: widget._builder,
            dragTargetExtension: dragTargetExtension,
            children: children,
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
