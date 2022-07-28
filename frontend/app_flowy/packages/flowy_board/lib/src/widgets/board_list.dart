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
typedef OnDeleted = void Function(String listId, int deletedIndex);
typedef OnInserted = void Function(String listId, int insertedIndex);
typedef OnWillInsert = void Function(
    String listId, int insertedIndex, BoardListItem item);

class BoardListData extends ChangeNotifier with EquatableMixin {
  final String id;
  final List<BoardListItem> _items;

  BoardListData({
    required this.id,
    required List<BoardListItem> items,
  }) : _items = items;

  @override
  List<Object?> get props => [id, ..._items];

  BoardListItem removeAt(int index) {
    final item = _items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }

    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, BoardListItem item) {
    _items.insert(index, item);
    notifyListeners();
  }

  void insertPhantom(int insertedIndex, BoardListPhantomItem phantomItem) {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      if (index != insertedIndex) {
        Log.debug(
            '[phantom] Move phantom from $id:$index to $id:$insertedIndex');
        move(index, insertedIndex);
      }
    } else {
      Log.debug('[phantom] insert phantom at $id:$insertedIndex');
      insert(insertedIndex, phantomItem);
    }
  }

  void removePhantom() {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      Log.debug('[phantom] Remove phantom at $id:$index to');
      removeAt(index);
    }
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
  bool get isPhantom => false;
  String get id;
}

class BoardListPhantomItem implements BoardListItem {
  final BoardListItem inner;

  BoardListPhantomItem(this.inner);

  @override
  bool get isPhantom => true;

  @override
  String get id => inner.id;
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
  final OnDeleted onDeleted;
  final OnInserted onInserted;
  final OnWillInsert onWillInserted;

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
    required this.onDeleted,
    required this.onInserted,
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
          final children = widget.listData._items.map((item) {
            if (item.isPhantom) {
              return widget.builder(
                  context, (item as BoardListPhantomItem).inner);
            } else {
              return widget.builder(context, item);
            }
          }).toList();
          Log.debug('${widget.listId} has ${children.length} children');

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
            onDeleted: (deletedIndex) {
              widget.onDeleted(widget.listId, deletedIndex);
            },
            onInserted: (insertedIndex) {
              widget.onInserted(widget.listId, insertedIndex);
            },
            onWillInserted: (insertedIndex, item) {
              widget.onWillInserted(widget.listId, insertedIndex, item);
            },
            items: widget.listData._items,
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
