import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/database/app_database.dart';
import '../core/theme/app_theme.dart';
import '../features/categories/data/repositories/category_repository_impl.dart';
import '../features/categories/domain/repositories/category_repository.dart';
import '../features/expenses/data/repositories/expense_repository_impl.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import 'app_router.dart';

class SpendWiseApp extends StatefulWidget {
  const SpendWiseApp({super.key, required this.database});

  final AppDatabase database;

  @override
  State<SpendWiseApp> createState() => _SpendWiseAppState();
}

class _SpendWiseAppState extends State<SpendWiseApp> {
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>(
          create: (_) => ExpenseRepositoryImpl(widget.database),
        ),
        RepositoryProvider<CategoryRepository>(
          create: (_) => CategoryRepositoryImpl(widget.database),
        ),
      ],
      child: MaterialApp.router(
        title: 'SpendWise IQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
