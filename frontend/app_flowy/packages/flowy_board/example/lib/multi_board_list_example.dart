import 'package:flowy_board/flowy_board.dart';
import 'package:flutter/material.dart';

class MultiBoardListExample extends StatefulWidget {
  const MultiBoardListExample({Key? key}) : super(key: key);

  @override
  State<MultiBoardListExample> createState() => _MultiBoardListExampleState();
}

class _MultiBoardListExampleState extends State<MultiBoardListExample> {
  var rows_1 = ["1", "2", "3", "4", "5"];
  var rows_2 = ["a", "b", "c", "d", "e"];

  @override
  Widget build(BuildContext context) {
    final children1 = rows_1.map((row) {
      return _RowWidget(text: row, key: ObjectKey(row));
    }).toList();

    final children2 = rows_2.map((row) {
      return _RowWidget(text: row, key: ObjectKey(row));
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: BoardList(
            scrollController: ScrollController(),
            children: children1,
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: BoardList(
            scrollController: ScrollController(),
            children: children2,
          ),
        )
      ],
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
      // width: double.infinity,
      height: 60,
      color: Colors.green,
      child: Center(child: Text(text)),
    );
  }
}
