import 'package:flutter_test/flutter_test.dart';
import 'package:careseva_admin/main.dart';

void main() {
  testWidgets('App loads cleanly test', (WidgetTester tester) async {
    await tester.pumpWidget(const CareSevaAdminApp());
    expect(find.text('CareSeva 2 Admin'), findsOneWidget);
  });
}
