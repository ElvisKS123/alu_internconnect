import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_cubit.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/opportunities/bloc/opportunity_cubit.dart';
import 'features/opportunities/repositories/opportunity_repository.dart';
import 'features/applications/bloc/application_cubit.dart';
import 'features/applications/repositories/application_repository.dart';
import 'features/startup/repositories/startup_repository.dart';
import 'config/router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ALUInternConnectApp());
}

class ALUInternConnectApp extends StatelessWidget {
  const ALUInternConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _FirebaseSetupNotice(),
      );
    }

    // Instantiate repositories once
    final authRepository = AuthRepository();
    final opportunityRepository = OpportunityRepository();
    final applicationRepository = ApplicationRepository();
    final startupRepository = StartupRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<OpportunityRepository>.value(
            value: opportunityRepository),
        RepositoryProvider<ApplicationRepository>.value(
            value: applicationRepository),
        RepositoryProvider<StartupRepository>.value(value: startupRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) =>
                AuthCubit(authRepository: authRepository),
          ),
          BlocProvider<OpportunityCubit>(
            create: (_) =>
                OpportunityCubit(repository: opportunityRepository),
          ),
          BlocProvider<ApplicationCubit>(
            create: (_) =>
                ApplicationCubit(repository: applicationRepository),
          ),
        ],
        child: _AppRouter(),
      ),
    );
  }
}

class _FirebaseSetupNotice extends StatelessWidget {
  const _FirebaseSetupNotice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                'Firebase is not ready yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The app will continue once Firebase is configured for this platform.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppRouter extends StatefulWidget {
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ALU InternConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
