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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Text('APPEARANCE', style: styles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
            child: Column(
              children: [
                _AppearanceTile(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  value: ThemeMode.system,
                  selected: themeMode,
                  onSelected: (mode) =>
                      context.read<ThemeCubit>().setMode(mode),
                ),
                const Divider(height: 1),
                _AppearanceTile(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  value: ThemeMode.light,
                  selected: themeMode,
                  onSelected: (mode) =>
                      context.read<ThemeCubit>().setMode(mode),
                ),
                const Divider(height: 1),
                _AppearanceTile(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  value: ThemeMode.dark,
                  selected: themeMode,
                  onSelected: (mode) =>
                      context.read<ThemeCubit>().setMode(mode),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text('SPENDING LIMITS', style: styles.sectionLabel),
          const SizedBox(height: 8),
          _ExportTile(
            icon: Icons.speed_rounded,
            title: 'Category limits',
            subtitle: 'Set monthly spending limits for your categories',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoryLimitsScreen()),
            ),
          ),

          // ── BACKUP DATA ─────────────────────────────────────────────────
          const SizedBox(height: 28),
          Text('BACKUP DATA', style: styles.sectionLabel),
          const SizedBox(height: 8),
          // CSV and JSON export in a single row
          Row(
            children: [
              Expanded(
                child: _CompactActionTile(
                  icon: Icons.table_chart_rounded,
                  label: 'CSV',
                  description: 'Save backup',
                  onTap: () => _export(context, CsvExportFormatter()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactActionTile(
                  icon: Icons.data_object_rounded,
                  label: 'JSON',
                  description: 'Save backup',
                  onTap: () => _export(context, JsonExportFormatter()),
                ),
              ),
            ],
          ),

          // ── IMPORT DATA ─────────────────────────────────────────────────
          const SizedBox(height: 28),
          Text('IMPORT DATA', style: styles.sectionLabel),
          const SizedBox(height: 8),
          // CSV and JSON import in a single row
          Row(
            children: [
              Expanded(
                child: _CompactActionTile(
                  icon: Icons.upload_file_rounded,
                  label: 'CSV',
                  description: 'Open file',
                  onTap: () => _pickAndImport(context, 'csv', false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactActionTile(
                  icon: Icons.upload_file_rounded,
                  label: 'JSON',
                  description: 'Open file',
                  onTap: () => _pickAndImport(context, 'json', true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── SAMPLE FORMAT ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Not sure about the format? Download a sample file to use as a template.',
                    style: styles.body,
                  ),
                ),
                const SizedBox(width: 10),
                _SampleButton(
                  label: 'CSV',
                  onTap: () => _downloadSample(context, false),
                ),
                const SizedBox(width: 6),
                _SampleButton(
                  label: 'JSON',
                  onTap: () => _downloadSample(context, true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text('ABOUT', style: styles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
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
    );
  }
}

// ── Appearance tile (unchanged) ──────────────────────────────────────────────

/// Radio-style tile for choosing a theme mode.
class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final isSelected = value == selected;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: styles.listRowTitle)),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Large tile (category limits) ─────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderHairline, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: colors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: styles.listRowTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: styles.body),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Compact half-width action tile (export/import CSV | JSON row) ─────────────

class _CompactActionTile extends StatelessWidget {
  const _CompactActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderHairline, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: colors.textPrimary),
            const SizedBox(height: 6),
            Text(label, style: styles.listRowTitle.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(description, style: styles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Inline "Download sample" button ─────────────────────────────────────────

class _SampleButton extends StatelessWidget {
  const _SampleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderHairline, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 14, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: styles.caption),
          ],
        ),
      ),
    );
  }
}
