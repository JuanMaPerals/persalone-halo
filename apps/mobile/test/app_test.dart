import 'package:flutter_test/flutter_test.dart';
import 'package:persalone_mobile/main.dart';

void main() {
  testWidgets('shows the prepared G1 boundary', (WidgetTester tester) async {
    await tester.pumpWidget(const PersalOneApp());

    expect(find.text('PersalOne Halo'), findsOneWidget);
    expect(find.text('G1 foundation'), findsOneWidget);
    expect(find.textContaining('prepared'), findsOneWidget);
    expect(find.textContaining('No physical Halo'), findsOneWidget);
  });
}
