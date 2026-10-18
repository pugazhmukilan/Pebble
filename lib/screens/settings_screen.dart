import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../blocs/theme/theme_cubit.dart';
import '../data/expense_repository.dart';
import '../export/export_service.dart';
import '../export/sample_export_service.dart';
import '../import/import_service.dart';
import 'category_limits_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Settings screen — export options and appearance (theme) live here,
/// away from the home list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context, ExportFormatter formatter) async {
    final repository = context.read<ExpenseRepository>();
    final exportService = ExportService(repository);
    try {
      final path = await exportService.export(formatter);
      if (!context.mounted || path == null) return;
      context.read<ExpenseCubit>().refreshExportDate();
      _showDownloadSuccess(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  /// Pick a previously exported file and import its expenses.
  Future<void> _pickAndImport(
    BuildContext context,
    String extension,
    bool isJson,
  ) async {
    final repository = context.read<ExpenseRepository>();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final service = ImportService(repository);
      final res = isJson
          ? await service.importJson(content)
          : await service.importCsv(content);

      if (!context.mounted) return;
      // Refresh both the expense list and the category set.
      context.read<ExpenseCubit>().loadExpenses();

      final message = res.hasError
          ? 'Import failed: ${res.error}'
          : 'Imported ${res.importedExpenses} '
                'expense${res.importedExpenses == 1 ? '' : 's'}'
                '${res.createdCategories > 0 ? ', ${res.createdCategories} new '
                          'categor${res.createdCategories == 1 ? 'y' : 'ies'}' : ''}'
                '${res.skipped > 0 ? ', ${res.skipped} skipped' : ''}.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _downloadSample(BuildContext context, bool isJson) async {
    try {
      final path = isJson
          ? await const SampleExportService().saveSampleJson()
          : await const SampleExportService().saveSampleCsv();
      if (context.mounted && path != null) {
        _showDownloadSuccess(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save sample: $e')));
      }
    }
  }

  void _showDownloadSuccess(BuildContext context) {
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.signalIncome,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Downloaded successfully',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        title: Text('Settings', style: styles.screenTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          12,
          AppSpacing.screenMargin,
          32,
        ),
        children: [
          _SettingsSection(
            label: 'APPEARANCE',
            child: _AppearanceSelector(
              selected: themeMode,
              onSelected: (mode) => context.read<ThemeCubit>().setMode(mode),
            ),
          ),

          _SettingsSection(
            label: 'SPENDING LIMITS',
            child: _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.speed_rounded,
                  title: 'Category limits',
                  subtitle: 'Set monthly spending limits for your categories',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryLimitsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _SettingsSection(
            label: 'BACKUP DATA',
            child: _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.table_chart_rounded,
                  title: 'Export as CSV',
                  subtitle: 'Save a spreadsheet backup',
                  onTap: () => _export(context, CsvExportFormatter()),
                ),
                const Divider(indent: 56, endIndent: 16),
                _SettingsRow(
                  icon: Icons.data_object_rounded,
                  title: 'Export as JSON',
                  subtitle: 'Save a complete data backup',
                  onTap: () => _export(context, JsonExportFormatter()),
                ),
              ],
            ),
          ),

          _SettingsSection(
            label: 'IMPORT DATA',
            child: _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.upload_file_rounded,
                  title: 'Import CSV',
                  subtitle: 'Restore from a spreadsheet file',
                  onTap: () => _pickAndImport(context, 'csv', false),
                ),
                const Divider(indent: 56, endIndent: 16),
                _SettingsRow(
                  icon: Icons.upload_file_rounded,
                  title: 'Import JSON',
                  subtitle: 'Restore from a data backup',
                  onTap: () => _pickAndImport(context, 'json', true),
                ),
              ],
            ),
          ),

          _SettingsSection(
            label: 'SAMPLE FORMAT',
            child: _SampleFormatCard(
              onCsvTap: () => _downloadSample(context, false),
              onJsonTap: () => _downloadSample(context, true),
            ),
          ),

          _SettingsSection(
            label: 'ABOUT',
            child: _SettingsGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pebble', style: styles.listRowTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Manual-only expense tracking. Private, local, fast entry. '
                        'Your data never leaves your device.',
                        style: styles.body,
                      ),
                      const SizedBox(height: 12),
                      Text('Version 0.2.0', style: styles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final styles = AppTextStyles.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: styles.sectionLabel),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: styles.listRowTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: styles.body),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: colors.textTertiary,
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.selected, required this.onSelected});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _AppearanceOption(
                icon: option.$2,
                label: option.$3,
                selected: selected == option.$1,
                onTap: () => onSelected(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.textPrimary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colors.textPrimary : colors.textTertiary,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: styles.caption.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleFormatCard extends StatelessWidget {
  const _SampleFormatCard({required this.onCsvTap, required this.onJsonTap});

  final VoidCallback onCsvTap;
  final VoidCallback onJsonTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.file_download_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text('Download a sample file', style: styles.listRowTitle),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Use it as a template when importing your data.',
              style: styles.body,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SampleButton(label: 'CSV', onTap: onCsvTap),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SampleButton(label: 'JSON', onTap: onJsonTap),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sample download button ───────────────────────────────────────────────────

class _SampleButton extends StatelessWidget {
  const _SampleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return Material(
      color: colors.textPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
            border: Border.all(color: colors.borderHairline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(label, style: styles.chipLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
