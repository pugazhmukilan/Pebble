import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../data/expense_repository.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';

class CategoryLimitsScreen extends StatefulWidget {
  const CategoryLimitsScreen({super.key});

  @override
  State<CategoryLimitsScreen> createState() => _CategoryLimitsScreenState();
}

class _CategoryLimitsScreenState extends State<CategoryLimitsScreen> {
  late Future<_LimitPageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_LimitPageData> _loadData() async {
    final repository = context.read<ExpenseRepository>();
    final now = DateTime.now();
    return _LimitPageData(
      categories: await repository.getCategories(),
      limits: await repository.getCategoryLimits(now.year, now.month),
    );
  }

  Future<void> _editLimit(
    ExpenseCategory category,
    double? currentLimit,
  ) async {
    // Capture the cubit before the async gap using the State's own context.
    final cubit = context.read<ExpenseCubit>();

    final result = await showDialog<_LimitDialogResult>(
      context: context,
      builder: (_) => _LimitDialog(
        categoryLabel: category.label,
        currentLimit: currentLimit,
      ),
    );

    if (!mounted || result == null) return;

    try {
      if (result.action == _LimitAction.unset) {
        await cubit.unsetCategoryLimit(category.id);
      } else if (result.action == _LimitAction.set) {
        final limit = double.tryParse(result.input);
        if (limit == null || limit <= 0) {
          // Use mounted (State property) instead of context.mounted from
          // an item-builder context that may no longer be valid.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter a limit greater than zero')),
            );
          }
          return;
        }
        await cubit.setCategoryLimit(category.id, limit);
      } else {
        return;
      }

      // Reload page data after a successful change.
      if (mounted) {
        setState(() {
          _data = _loadData();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update limit: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        title: Text('Category limits', style: styles.screenTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<_LimitPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Could not load limits: ${snapshot.error}'),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: data.categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = data.categories[index];
              final limit = data.limits[category.id];
              return _LimitTile(
                category: category,
                limit: limit,
                onTap: () => _editLimit(category, limit),
              );
            },
          );
        },
      ),
    );
  }
}

enum _LimitAction { set, unset }

class _LimitPageData {
  const _LimitPageData({required this.categories, required this.limits});

  final List<ExpenseCategory> categories;
  final Map<String, double> limits;
}

class _LimitDialogResult {
  const _LimitDialogResult(this.action, this.input);

  final _LimitAction action;
  final String input;
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({required this.categoryLabel, required this.currentLimit});

  final String categoryLabel;
  final double? currentLimit;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit == null ? '' : widget.currentLimit.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.categoryLabel} limit'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Monthly limit',
          prefixText: '₹ ',
        ),
      ),
      actions: [
        if (widget.currentLimit != null)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const _LimitDialogResult(_LimitAction.unset, '')),
            child: const Text('Remove limit'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_LimitDialogResult(_LimitAction.set, _controller.text.trim())),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.category,
    required this.limit,
    required this.onTap,
  });

  final ExpenseCategory category;
  final double? limit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderHairline, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(child: Text(category.label, style: styles.listRowTitle)),
            Text(
              limit == null
                  ? 'No limit'
                  : '₹${formatCompactAmount(limit!)} / month',
              style: styles.body,
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
