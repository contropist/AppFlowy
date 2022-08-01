import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../flowy_board.dart';
import 'board_column/board_phantom.dart';

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
  final BoardDataController dataController;

  ///
  final BoardPassthroughPhantomController passthroughPhantomContorller;

  Board({
    required this.dataController,
    required this.builder,
    this.spacing = 10.0,
    this.runSpacing = 0.0,
    Key? key,
  })  : passthroughPhantomContorller =
            BoardPassthroughPhantomController(delegate: dataController),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer(
        builder: (context, notifier, child) {
          List<Widget> children = [];
          dataController.columns.forEach((key, listData) {
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
  Widget buildBoardColumn(
    String columnId,
    BoardColumnDataController dataController,
  ) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer<BoardColumnDataController>(
        builder: (context, value, child) {
          return BoardColumn(
            key: ValueKey(columnId),
            builder: builder,
            dataController: dataController,
            scrollController: ScrollController(),
            onReorder: (_, int fromIndex, int toIndex) {
              dataController.move(fromIndex, toIndex);
            },
            phantomController: passthroughPhantomContorller,
          );
        },
      ),
    );
  }
}

class BoardDataController extends ChangeNotifier
    with EquatableMixin, PhantomControllerDelegate {
  final LinkedHashMap<String, BoardColumnDataController> columns =
      LinkedHashMap();

  BoardDataController();

  @override
  List<Object?> get props {
    return [columns.values];
  }

  @override
  BoardColumnDataController? controller(String columnId) {
    return columns[columnId];
  }
}
