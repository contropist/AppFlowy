import 'dart:convert';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/state_tree.dart';
import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('create state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    expect(stateTree.root.type, 'root');
    expect(stateTree.root.toJson(), data['document']);
  });

  test('search node by Path in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final checkBoxNode = stateTree.root.childAtPath([1, 0]);
    expect(checkBoxNode != null, true);
    final textType = checkBoxNode!.attributes['text-type'];
    expect(textType != null, true);
  });

  test('search node by Self in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final checkBoxNode = stateTree.root.childAtPath([1, 0]);
    expect(checkBoxNode != null, true);
    final textType = checkBoxNode!.attributes['text-type'];
    expect(textType != null, true);
    final path = checkBoxNode.path;
    expect(pathEquals(path, [1, 0]), true);
  });

  test('insert node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final insertNode = Node.fromJson({
      'type': 'text',
    });
    bool result = stateTree.insert([1, 1], [insertNode]);
    expect(result, true);
    expect(identical(insertNode, stateTree.nodeAtPath([1, 1])), true);
  });

  test('delete node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    stateTree.delete([1, 1], 1);
    final node = stateTree.nodeAtPath([1, 1]);
    expect(node != null, true);
    expect(node!.attributes['tag'], '**');
  });

  test('update node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final attributes = stateTree.update([1, 1], {'text-type': 'heading1'});
    expect(attributes != null, true);
    expect(attributes!['text-type'], 'checkbox');
    final updatedNode = stateTree.nodeAtPath([1, 1]);
    expect(updatedNode != null, true);
    expect(updatedNode!.attributes['text-type'], 'heading1');
  });

  test('test path utils 1', () {
    final path1 = <int>[1];
    final path2 = <int>[1];
    expect(pathEquals(path1, path2), true);

    expect(hashList(path1), hashList(path2));
  });

  test('test path utils 2', () {
    final path1 = <int>[1];
    final path2 = <int>[2];
    expect(pathEquals(path1, path2), false);

    expect(hashList(path1) != hashList(path2), true);
  });

  test('test position comparator', () {
    final pos1 = Position(path: [1], offset: 0);
    final pos2 = Position(path: [1], offset: 0);
    expect(pos1 == pos2, true);
    expect(pos1.hashCode == pos2.hashCode, true);
  });

  test('test position comparator with offset', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    expect(pos1, pos2);
    expect(pos1.hashCode, pos2.hashCode);
  });

  test('test position comparator false', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 2, 1, 1], offset: 100);
    expect(pos1 == pos2, false);
    expect(pos1.hashCode == pos2.hashCode, false);
  });

  test('test position comparator with offset false', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 1, 1, 1], offset: 101);
    expect(pos1 == pos2, false);
    expect(pos1.hashCode == pos2.hashCode, false);
  });

  test('test selection comparator', () {
    final pos = Position(path: [0], offset: 0);
    final sel = Selection.collapsed(pos);
    expect(sel.start, sel.end);
    expect(sel.isCollapsed, true);
  });

  test('test selection collapse', () {
    final start = Position(path: [0], offset: 0);
    final end = Position(path: [0], offset: 10);
    final sel = Selection(start: start, end: end);

    final collapsedSelAtStart = sel.collapse(atStart: true);
    expect(collapsedSelAtStart.start, start);
    expect(collapsedSelAtStart.end, start);

    final collapsedSelAtEnd = sel.collapse();
    expect(collapsedSelAtEnd.start, end);
    expect(collapsedSelAtEnd.end, end);
  });
}
