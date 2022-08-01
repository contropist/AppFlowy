import 'package:flutter/material.dart';

import '../../../flowy_board.dart';
import '../../utils/log.dart';
import '../flex/drag_state.dart';
import '../flex/drag_target.dart';

abstract class PhantomControllerDelegate {
  BoardColumnDataController? controller(String columnId);
}

class BoardPassthroughPhantomController {
  final PhantomControllerDelegate delegate;

  /// The index that the dragging widget occupied after moving into another list
  DraggingItem? removeItem;

  /// The index that the dragging widget moved into another list.
  DraggingItem? insertItem;

  PhantomItem? phantomItem;

  BoardPassthroughPhantomController({required this.delegate});

  void newPassthroughPhantom(
      String columnId, FlexDragTargetData dragTargetData, int phantomIndex) {
    /// Insert new phantom to list
    phantomItem =
        PhantomItem(columnId, dragTargetData.columnItem as ColumnItem);

    delegate
        .controller(columnId)
        ?.insertPassthroughPhantom(dragTargetData, phantomIndex);
  }

  /// Insert the [Phantom] to list with [listId] and remove the [Phantom]
  /// from the others which [listId] is not equal to the [listId].
  ///
  void updatePassedInPhantom(
    String listId,
    FlexDragTargetData dragTargetData,
    int phantomIndex,
  ) {
    _markInsert(listId, phantomIndex);
    _markDelete(dragTargetData.columnId, dragTargetData.draggingIndex);

    assert(phantomItem != null);
    if (phantomItem!.listId != listId) {
      /// Remove the phanotm from the old list
      delegate.controller(phantomItem!.listId)?.removePassthroughPhantom();
    } else {
      /// Update the existing phantom index
      delegate
          .controller(phantomItem!.listId)
          ?.insertPassthroughPhantom(dragTargetData, phantomIndex);
    }
  }

  void removePassedInPhantom() {
    if (phantomItem != null) {
      delegate.controller(phantomItem!.listId)?.removePassthroughPhantom();
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
    final item = delegate.controller(removeListId)?.removeAt(removeIndex);
    assert(item != null);
    delegate.controller(insertListId)?.insert(insertIndex, item!);

    removeItem = null;
    insertItem = null;
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

class DraggingItem {
  final String listId;
  final int index;

  DraggingItem(this.listId, this.index);
}

class PhantomItem {
  final String listId;
  final ColumnItem item;

  PhantomItem(this.listId, this.item);
}

class BoardListPhantomItem extends ColumnItem {
  final PassthroughPhantom phantomContext;

  BoardListPhantomItem(PassthroughPhantom insertedPhantom)
      : phantomContext = insertedPhantom;

  @override
  bool get isPhantom => true;

  @override
  String get id => phantomContext.itemData.id;

  Size? get feedbackSize => phantomContext.feedbackSize;

  Widget get draggingWidget => phantomContext.draggingWidget == null
      ? const SizedBox()
      : phantomContext.draggingWidget!;
}

class PassthroughPhantom {
  int index;
  final FlexDragTargetData dragTargetData;

  Size? get feedbackSize => dragTargetData.state.feedbackSize;

  Widget? get draggingWidget => dragTargetData.draggingWidget;

  ColumnItem get itemData => dragTargetData.columnItem as ColumnItem;

  VoidCallback? onInserted;

  VoidCallback? onDeleted;

  PassthroughPhantom({
    required this.index,
    required this.dragTargetData,
  });
}

class PhantomReorderDraggableBuilder extends ReorderDraggableTargetBuilder {
  @override
  Widget? build<T extends DragTargetData>(
    BuildContext context,
    Widget child,
    DragTargetOnStarted onDragStarted,
    DragTargetOnEnded<T> onDragEnded,
  ) {
    if (child is PassthroughPhantomWidget) {
      final phantomContext = child.passthroughPhantom;
      phantomContext.onInserted = () {
        onDragStarted(
          child,
          phantomContext.index,
          phantomContext.feedbackSize,
        );
      };

      phantomContext.onDeleted = () {
        onDragEnded(phantomContext.dragTargetData as T);
      };
      return IgnorePointerWidget(child: child);
    } else {
      return null;
    }
  }
}

class PassthroughPhantomWidget extends PhantomWidget {
  final PassthroughPhantom passthroughPhantom;

  PassthroughPhantomWidget({
    required double opacity,
    required this.passthroughPhantom,
    Key? key,
  }) : super(
          child: passthroughPhantom.draggingWidget,
          opacity: opacity,
          key: key,
        );
}
