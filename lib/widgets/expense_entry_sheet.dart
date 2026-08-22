import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../blocs/expense/expense_state.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'category_grid.dart';
import 'date_chip_selector.dart';

/// Shared bottom sheet for BOTH add and edit flows (§7).
/// [expense] is null for add mode, non-null for edit mode.
class ExpenseEntrySheet extends StatefulWidget {
  const ExpenseEntrySheet({super.key, this.expense});

  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<ExpenseEntrySheet> createState() => _ExpenseEntrySheetState();
}

class _ExpenseEntrySheetState extends State<ExpenseEntrySheet> {
  late DateTime _selectedDate;
  String? _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final e = widget.expense!;
      _selectedDate = e.date;
      _selectedCategory = e.categoryId;
      _amountController = TextEditingController(
        text: _formatInitialAmount(e.amount),
      );
      _noteController = TextEditingController(text: e.note ?? '');
    } else {
      _selectedDate = DateTime.now();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
    }

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {}); // trigger rebuild to update submit button status
  }

  /// Format the initial amount for editing — no trailing zeros for whole numbers.
  String _formatInitialAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCategory != null &&
      _amountController.text.trim().isNotEmpty &&
      _parseAmount() > 0;

  double _parseAmount() => double.tryParse(_amountController.text.trim()) ?? 0;

  void _submit() {
    if (!_canSubmit) return;
    final cubit = context.read<ExpenseCubit>();
    final amount = _parseAmount();
    final note = _noteController.text.trim();

    if (widget.isEditing) {
      cubit.updateExpense(
        widget.expense!,
        amount: amount,
        categoryId: _selectedCategory!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      );
    } else {
      cubit.addExpense(
        amount: amount,
        categoryId: _selectedCategory!,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final categories = context.select((ExpenseCubit cubit) {
      final state = cubit.state;
      if (state is ExpenseLoaded) return state.categories;
      return <ExpenseCategory>[];
    });

    return SafeArea(
      child: BlocListener<ExpenseCubit, ExpenseState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is ExpenseLoaded) {
            final ids = state.categories.map((c) => c.id).toSet();
            if (_selectedCategory != null && !ids.contains(_selectedCategory)) {
              setState(() => _selectedCategory = null);
            }
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scrollable forms
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount field with native keyboard
                      TextField(
                        controller: _amountController,
                        autofocus: !widget.isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: styles.totalAmount,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '₹',
                              style: styles.totalAmount,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date chips
                      DateChipSelector(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) =>
                            setState(() => _selectedDate = date),
                      ),
                      const SizedBox(height: 24),

                      // Category grid
                      CategoryGrid(
                        categories: categories,
                        selectedCategoryId: _selectedCategory,
                        onCategorySelected: (catId) =>
                            setState(() => _selectedCategory = catId),
                      ),
                      const SizedBox(height: 24),

                      // Note field
                      TextField(
                        controller: _noteController,
                        style: styles.listRowTitle,
                        decoration: InputDecoration(
                          hintText: 'Add a note (optional)',
                          hintStyle: styles.body,
                          filled: true,
                          fillColor: colors.surfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Submit button — "Log expense" (add) or "Save changes" (edit)
              // Pinned at the bottom above the keyboard
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? colors.textPrimary
                        : colors.textTertiary,
                    foregroundColor: colors.surfaceRaised,
                    disabledBackgroundColor: colors.textTertiary,
                    disabledForegroundColor: colors.surfaceRaised
                        .withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isEditing ? 'Save changes' : 'Log expense',
                    style: styles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}