import 'package:flowy_board/flowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  final BoardDataController boardData = BoardDataController();

  @override
  void initState() {
    final boardList1 = BoardColumnDataController(columnId: "1", items: [
      TextItem("a"),
      TextItem("b"),
      TextItem("c"),
      TextItem("d"),
    ]);
    final boardList2 = BoardColumnDataController(columnId: "2", items: [
      TextItem("1"),
      TextItem("2"),
      TextItem("3"),
      TextItem("4"),
      TextItem("5"),
    ]);

    boardData.columns[boardList1.columnId] = boardList1;
    boardData.columns[boardList2.columnId] = boardList2;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Board(
      dataController: boardData,
      builder: (context, item) {
        return _RowWidget(item: item as TextItem, key: ObjectKey(item));
      },
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

class TextItem extends ColumnItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}
