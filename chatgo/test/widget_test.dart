import 'package:flutter_test/flutter_test.dart';

// On importe main.dart pour avoir accès à ChatAndGoApp.
// Adapte "chatgo" ci-dessous si le nom de ton package (dans
// pubspec.yaml, ligne "name:") est différent.
import 'package:chatgo/main.dart';

void main() {
  testWidgets('Le splash screen Chat&GO s\'affiche', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChatAndGoApp());

    expect(find.text('Chat&GO'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });
}
