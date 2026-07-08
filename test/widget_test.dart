import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alu_internconnect/main.dart';
import 'package:alu_internconnect/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  });

  testWidgets('app launches without crashing', (tester) async {
    await tester.pumpWidget(const ALUInternConnectApp());
    await tester.pumpAndSettle();

    expect(find.byType(ALUInternConnectApp), findsOneWidget);
  });
}
