import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/login_user.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go('/categories');
            }
          },
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AuthError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<AuthCubit>().loadUsers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is AuthUsersLoaded) {
              return _LoginForm(state: state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.state});

  final AuthUsersLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'This is mock authentication using JSONPlaceholder. '
          'Select a user from the API to continue.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: state.selectedUsername,
          decoration: InputDecoration(
            labelText: 'Select user',
            errorText: state.validationMessage,
          ),
          items: state.users.map((LoginUser user) {
            return DropdownMenuItem<String>(
              value: user.username,
              child: Text('${user.name} (${user.username})'),
            );
          }).toList(),
          onChanged: (username) {
            context.read<AuthCubit>().selectUsername(username);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.read<AuthCubit>().login(),
          child: const Text('Login'),
        ),
      ],
    );
  }
}
