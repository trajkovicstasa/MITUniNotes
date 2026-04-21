import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/admin_nav_item.dart';
import 'package:notes_hub/providers/theme_provider.dart';
import 'package:notes_hub/screens/auth/login.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onSelect,
    required this.child,
  });

  final int currentIndex;
  final String title;
  final String subtitle;
  final List<AdminNavItem> items;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      drawer: isWide
          ? null
          : _AdminDrawer(
              currentIndex: currentIndex,
              items: items,
              onSelect: onSelect,
            ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 280,
              child: _AdminSidebar(
                currentIndex: currentIndex,
                items: items,
                onSelect: onSelect,
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isWide ? 24 : 8, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isWide)
                      Builder(
                        builder: (context) => IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ),
                    if (!isWide) const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TitelesTextWidget(label: title, fontSize: 30),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await MyAppFunctions.showErrorOrWarningDialog(
                              context: context,
                              subtitle: 'Da li sigurno zelis da se odjavis sa admin naloga?',
                              isError: false,
                              fct: () async {
                                await FirebaseAuth.instance.signOut();
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  LoginScreen.routeName,
                                  (route) => false,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Odjava'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SubtitleTextWidget(label: subtitle, maxLines: 3),
                    const SizedBox(height: 24),
                    Expanded(child: child),
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  final int currentIndex;
  final List<AdminNavItem> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.getIsDarkTheme;

    return Container(
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      UniNotesLogo(size: 44),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TitelesTextWidget(label: 'UniNotes Admin', fontSize: 20),
                            SubtitleTextWidget(
                              label: 'Moderacija i administracija sistema',
                              maxLines: 2,
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SubtitleTextWidget(
                    label: 'Navigacija',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? AppColors.lightPrimary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onSelect(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected
                                      ? AppColors.lightPrimary
                                      : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SubtitleTextWidget(
                                     label: item.label,
                                     color: isSelected
                                         ? AppColors.lightPrimary
                                         : Theme.of(context)
                                             .textTheme
                                             .bodyLarge
                                             ?.color,
                                     fontWeight: isSelected
                                         ? FontWeight.w700
                                         : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const SubtitleTextWidget(
                    label: 'Podesavanja',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        isDarkTheme
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.lightPrimary,
                      ),
                      title: Text(
                        isDarkTheme ? 'Tamna tema' : 'Svetla tema',
                      ),
                      value: isDarkTheme,
                      onChanged: (value) {
                        themeProvider.setDarkTheme(themeValue: value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  final int currentIndex;
  final List<AdminNavItem> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _AdminSidebar(
        currentIndex: currentIndex,
        items: items,
        onSelect: (index) {
          Navigator.pop(context);
          onSelect(index);
        },
      ),
    );
  }
}
