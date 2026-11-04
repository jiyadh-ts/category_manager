import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/app_database.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/categories/data/category_local_data_source.dart';
import 'features/categories/data/category_repository_impl.dart';
import 'features/categories/domain/category_repository.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/profile_repository.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final sessionStorage = SessionStorage(prefs);

  final database = AppDatabase();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final authRepository = AuthRepositoryImpl(dio);
  final profileRepository = ProfileRepositoryImpl(dio);
  final categoryRepository = CategoryRepositoryImpl(
    CategoryLocalDataSource(database),
  );

  runApp(
    CategoryManagerApp(
      authRepository: authRepository,
      profileRepository: profileRepository,
      categoryRepository: categoryRepository,
      sessionStorage: sessionStorage,
    ),
  );
}

class CategoryManagerApp extends StatefulWidget {
  const CategoryManagerApp({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.categoryRepository,
    required this.sessionStorage,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final CategoryRepository categoryRepository;
  final SessionStorage sessionStorage;

  @override
  State<CategoryManagerApp> createState() => _CategoryManagerAppState();
}

class _CategoryManagerAppState extends State<CategoryManagerApp> {
  late final AuthCubit _authCubit;
  late final CategoryCubit _categoryCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(
      repository: widget.authRepository,
      sessionStorage: widget.sessionStorage,
    );
    _categoryCubit = CategoryCubit(widget.categoryRepository);
    _appRouter = AppRouter(authCubit: _authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _categoryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepository),
        RepositoryProvider<ProfileRepository>.value(
          value: widget.profileRepository,
        ),
        RepositoryProvider<CategoryRepository>.value(
          value: widget.categoryRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<CategoryCubit>.value(value: _categoryCubit),
        ],
        child: MaterialApp.router(
          title: 'Category Manager',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
