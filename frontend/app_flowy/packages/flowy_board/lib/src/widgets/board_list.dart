import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:equatable/equatable.dart';
import '../utils/log.dart';
import 'board_overlay.dart';
import 'board_mixin.dart';
import 'drag_target.dart';
import 'dart:math';

part 'board_list_content.dart';

typedef OnDragStarted = void Function(String listId, int index);
typedef OnDragEnded = void Function(String listId);
typedef OnReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnWillDeleted = void Function(String listId, int deletedIndex);
typedef OnWillInserted = void Function(String listId, int insertedIndex);

class BoardListData extends ChangeNotifier with EquatableMixin {
  final String id;
  final List<BoardListItem> items;

  BoardListData({
    required this.id,
    required this.items,
  });

  @override
  List<Object?> get props => [id, ...items];

  BoardListItem removeAt(int index) {
    final item = items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    final item = items.removeAt(fromIndex);
    items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, BoardListItem item) {
    items.insert(index, item);
    notifyListeners();
  }
}

class BoardListConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);
  const BoardListConfig();
}

abstract class BoardListItem {
  // String get uniqueId;
}

typedef BoardListItemWidgetBuilder = Widget Function(
    BuildContext context, BoardListItem item);

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardListData listData;
  final BoardListItemWidgetBuilder builder;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final OnWillDeleted onWillDeleted;
  final OnWillInserted onWillInserted;

  String get listId => listData.id;

  const BoardList({
    Key? key,
    this.header,
    this.footer,
    required this.listData,
    required this.builder,
    this.scrollController,
    this.config = const BoardListConfig(),
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onWillDeleted,
    required this.onWillInserted,
  }) : super(key: key);

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
          final children = widget.listData.items.map((item) {
            return widget.builder(context, item);
          }).toList();

          return BoardListContentWidget(
            key: widget.key,
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {
              widget.onDragStarted?.call(widget.listId, index);
            },
            onReorder: ((fromIndex, toIndex) {
              widget.onReorder(widget.listId, fromIndex, toIndex);
            }),
            onDragEnded: () {
              widget.onDragEnded?.call(widget.listId);
            },
            onWillDeleted: (deletedIndex) {
              widget.onWillDeleted(widget.listId, deletedIndex);
            },
            onWillInserted: (insertedIndex) {
              widget.onWillInserted(widget.listId, insertedIndex);
            },
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
