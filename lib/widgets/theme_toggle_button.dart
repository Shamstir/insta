import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone/providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showText;
  final IconData? customIcon;
  
  const ThemeToggleButton({
    Key? key,
    this.showText = true,
    this.customIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                themeProvider.toggleTheme();
                
                // Show a snackbar with the current theme
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      themeProvider.isDarkMode 
                        ? 'Switched to Dark Mode' 
                        : 'Switched to Light Mode',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showText ? 16 : 12,
                  vertical: showText ? 12 : 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      customIcon ?? (themeProvider.isDarkMode 
                        ? Icons.light_mode 
                        : Icons.dark_mode),
                      size: 20,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    if (showText) ...[
                      const SizedBox(width: 8),
                      Text(
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative simple icon button version
class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode 
              ? Icons.light_mode_outlined 
              : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: themeProvider.isDarkMode 
            ? 'Switch to Light Mode' 
            : 'Switch to Dark Mode',
        );
      },
    );
  }
}

// Theme toggle list tile for settings pages
class ThemeToggleListTile extends StatelessWidget {
  const ThemeToggleListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(
            themeProvider.isDarkMode 
              ? Icons.dark_mode 
              : Icons.light_mode,
          ),
          title: const Text('Dark Mode'),
          subtitle: Text(
            themeProvider.isDarkMode 
              ? 'Currently using dark theme' 
              : 'Currently using light theme',
          ),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          onTap: () {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}
