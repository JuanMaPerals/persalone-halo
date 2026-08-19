import 'package:flutter_test/flutter_test.dart';
import 'package:persalone_mobile/main.dart';

void main() {
  testWidgets('declares the G1 capability boundary', (WidgetTester tester) async {
    await tester.pumpWidget(const PersalOneApp());

    expect(find.text('G1 foundation'), findsOneWidget);
    expect(find.textContaining('No physical Halo'), findsOneWidget);
  });
}
