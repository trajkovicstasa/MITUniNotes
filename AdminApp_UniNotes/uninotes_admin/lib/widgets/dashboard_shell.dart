import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/models/admin_nav_item.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/uninotes_admin_logo.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
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
                padding: EdgeInsets.fromLTRB(isWide ? 24 : 4, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isWide)
                      Builder(
                        builder: (context) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            icon: const Icon(Icons.menu_rounded),
                          );
                        },
                      ),
                    if (!isWide) const SizedBox(height: 18),
                    AppTitleText(label: title, fontSize: 30),
                    const SizedBox(height: 6),
                    AppSubtitleText(label: subtitle, maxLines: 2),
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
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UniNotesAdminLogo(),
                  const SizedBox(height: 28),
                  const AppSubtitleText(
                    label: 'Navigacija',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.10)
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
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppSubtitleText(
                                    label: item.label,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.text,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.scaffold,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const AppSubtitleText(
                      label:
                          'Admin app je odvojena od korisnicke aplikacije i sluzi za moderaciju sadrzaja.',
                      maxLines: 4,
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
