import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:ios_app/main.dart';

class MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository mockRepository;

  setUp(() {
    mockRepository = MockShoppingItemRepository();

    when(() => mockRepository.getAll()).thenAnswer((_) async => []);
  });

  testWidgets('Shopping List smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(repository: mockRepository),
    );

    await tester.pumpAndSettle();

    // Verify that our app starts with the empty state message.
    expect(find.text('Your shopping list is empty!'), findsOneWidget);
  });
}
