import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../flowy_board.dart';
import '../utils/log.dart';

class DraggingItem {
  final String listId;
  final int index;

  DraggingItem(this.listId, this.index);
}

class BoardData extends ChangeNotifier with EquatableMixin {
  final LinkedHashMap<String, BoardListData> lists = LinkedHashMap();

  /// The index that the dragging widget occupied after moving into another list
  DraggingItem? removeItem;

  /// The index that the dragging widget moved into another list.
  DraggingItem? insertItem;

  BoardData();

  void markDelete(String listId, int index) {
    if (removeItem?.listId == listId && removeItem?.index == index) {
      return;
    }

    Log.info('Will remove $listId:$index');
    removeItem = DraggingItem(listId, index);
  }

  void markInsert(String listId, int index) {
    if (insertItem?.listId == listId && insertItem?.index == index) {
      insertItem = null;
      return;
    }

    Log.info('Will insert $listId:$index');
    insertItem = DraggingItem(listId, index);
  }

  void swapListDataIfNeed() {
    if (insertItem == null) return;
    assert(removeItem != null);

    final removeListId = removeItem!.listId;
    final removeIndex = removeItem!.index;

    final insertListId = insertItem!.listId;
    final insertIndex = insertItem!.index;

    final item = lists[removeListId]?.removeAt(removeIndex);
    assert(item != null);

    removeItem = null;
    insertItem = null;

    if (item != null) {
      Log.info(
          'Did move item from List$removeListId:$removeIndex to List$insertListId:$insertIndex');
      lists[insertListId]?.insert(insertIndex, item);
    }
  }

  @override
  List<Object?> get props {
    return [lists.values];
  }
}

class Board extends StatelessWidget {
  /// The direction to use as the main axis.
  final Axis direction = Axis.vertical;

  /// How much space to place between children in a run in the main axis.
  /// Defaults to 0.0.
  final double spacing;

  /// How much space to place between the runs themselves in the cross axis.
  /// Defaults to 0.0.
  final double runSpacing;

  final BoardListItemWidgetBuilder builder;

  ///
  final BoardData boardData;

  const Board({
    required this.boardData,
    required this.builder,
    this.spacing = 10.0,
    this.runSpacing = 0.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: boardData,
      child: Consumer(
        builder: (context, notifier, child) {
          List<Widget> children = [];
          boardData.lists.forEach((key, listData) {
            final child = buildBoardList(key, listData);
            if (children.isEmpty) {
              children.add(SizedBox(width: spacing));
            }
            children.add(Expanded(child: child));
            children.add(SizedBox(width: spacing));
          });

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          );
        },
      ),
    );
  }

  ///
  Widget buildBoardList(String listId, BoardListData listData) {
    return ChangeNotifierProvider.value(
      value: listData,
      child: Consumer<BoardListData>(
        builder: (context, value, child) {
          return BoardList(
            key: ValueKey(listId),
            builder: builder,
            listData: listData,
            scrollController: ScrollController(),
            onWillDeleted: (listId, index) {
              boardData.markDelete(listId, index);
            },
            onWillInserted: (listId, index) {
              boardData.markInsert(listId, index);
            },
            onReorder: (_, int fromIndex, int toIndex) {
              listData.move(fromIndex, toIndex);
            },
            onDragEnded: (_) {
              boardData.swapListDataIfNeed();
            },
          );
        },
      ),
    );
  }
}
