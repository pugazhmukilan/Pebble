import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../data/expense_repository.dart';
import '../export/export_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Settings screen — export options live here, away from the home list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context, ExportFormatter formatter) async {
    final repository = context.read<ExpenseRepository>();
    final exportService = ExportService(repository);
    try {
      await exportService.export(formatter);
      if (context.mounted) {
        context.read<ExpenseCubit>().refreshExportDate();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTextStyles.monthHeader),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('EXPORT DATA', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 8),
          _ExportTile(
            icon: Icons.table_chart_rounded,
            title: 'Export as CSV',
            subtitle: 'All expenses, opens in any spreadsheet app',
            onTap: () => _export(context, CsvExportFormatter()),
          ),
          const SizedBox(height: 12),
          _ExportTile(
            icon: Icons.data_object_rounded,
            title: 'Export as JSON',
            subtitle: 'All expenses, machine-readable format',
            onTap: () => _export(context, JsonExportFormatter()),
          ),
          const SizedBox(height: 28),
          const Text('ABOUT', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pebble', style: AppTextStyles.expenseLabel),
                SizedBox(height: 4),
                Text(
                  'Manual-only expense tracking. Private, local, fast entry. '
                  'Your data never leaves your device.',
                  style: AppTextStyles.expenseNote,
                ),
                SizedBox(height: 12),
                Text('Version 0.2.0', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.expenseLabel),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.expenseNote),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
