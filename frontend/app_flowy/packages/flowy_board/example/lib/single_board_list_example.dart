import 'package:flutter/material.dart';
import 'package:flowy_board/flowy_board.dart';

class SingleBoardListExample extends StatefulWidget {
  const SingleBoardListExample({Key? key}) : super(key: key);

  @override
  State<SingleBoardListExample> createState() => _SingleBoardListExampleState();
}

class _SingleBoardListExampleState extends State<SingleBoardListExample> {
  var rows = ["1", "2", "3", "4", "5"];

  @override
  Widget build(BuildContext context) {
    final children = rows.map((row) {
      return _RowWidget(text: row, key: ObjectKey(row));
    }).toList();

    return BoardList(
      children: children,
      onDragStarted: (index) {
        debugPrint("[drag] $index");
      },
      onReorder: (from, to) {
        debugPrint("[drag] from:$from to:$to");
        setState(() {
          final row = rows.removeAt(from);
          rows.insert(to, row);
        });
      },
      onDragEnded: () {
        debugPrint("[drag] end");
      },
    );
  }
}

class _RowWidget extends StatelessWidget {
  final String text;
  const _RowWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ObjectKey(text),
      width: double.infinity,
      height: 60,
      color: Colors.green,
      child: Center(child: Text(text)),
    );
  }
}
