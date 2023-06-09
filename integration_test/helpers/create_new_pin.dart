import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin_code_view/code_view.dart';

import 'enter_pin.dart';

Future<void> createNewPin(WidgetTester tester) async {
  const String correctPin = '123456';
  const String wrongPin = '123457';

  await tester.pumpAndSettle();
  await enterPinCode(tester, pin: correctPin);
  await tester.pumpAndSettle();

  //check for wrong pin
  await enterPinCode(tester, pin: wrongPin);
  await tester.pump(Duration(seconds: 1));
  final codeView = find.byType(CodeView);
  final codeViewParent =
      find.ancestor(of: codeView, matching: find.byType(Column)).first;
  final errorText =
      find.descendant(of: codeViewParent, matching: find.byType(Text));
  expect(
    tester.widget<Text>(errorText).data.isNotEmpty,
    true,
    reason: 'Wrong confirmation PIN entered, but no error message shown.',
  );

  await enterPinCode(tester, pin: correctPin);
  await tester.pumpAndSettle();
}
