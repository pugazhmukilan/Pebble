import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../blocs/expense/expense_state.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/expense_entry_sheet.dart';
import '../widgets/expense_list.dart';
import '../widgets/month_header.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/total_summary_card.dart';
import 'settings_screen.dart';

/// Main screen: month header → total card → pie chart → expense list → FAB.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseCubit>(),
        child: const ExpenseEntrySheet(),
      ),
    );
  }

  void _openEditSheet(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseCubit>(),
        child: ExpenseEntrySheet(expense: expense),
      ),
    );
  }

  void _openMonthPicker(BuildContext context, int year, int month) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MonthPickerSheet(
        selectedYear: year,
        selectedMonth: month,
        onMonthSelected: (y, m) =>
            context.read<ExpenseCubit>().changeMonth(y, m),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            if (state is ExpenseLoading || state is ExpenseInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            if (state is ExpenseError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: AppTextStyles.cardLabel,
                ),
              );
            }
            final loaded = state as ExpenseLoaded;

            // Determine slide direction for animation
            final isForward = loaded.monthDirection == MonthDirection.forward;
            final isBackward =
                loaded.monthDirection == MonthDirection.backward;
            final key = ValueKey('${loaded.selectedYear}-${loaded.selectedMonth}');

            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 0) {
                  context.read<ExpenseCubit>().previousMonth();
                } else if (details.primaryVelocity! < 0) {
                  context.read<ExpenseCubit>().nextMonth();
                }
              },
              child: Column(
                children: [
                  // Fixed month header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: MonthHeader(
                            year: loaded.selectedYear,
                            month: loaded.selectedMonth,
                            hasNext: !loaded.isCurrentMonth,
                            onPrevious: () => context
                                .read<ExpenseCubit>()
                                .previousMonth(),
                            onNext: () =>
                                context.read<ExpenseCubit>().nextMonth(),
                            onCalendarTap: () => _openMonthPicker(
                              context,
                              loaded.selectedYear,
                              loaded.selectedMonth,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 4,
                          child: IconButton(
                            onPressed: () => _openSettings(context),
                            icon: const Icon(Icons.settings_rounded),
                            iconSize: 22,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated content area
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final isNewChild = child.key == key;
                        double begin;
                        if (isForward) {
                          begin = isNewChild ? 1.0 : -1.0;
                        } else if (isBackward) {
                          begin = isNewChild ? -1.0 : 1.0;
                        } else {
                          begin = 0.0;
                        }
                        if (begin == 0.0) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }
                        final slideTween = Tween<Offset>(
                          begin: Offset(begin, 0.0),
                          end: Offset.zero,
                        ).animate(animation);
                        final fadeTween = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.3, 1.0),
                          ),
                        );
                        return SlideTransition(
                          position: slideTween,
                          child: FadeTransition(
                            opacity: fadeTween,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: key,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    // Total summary card with category breakdown
                                    TotalSummaryCard(
                                      total: loaded.total,
                                      categoryBreakdown:
                                          loaded.categoryBreakdown,
                                      categories: loaded.categories,
                                      lastExportDate: loaded.lastExportDate,
                                    ),
                                    const SizedBox(height: 12),

                                    // Expense list
                                    ExpenseList(
                                      expenses: loaded.expenses,
                                      categories: loaded.categories,
                                      isCurrentMonth: loaded.isCurrentMonth,
                                      onDelete: (expense) => context
                                          .read<ExpenseCubit>()
                                          .deleteExpense(expense),
                                      onEdit: (expense) =>
                                          _openEditSheet(context, expense),
                                    ),

                                    // Bottom clearance for FAB
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // 4. Floating "+" button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
