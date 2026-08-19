import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/expense/expense_cubit.dart';
import 'blocs/onboarding/onboarding_cubit.dart';
import 'constants/categories.dart';
import 'data/expense_repository.dart';
import 'models/category.dart';
import 'models/expense.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Hive — uses app internal storage, no permissions needed
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseCategoryAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  Box<Expense> expenseBox;
  try {
    expenseBox = await Hive.openBox<Expense>('expenses');
  } catch (e) {
    // If old enum data causes parsing errors, wipe and start fresh
    await Hive.deleteBoxFromDisk('expenses');
    expenseBox = await Hive.openBox<Expense>('expenses');
  }

  Box<ExpenseCategory> categoryBox;
  try {
    categoryBox = await Hive.openBox<ExpenseCategory>('categories');
  } catch (e) {
    await Hive.deleteBoxFromDisk('categories');
    categoryBox = await Hive.openBox<ExpenseCategory>('categories');
  }

  // Wire concrete implementation (DI, §14)
  final repository = HiveExpenseRepository(expenseBox, categoryBox);

  // Seed default categories on first run
  await repository.initDefaultCategories(defaultCategories);

  // Check onboarding flag
  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

  runApp(PebbleApp(repository: repository, hasOnboarded: hasOnboarded));
}

class PebbleApp extends StatelessWidget {
  const PebbleApp({
    super.key,
    required this.repository,
    required this.hasOnboarded,
  });

  final HiveExpenseRepository repository;
  final bool hasOnboarded;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>.value(value: repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => OnboardingCubit()..checkOnboarding()),
          BlocProvider(create: (_) => ExpenseCubit(repository)..loadExpenses()),
        ],
        child: MaterialApp(
          title: 'Pebble',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: hasOnboarded ? const HomeScreen() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
