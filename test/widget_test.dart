import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_companion/main.dart';
import 'package:antigravity_companion/core/storage/storage_service.dart';
import 'package:antigravity_companion/providers/storage_provider.dart';

void main() {
  testWidgets('Antigravity Companion app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const AntigravityCompanionApp(),
      ),
    );

    // Verify ANTIGRAVITY header is rendered
    expect(find.text('ANTIGRAVITY'), findsOneWidget);
    expect(find.text('Quick Commands'), findsOneWidget);
  });
}
