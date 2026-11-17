import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/domain/repositories/category_repository.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/expenses/domain/usecases/save_expense.dart';
import '../features/expenses/presentation/cubit/add_expense_cubit.dart';
import '../features/expenses/presentation/cubit/expense_list_cubit.dart';
import '../features/expenses/presentation/pages/add_expense_page.dart';
import '../features/expenses/presentation/pages/expense_list_page.dart';
import 'app_routes.dart';

GoRouter createRouter() => GoRouter(
  initialLocation: AppRoutes.expenses,
  routes: [
    GoRoute(
      path: AppRoutes.expenses,
      builder: (context, state) => BlocProvider(
        create: (_) => ExpenseListCubit(context.read<ExpenseRepository>()),
        child: const ExpenseListPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AddExpenseCubit(SaveExpense(context.read<ExpenseRepository>())),
          ),
          BlocProvider(
            create: (_) => CategoriesCubit(context.read<CategoryRepository>()),
          ),
        ],
        child: const AddExpensePage(),
      ),
    ),
  ],
);
