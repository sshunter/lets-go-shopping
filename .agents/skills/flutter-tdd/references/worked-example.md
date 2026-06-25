# Worked Example: Profile Feature via Flutter TDD

A concrete walk through the orchestrator's loop on a small feature, showing the sequencing (tracer bullet -> per-behavior logic + widget red-green -> integration) and the mocking boundary map in Dart.

Feature: load a user profile by id. Show a loading indicator while loading, the user's name when loaded, and an error message on failure.

Layers (from `flutter-apply-architecture-best-practices`):
- `UserProfileApiClient` (Service) - wraps the external API. TRUE system boundary.
- `UserProfileRepository` (interface + impl) - consumes the ApiClient, returns a domain `UserProfile`. Impl tested against a fake ApiClient. Interface mocked when testing the ViewModel.
- `ProfileViewModel` (ChangeNotifier) - exposes `isLoading` / `user` / `errorMessage` and a `loadProfile(id)` command. Internal collaborator: never mocked when testing the View.
- `ProfileView` - listens to the ViewModel.

## Step 1: Tracer bullet (widget tier, thin end-to-end)

Write a widget test of the feature's entry widget with minimal stubs. RED = the widget does not exist (compile fail).

```dart
// test/profile_view_tracer_test.dart
testWidgets('ProfileView shows not-found placeholder initially', (tester) async {
  await tester.pumpWidget(MaterialApp(home: ProfileView(viewModel: ProfileViewModel())));
  expect(find.text('User not found'), findsOneWidget);
});
```

Run `flutter test test/profile_view_tracer_test.dart` -> RED (ProfileView / ProfileViewModel do not exist). Create minimal `ProfileView` + `ProfileViewModel` stubs to compile and pass -> GREEN. The path is proven.

## Step 2: Incremental red-green, logic-tier-first, per behavior

### Behavior: loadProfile sets the user from the repository

Logic tier. Mock the Repository INTERFACE (declared port) - not the ApiClient, not the ViewModel.

```dart
// test/profile_viewmodel_test.dart
test('loadProfile exposes the user from the repository', () async {
  final repo = MockUserProfileRepository(); // mock the interface
  when(repo.getUser('1')).thenAnswer((_) async => UserProfile(id: '1', name: 'Ada'));
  final vm = ProfileViewModel(repository: repo);

  await vm.loadProfile('1');

  expect(vm.user?.name, 'Ada');
});
```

Run -> RED -> implement `ProfileViewModel.loadProfile` minimally -> GREEN.

### Behavior: loadProfile shows loading then not-loading

```dart
test('loadProfile sets isLoading true while loading, false after', () async {
  final repo = MockUserProfileRepository();
  when(repo.getUser('1')).thenAnswer((_) async => UserProfile(id: '1', name: 'Ada'));
  final vm = ProfileViewModel(repository: repo);

  final future = vm.loadProfile('1');
  expect(vm.isLoading, isTrue);
  await future;
  expect(vm.isLoading, isFalse);
});
```

Run -> RED -> add the loading state -> GREEN.

### Behavior: loadProfile exposes an error on failure

```dart
test('loadProfile exposes an error message when the repository throws', () async {
  final repo = MockUserProfileRepository();
  when(repo.getUser('1')).thenThrow(Exception('boom'));
  final vm = ProfileViewModel(repository: repo);

  await vm.loadProfile('1');

  expect(vm.errorMessage, 'boom');
});
```

Run -> RED -> add error handling -> GREEN.

### Repository impl tested against a FAKE Service (true boundary), not a mock

```dart
// test/user_profile_repository_test.dart
test('getUser maps the api model to a domain user and caches it', () async {
  final apiClient = FakeUserProfileApiClient(); // fake, not mock
  final repo = UserProfileRepository(apiClient: apiClient);

  final user = await repo.getUser('1');

  expect(user.name, 'Ada Lovelace');
  // second call does not hit the api again (cache)
  apiClient.callCount = 0;
  await repo.getUser('1');
  expect(apiClient.callCount, 0);
});
```

Run -> RED -> implement mapping + cache -> GREEN.

### Widget tier, same behaviors, with a REAL ViewModel

Never mock the ViewModel. The View runs against a real ViewModel, which runs against a mocked Repository.

```dart
// test/profile_view_test.dart
testWidgets('shows a loading indicator while loading', (tester) async {
  final repo = MockUserProfileRepository();
  when(repo.getUser('1')).thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => UserProfile(id: '1', name: 'Ada')));
  final vm = ProfileViewModel(repository: repo);
  await tester.pumpWidget(MaterialApp(home: ProfileView(viewModel: vm)));

  vm.loadProfile('1'); // do not await
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

Run -> RED -> render the indicator when `isLoading` -> GREEN. Repeat for "shows user name when loaded" and "shows error message on failure", one test at a time.

## Step 3: Integration verification (last)

Full `integration_test` covering the end-to-end flow. The app is wired with a real Repository against a fake Service (via DI), so the whole stack runs.

```dart
// integration_test/profile_flow_test.dart
IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('loading a profile shows the user name end-to-end', (tester) async {
  await tester.pumpWidget(MyApp()); // wired with UserProfileRepository(FakeUserProfileApiClient())

  await tester.enterText(find.byKey(const ValueKey('user_id_field')), '1');
  await tester.tap(find.byKey(const ValueKey('load_button')));
  await tester.pumpAndSettle();

  expect(find.text('Ada Lovelace'), findsOneWidget);
});
```

Run `flutter test integration_test/profile_flow_test.dart` -> RED until the flow is wired -> GREEN. Then run the full `flutter test` suite as the final regression check.

## Boundary map recap (what got mocked where)

- `FakeUserProfileApiClient` - fake at the true system boundary, used in Repository impl tests and the integration test.
- `MockUserProfileRepository` - mock the Repository INTERFACE (injected port), used only in ViewModel tests.
- `ProfileViewModel` - REAL in every widget test. Never mocked.
- Unit under test - never mocked. No assertions on internal call counts / order.

This is the reconciled map: mock at two layers (Service via fake, Repository-interface-as-port), never mock a sibling ViewModel or the unit under test.