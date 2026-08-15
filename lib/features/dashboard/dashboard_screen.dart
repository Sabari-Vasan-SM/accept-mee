import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/connection_status_header.dart';
import 'widgets/urgent_approval_banner.dart';
import 'widgets/agent_hero_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/mini_activity_feed.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh trigger
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    UrgentApprovalBanner(),
                    AgentHeroCard(),
                    SizedBox(height: 24),
                    QuickActionsRow(),
                    SizedBox(height: 24),
                    MiniActivityFeed(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
