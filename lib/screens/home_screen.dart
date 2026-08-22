import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/expense/expense_cubit.dart';
import '../blocs/expense/expense_state.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/expense_entry_sheet.dart';
import '../widgets/expense_list.dart';
import '../widgets/month_header.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/total_summary_card.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';

/// Main screen: month header → total card → pie chart → expense list → FAB.
/// The obscure toggle hides amount figures and remembers the preference.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _obscureKey = 'obscure_amounts';
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _loadObscurePreference();
  }

  Future<void> _loadObscurePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _obscured = prefs.getBool(_obscureKey) ?? false);
    }
  }

  Future<void> _toggleObscured() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_obscured;
    setState(() => _obscured = next);
    await prefs.setBool(_obscureKey, next);
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
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
      backgroundColor: AppColors.of(context).surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
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
      backgroundColor: AppColors.of(context).surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
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

  void _openAnalysis(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/pebble_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        title: Text('Pebble', style: styles.screenTitle),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _openAnalysis(context),
            icon: const Icon(Icons.bar_chart_rounded),
            iconSize: 22,
            color: colors.textPrimary,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.tune_rounded),
            iconSize: 22,
            color: colors.textPrimary,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            if (state is ExpenseLoading || state is ExpenseInitial) {
              return Center(
                child: CircularProgressIndicator(color: colors.textPrimary),
              );
            }
            if (state is ExpenseError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: styles.cardLabel,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
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
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    // Total summary card with category breakdown
                                    TotalSummaryCard(
                                      total: loaded.total,
                                      previousMonthTotal:
                                          loaded.previousMonthTotal,
                                      categoryBreakdown:
                                          loaded.categoryBreakdown,
                                      categories: loaded.categories,
                                      lastExportDate: loaded.lastExportDate,
                                      obscured: _obscured,
                                      onToggleObscured: _toggleObscured,
                                    ),
                                    const SizedBox(height: 12),

                                    // Expense list
                                    ExpenseList(
                                      expenses: loaded.expenses,
                                      categories: loaded.categories,
                                      isCurrentMonth: loaded.isCurrentMonth,
                                      obscured: _obscured,
                                      onDelete: (expense) => context
                                          .read<ExpenseCubit>()
                                          .deleteExpense(expense),
                                      onEdit: (expense) =>
                                          _openEditSheet(context, expense),
                                    ),

                                    // Bottom clearance for FAB (height + 24)
                                    const SizedBox(height: AppSpacing.fabClearance),
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