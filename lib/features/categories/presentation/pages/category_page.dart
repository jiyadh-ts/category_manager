import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tile.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addRootCategory() async {
    final name = await showCategoryFormDialog(
      context: context,
      title: 'Add root category',
    );
    if (name == null || !mounted) {
      return;
    }

    await context.read<CategoryCubit>().addCategory(name: name);
  }

  Future<void> _logout() async {
    await context.read<AuthCubit>().logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRootCategory,
        tooltip: 'Add root category',
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                context.read<CategoryCubit>().search(value);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocConsumer<CategoryCubit, CategoryState>(
                listener: (context, state) {
                  if (state is CategoryLoaded && state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage!)),
                    );
                    context.read<CategoryCubit>().clearErrorMessage();
                  }
                },
                builder: (context, state) {
                  if (state is CategoryLoading || state is CategoryInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CategoryError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CategoryCubit>().loadCategories();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CategoryLoaded) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total categories: ${state.totalCount}'),
                        const SizedBox(height: 8),
                        Expanded(child: CategoryTreeList(state: state)),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
