import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_flutter/shared_flutter.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _CapturingView extends StatefulWidget {
  final void Function(ShoppingListBloc bloc) onBloc;
  final Widget child;

  const _CapturingView({required this.onBloc, required this.child});

  @override
  State<_CapturingView> createState() => _CapturingViewState();
}

class _CapturingViewState extends State<_CapturingView> {
  @override
  Widget build(BuildContext context) {
    widget.onBloc(context.read<ShoppingListBloc>());
    return widget.child;
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView();

  @override
  Widget build(BuildContext context) {
    // Reading the bloc here proves ShoppingListScope provides it to
    // descendants; throws if no BlocProvider is present.
    context.read<ShoppingListBloc>();
    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoading) {
          return const Center(child: Text('loading'));
        }
        if (state is ShoppingListFailure) {
          return Center(child: Text('error: ${state.message}'));
        }
        final items = (state as ShoppingListLoaded).items;
        if (items.isEmpty) {
          return const Center(child: Text('empty'));
        }
        return Column(
          children: items.map((item) => Text(item.name)).toList(),
        );
      },
    );
  }
}

void main() {
  late _MockShoppingItemRepository repository;

  setUp(() {
    repository = _MockShoppingItemRepository();
    registerFallbackValue(
      ShoppingItem(id: '0', name: 'placeholder', createdAt: DateTime.now()),
    );
  });

  testWidgets(
    'creates a ShoppingListBloc, provides it, and loads items on start',
    (tester) async {
      final item = ShoppingItem(
        id: '1',
        name: 'Apples',
        createdAt: DateTime.now(),
      );
      when(() => repository.getAll()).thenAnswer((_) async => [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScope(
            repository: repository,
            child: const _ItemsView(),
          ),
        ),
      );

      // The scope is a descendant of MaterialApp in production, so mirror that
      // here. The initial load should resolve to the loaded items.
      await tester.pumpAndSettle();

      expect(find.text('Apples'), findsOneWidget);
      verify(() => repository.getAll()).called(1);
    },
  );

  testWidgets('reloads the list when the app resumes', (tester) async {
    final item = ShoppingItem(
      id: '2',
      name: 'Bananas',
      createdAt: DateTime.now(),
    );
    var getAllCalls = 0;
    when(() => repository.getAll()).thenAnswer((_) async {
      getAllCalls += 1;
      return getAllCalls == 1 ? <ShoppingItem>[] : [item];
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ShoppingListScope(
          repository: repository,
          child: const _ItemsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('empty'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Bananas'), findsOneWidget);
    verify(() => repository.getAll()).called(2);
  });

  testWidgets(
    'removes its lifecycle observer and closes the bloc when disposed',
    (tester) async {
      when(() => repository.getAll()).thenAnswer((_) async => []);

      ShoppingListBloc? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScope(
            repository: repository,
            child: _CapturingView(
              onBloc: (bloc) => captured = bloc,
              child: const _ItemsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.isClosed, isFalse);

      // Replacing the tree disposes the scope.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(captured!.isClosed, isTrue);

      // The observer is gone: a resume event must not trigger another load.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      verify(() => repository.getAll()).called(1);
    },
  );
}