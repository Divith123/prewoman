import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash/consts.dart';
import 'common_widgets/common_widgets.dart';
import 'envvar/environment_page.dart';
import 'home_page/home_page.dart';
import 'history/history_page.dart';
import 'settings_page.dart';
import 'aichat/aichatpage.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final railIdx = ref.watch(navRailIndexStateProvider);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Column(
              children: [
                SizedBox(
                  height: kIsMacOS ? 32.0 : 16.0,
                  width: 64,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavIcon(
                      context,
                      ref,
                      index: 0,
                      icon: Icons.auto_awesome_mosaic_outlined,
                      selectedIcon: Icons.auto_awesome_mosaic,
                      label: 'Requests',
                    ),
                    kVSpacer10,
                    _buildNavIcon(
                      context,
                      ref,
                      index: 1,
                      icon: Icons.laptop_windows_outlined,
                      selectedIcon: Icons.laptop_windows,
                      label: 'Variables',
                    ),
                    kVSpacer10,
                    _buildNavIcon(
                      context,
                      ref,
                      index: 2,
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history_rounded,
                      label: 'History',
                    ),
                    kVSpacer10,
                    _buildNavIcon(
                      context,
                      ref,
                      index: 3,
                      icon: Icons.chat_outlined,
                      selectedIcon: Icons.chat,
                      label: 'AI Chat',
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: NavbarButton(
                          railIdx: railIdx,
                          selectedIcon: Icons.help,
                          icon: Icons.help_outline,
                          label: 'About',
                          showLabel: false,
                          isCompact: true,
                          onTap: () {
                            showAboutAppDialog(context);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: NavbarButton(
                          railIdx: railIdx,
                          buttonIdx: 4, // Corrected index for Settings
                          selectedIcon: Icons.settings,
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          showLabel: false,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            Expanded(
              child: IndexedStack(
                alignment: AlignmentDirectional.topCenter,
                index: railIdx,
                children: const [
                  HomePage(),
                  EnvironmentPage(),
                  HistoryPage(),
                  AIChatPage(), // Added AI Chat Page
                  SettingsPage(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final railIdx = ref.watch(navRailIndexStateProvider);
    return Column(
      children: [
        IconButton(
          isSelected: railIdx == index,
          onPressed: () {
            ref.read(navRailIndexStateProvider.notifier).state = index;
          },
          icon: Icon(icon),
          selectedIcon: Icon(selectedIcon),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
