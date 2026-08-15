import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antigravity_companion/core/constants/app_theme.dart';
import 'package:antigravity_companion/features/approvals/approvals_screen.dart';
import 'package:antigravity_companion/providers/antigravity_provider.dart';
import 'package:antigravity_companion/providers/approvals_provider.dart';

import 'support/fake_client.dart';

Widget _wrap(FakeAntigravityClient client) {
  return ProviderScope(
    overrides: [antigravityClientProvider.overrideWithValue(client)],
    child: MaterialApp(theme: AppTheme.darkTheme, home: const ApprovalsScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when nothing is waiting', (tester) async {
    final client = FakeAntigravityClient();
    await tester.pumpWidget(_wrap(client));
    await tester.pumpAndSettle();

    expect(find.text('All Clear'), findsOneWidget);
    expect(find.textContaining('Nothing is waiting on you'), findsOneWidget);
  });

  testWidgets('renders a pending request from the broker', (tester) async {
    final client = FakeAntigravityClient(approvals: [buildRequest()]);
    await tester.pumpWidget(_wrap(client));
    await tester.pumpAndSettle();

    expect(find.text('rm -rf ./dist'), findsWidgets);
    expect(find.text('All Clear'), findsNothing);
  });

  testWidgets('the count provider tracks what the broker reports', (tester) async {
    final client = FakeAntigravityClient(
      approvals: [buildRequest(id: 'a'), buildRequest(id: 'b', title: 'npm install')],
    );

    late int count;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [antigravityClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Consumer(
            builder: (context, ref, _) {
              count = ref.watch(pendingApprovalsCountProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(count, 2);
  });
}
