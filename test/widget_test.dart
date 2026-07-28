// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_tuperiri/main.dart';

void main() {
  testWidgets('Hotel Tuperiri app starts', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HotelTupeririApp());

    expect(find.text('HOTEL TUPERIRI'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
