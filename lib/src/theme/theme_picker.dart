import 'package:flutter/material.dart';
import '../core/session_store.dart';
import 'app_theme.dart';

class ThemePickerButton extends StatelessWidget {
  const ThemePickerButton({
    super.key,
    required this.sessionStore,
    this.onDark = false,
  });
  final SessionStore sessionStore;
  final bool onDark;

  Future<void> _chooseTheme(BuildContext context) async {
    final selected = await showModalBottomSheet<TrainerTheme>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose your theme',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Applied to every screen.'),
                const SizedBox(height: 16),
                for (final theme in TrainerTheme.values)
                  ListTile(
                    key: ValueKey(theme.name),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    selected: sessionStore.theme == theme,
                    leading: CircleAvatar(
                      backgroundColor: theme.accent,
                      child: Icon(
                        Icons.palette_outlined,
                        color: AppPalette.forTheme(theme).onAccent,
                      ),
                    ),
                    title: Text(theme.label),
                    subtitle: Text(
                      '${theme.description} · ${switch (theme) {
                        TrainerTheme.monochrome => 'Bottom navigation',
                        TrainerTheme.gold => 'Side navigation',
                        TrainerTheme.roseGold => 'Menu drawer',
                      }}',
                    ),
                    trailing: sessionStore.theme == theme
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: () => Navigator.of(context).pop(theme),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null) return;
    try {
      await sessionStore.setTheme(selected);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your theme. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _toggleMode(BuildContext context) async {
    try {
      await sessionStore.setDarkMode(!sessionStore.isDark);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save appearance. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: sessionStore.isDark
            ? 'Switch to light mode'
            : 'Switch to dark mode',
        onPressed: () => _toggleMode(context),
        color: onDark ? Colors.white : null,
        icon: Icon(
          sessionStore.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        ),
      ),
      TextButton.icon(
        onPressed: () => _chooseTheme(context),
        style: onDark
            ? TextButton.styleFrom(foregroundColor: Colors.white)
            : null,
        icon: const Icon(Icons.palette_outlined),
        label: const Text('Theme'),
      ),
    ],
  );
}
