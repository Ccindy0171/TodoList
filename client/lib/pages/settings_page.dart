import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, localizations.theme),
          _buildThemeSelector(context, themeProvider, localizations),
          const Divider(),
          _buildSectionHeader(context, localizations.language),
          _buildLanguageSelector(context, localizationProvider, localizations),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider, AppLocalizations localizations) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: Text(localizations.lightTheme),
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Text(localizations.darkTheme),
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Text(localizations.systemTheme),
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildLanguageSelector(BuildContext context, LocalizationProvider localizationProvider, AppLocalizations localizations) {
    return Column(
      children: [
        RadioListTile<Locale>(
          title: Text(localizations.english),
          value: LocalizationProvider.enLocale,
          groupValue: localizationProvider.locale,
          onChanged: (Locale? value) {
            if (value != null) {
              localizationProvider.setLocale(value);
            }
          },
        ),
        RadioListTile<Locale>(
          title: Text(localizations.chinese),
          value: LocalizationProvider.zhLocale,
          groupValue: localizationProvider.locale,
          onChanged: (Locale? value) {
            if (value != null) {
              localizationProvider.setLocale(value);
            }
          },
        ),
      ],
    );
  }
} 