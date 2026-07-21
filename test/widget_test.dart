import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scholar_management_system/main.dart';

void main() {
  testWidgets('Sign in page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our SignInPage elements exist.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In to Portal'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
