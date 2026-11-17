import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_007_nonogram_logic/main.dart';

void main() {
  testWidgets('first stage renders all 25 squares and undo', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const NonogramApp());
    expect(find.byKey(const ValueKey('cell-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cell-4-4')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pump();
    expect(find.byIcon(Icons.undo), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(find.text('Complete the picture to win.'), findsOneWidget);
  });
}
