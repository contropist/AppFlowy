import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../flowy_board.dart';
import '../utils/log.dart';
import 'flex/drag_state.dart';

class DraggingItem {
  final String listId;
  final int index;

  DraggingItem(this.listId, this.index);
}

class PhantomItem {
  final String listId;
  final BoardColumnItem item;

  PhantomItem(this.listId, this.item);
}

class BoardDataController extends ChangeNotifier with EquatableMixin {
  final LinkedHashMap<String, BoardColumnDataController> lists =
      LinkedHashMap();

  /// The index that the dragging widget occupied after moving into another list
  DraggingItem? removeItem;

  /// The index that the dragging widget moved into another list.
  DraggingItem? insertItem;

  PhantomItem? phantomItem;

  BoardDataController();

  /// Insert the [Phantom] to list with [listId] and remove the [Phantom]
  /// from the others which [listId] is not equal to the [listId].
  ///
  void receivePassedInPhantom(
      String listId, DraggingContext draggingContext, int phantomIndex) {
    _markInsert(listId, phantomIndex);
    _markDelete(draggingContext.listId, draggingContext.draggingIndex);

    if (phantomItem != null) {
      if (phantomItem!.listId != listId) {
        /// Remove the phanotm from the old list
        lists[phantomItem!.listId]?.removePassedInPhantom();
      } else {
        /// Update the existing phantom index
        lists[phantomItem!.listId]
            ?.insertPhantom(draggingContext, phantomIndex);
      }
    } else {
      /// Insert new phantom to list
      phantomItem = PhantomItem(listId, draggingContext.bindData);
      lists[listId]?.insertPhantom(draggingContext, phantomIndex);
    }
  }

  void removePassedInPhantom() {
    if (phantomItem != null) {
      lists[phantomItem!.listId]?.removePassedInPhantom();
    }

    phantomItem = null;
  }

  void swapListDataIfNeed() {
    Log.trace(
        "[$BoardColumnDataController] Remove: $removeItem Insert: $insertItem");
    if (insertItem == null) return;
    assert(removeItem != null);

    final removeListId = removeItem!.listId;
    final removeIndex = removeItem!.index;

    final insertListId = insertItem!.listId;
    final insertIndex = insertItem!.index;

    Log.info(
        '[$BoardColumnDataController] move List$removeListId:$removeIndex to List$insertListId:$insertIndex');
    final item = lists[removeListId]?.removeAt(removeIndex);
    assert(item != null);
    lists[insertListId]?.insert(insertIndex, item!);

    removeItem = null;
    insertItem = null;
  }

  @override
  List<Object?> get props {
    return [lists.values];
  }

  void _markDelete(String listId, int index) {
    if (removeItem?.listId == listId && removeItem?.index == index) {
      return;
    }

    Log.info('Mark $listId:$index as deletable');
    removeItem = DraggingItem(listId, index);
  }

  void _markInsert(String listId, int index) {
    if (insertItem?.listId == listId && insertItem?.index == index) {
      return;
    }

    Log.info('Mark $listId:$index as insertable');
    insertItem = DraggingItem(listId, index);
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

  final BoardColumnItemWidgetBuilder builder;

  ///
  final BoardDataController boardData;

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
            final child = buildBoardColumn(key, listData);
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
  Widget buildBoardColumn(String columnId, BoardColumnDataController listData) {
    return ChangeNotifierProvider.value(
      value: listData,
      child: Consumer<BoardColumnDataController>(
        builder: (context, value, child) {
          return BoardColumn(
            key: ValueKey(columnId),
            builder: builder,
            dataController: listData,
            scrollController: ScrollController(),
            onReorder: (_, int fromIndex, int toIndex) {
              listData.move(fromIndex, toIndex);
            },
            onDragEnded: (_) {
              Log.debug("$columnId end dragging");
              boardData.removePassedInPhantom();
              boardData.swapListDataIfNeed();
            },
            onPassedInPhantom: (listId, draggingContext, phantomIndex) {
              boardData.receivePassedInPhantom(
                  listId, draggingContext, phantomIndex);
            },
          );
        },
      ),
    );
  }
}
