import 'package:flutter_test/flutter_test.dart';
import 'package:persalone_mobile/main.dart';

void main() {
  testWidgets('declares the G3/G4 Android audio evidence boundary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PersalOneApp());

    expect(find.text('G3/G4: host audio real'), findsOneWidget);
    expect(find.textContaining('Halo audio'), findsOneWidget);
    expect(find.textContaining('MEASURED'), findsOneWidget);
  });
}
