import 'package:flutter/material.dart';

import '../../utils/log.dart';
import 'drag_state.dart';
import 'drag_target.dart';
import 'reorder_flex.dart';

class DragTargetExtension {
  final String columnId;
  final ReorderDraggableTargetBuilder? draggableTargetBuilder;
  final void Function(FlexDragTargetData, int) newDragTargetData;
  final void Function(FlexDragTargetData, int) updateDragTargetData;

  DragTargetExtension({
    required this.columnId,
    required this.newDragTargetData,
    required this.updateDragTargetData,
    this.draggableTargetBuilder,
  });

  bool canHandler(FlexDragTargetData dragTargetData) {
    /// If the columnId equal to the dragTargetData's columnId,
    /// it means the dragTarget is dragging on the top of its own list.
    /// Otherwise, it means the dargTarget was moved to another list.
    ///
    return columnId != dragTargetData.columnId;
  }

  bool onWillAccept(
    ReorderFlexState reorderFlexState,
    BuildContext context,
    FlexDragTargetData dragTargetData,
    bool isDragging,
    int dragIndex,
    int itemIndex,
  ) {
    if (isDragging) {
      Log.debug(
          '[$DragTargetExtension] move List${dragTargetData.columnId}:${dragTargetData.draggingIndex} '
          'to List$columnId:$itemIndex');

      updateDragTargetData(dragTargetData, itemIndex);
      reorderFlexState.onWillAccept(context, dragIndex, itemIndex);
    } else {
      Log.debug('[$DragTargetExtension] new dragTargeData at $itemIndex');
      newDragTargetData(dragTargetData, itemIndex);
    }

    return true;
  }

  void onAccept(FlexDragTargetData dragTargetData) {
    Log.debug('[$DragTargetExtension] $columnId on onAccept');
  }

  void onLeave(FlexDragTargetData dragTargetData) {
    Log.debug('[$DragTargetExtension] $columnId on leave');
  }
}
