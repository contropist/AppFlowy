import 'package:flowy_board/flowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  var items_1 = [
    TextItem("1"),
    TextItem("2"),
    TextItem("3"),
    TextItem("4"),
    TextItem("5"),
  ];
  var items_2 = [
    TextItem("a"),
    TextItem("b"),
    TextItem("c"),
    TextItem("d"),
    TextItem("e"),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildList1()),
        const SizedBox(width: 30),
        Expanded(child: _buildList2())
      ],
    );
  }

  Widget _buildList1() {
    final children = items_1.map((item) {
      return _RowWidget(item: item, key: ObjectKey(item));
    }).toList();

    return BoardList(
      scrollController: ScrollController(),
      onDeleted: (int deletedIndex) {
        final removedItem = items_1.removeAt(deletedIndex);
        setState(() {});
        return removedItem;
      },
      onReorder: (from, to) {
        setState(() {
          final row = items_1.removeAt(from);
          items_1.insert(to, row);
        });
      },
      onInserted: (
        int insertedIndex,
        BoardListItem newItem,
      ) {
        setState(() {
          items_1.insert(insertedIndex, newItem as TextItem);
        });
      },
      children: children,
    );
  }

  Widget _buildList2() {
    final children = items_2.map((item) {
      return _RowWidget(item: item, key: ObjectKey(item));
    }).toList();

    return BoardList(
      scrollController: ScrollController(),
      onDeleted: (int deletedIndex) {
        final removedItem = items_2.removeAt(deletedIndex);
        setState(() {});
        return removedItem;
      },
      onReorder: (from, to) {
        setState(() {
          final row = items_2.removeAt(from);
          items_2.insert(to, row);
        });
      },
      onInserted: (
        int insertedIndex,
        BoardListItem newItem,
      ) {
        setState(() {
          items_2.insert(insertedIndex, newItem as TextItem);
        });
      },
      children: children,
    );
  }
}

class _RowWidget extends StatelessWidget {
  final TextItem item;
  const _RowWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(item),
      height: 60,
      color: Colors.green,
      child: Center(child: Text(item.s)),
    );
  }
}

class TextItem extends BoardListItem {
  final String s;

  TextItem(this.s);
}
