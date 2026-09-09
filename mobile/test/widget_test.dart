import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/main.dart';

void main() {
  testWidgets('renders initial counter value', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HaraApp()));

    expect(find.text('0'), findsOneWidget);
  });
}
