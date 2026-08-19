import 'package:flutter_test/flutter_test.dart';
import 'package:persalone_mobile/main.dart';

void main() {
  testWidgets('shows Android-first G3/G4 controls and evidence limits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PersalOneApp());

    expect(find.text('PersalOne HORIZON — Android audio'), findsOneWidget);
    expect(find.text('G3/G4: host audio real'), findsOneWidget);
    expect(find.textContaining('PREPARED'), findsWidgets);
    expect(find.textContaining('Halo audio'), findsOneWidget);
    expect(find.text('Solicitar micrófono'), findsOneWidget);
    expect(find.text('Iniciar captura real'), findsOneWidget);
  });
}
