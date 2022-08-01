import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../flex/drag_state.dart';
import '../flex/reorder_flex.dart';
import 'board_phantom.dart';

abstract class ColumnItem extends ReoderFlextItem {
  String get id;

  bool get isPhantom => false;
}

class BoardColumnDataController extends ChangeNotifier
    with EquatableMixin, ReoderFlextDataSource {
  final String columnId;
  final List<ColumnItem> _items;
  final phantomNotifier = PassthroughPhantomNotifier();

  BoardColumnDataController({
    required this.columnId,
    required List<ColumnItem> items,
  }) : _items = items;

  @override
  List<Object?> get props => [columnId, ..._items];

  ColumnItem removeAt(int index) {
    Log.debug(
        '[$BoardColumnDataController] List$columnId remove item at $index');
    final item = _items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }
    Log.debug(
        '[$BoardColumnDataController] List$columnId move item from $fromIndex to $toIndex');
    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, ColumnItem item) {
    Log.debug(
        '[$BoardColumnDataController] List$columnId insert item at $index');
    _items.insert(index, item);
    notifyListeners();
  }

  /// Insert the [Phantom] at [insertedIndex] and remove the existing [Phantom]
  /// if it exists.
  void insertPassthroughPhantom(
      FlexDragTargetData dragTargetData, int phantomIndex) {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      if (index != phantomIndex) {
        Log.debug(
            '[PassthroughPhantom] List$columnId move $columnId:$index to $columnId:$phantomIndex');
        final item = _items.removeAt(index);
        _items.insert(phantomIndex, item);
        // move(index, insertedPhantom.index);
      }
    } else {
      Log.debug(
          '[PassthroughPhantom] List$columnId insert $columnId:$phantomIndex');
      final phantom = PassthroughPhantom(
        index: phantomIndex,
        dragTargetData: dragTargetData,
      );

      phantomNotifier.addListener(
        onInserted: (c) => phantom.onInserted?.call(),
        onDeleted: (c) => phantom.onDeleted?.call(),
      );

      insert(phantomIndex, BoardListPhantomItem(phantom));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 2500), () {
// Here you can write your code
        });

        phantomNotifier.insert(phantom);
      });
    }
  }

  void removePassthroughPhantom() {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      Log.debug('[PassthroughPhantom] List$columnId delete $columnId:$index');
      _items.removeAt(index);
      phantomNotifier.delete(index);
    }
  }

  @override
  List<ColumnItem> get items => _items;

  @override
  String get id => columnId;
}

class PassthroughPhantomNotifier {
  final _insertNotifier = PhantomInsertNotifier();

  final _deleteNotifier = PhantomDeleteNotifier();

  void insert(PassthroughPhantom insertedIndex) {
    _insertNotifier.insert(insertedIndex);
  }

  void delete(int deletedIndex) {
    _deleteNotifier.delete(deletedIndex);
  }

  void addListener({
    void Function(PassthroughPhantom? insertedPhantom)? onInserted,
    void Function(int index)? onDeleted,
  }) {
    if (onInserted != null) {
      _insertNotifier.addListener(() {
        onInserted(_insertNotifier.insertedPhantom);
      });
    }

    if (onDeleted != null) {
      _deleteNotifier.addListener(() {
        onDeleted(_deleteNotifier.deletedIndex);
      });
    }
  }
}

class PhantomInsertNotifier extends ChangeNotifier {
  PassthroughPhantom? insertedPhantom;

  void insert(PassthroughPhantom insertedPhantom) {
    if (this.insertedPhantom != insertedPhantom) {
      this.insertedPhantom = insertedPhantom;
      notifyListeners();
    }
  }
}

class PhantomDeleteNotifier extends ChangeNotifier {
  int deletedIndex = -1;

  void delete(int deletedIndex) {
    if (this.deletedIndex != deletedIndex) {
      this.deletedIndex = deletedIndex;
      notifyListeners();
    }
  }
}
