import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/new_dashboard_screen.dart';
import '../add_patient_screen.dart';
import '../search_screen.dart';
import '../reports_screen.dart';
import '../patient_details_screen.dart';
import '../design_system/design_system_screen.dart';

/// Определение всех route names для типобезопасного использования.
abstract class AppRoutes {
  static const root = 'root';
  static const dashboard = 'dashboard';
  static const patient = 'patient';
  static const addPatient = 'addPatient';
  static const search = 'search';
  static const reports = 'reports';
}

/// Центральный GoRouter приложения.
/// Позже его можно расширить guard-ами, редиректами и пр.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Витрина дизайн‑системы (отдельный корневой маршрут)
    GoRoute(
      path: '/design-system',
      builder: (context, state) => const DesignSystemScreen(),
    ),
    // Корневой раздел с вложенными маршрутами
    GoRoute(
      name: AppRoutes.root,
      path: '/',
      builder: (context, state) => const NewDashboardScreen(),
      routes: [
        GoRoute(
          name: AppRoutes.patient,
          path: 'patient/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return PatientDetailsScreen(patientId: id ?? '');
          },
        ),
        GoRoute(
          name: AppRoutes.dashboard,
          path: 'dashboard/:id',
          builder: (context, state) => const NewDashboardScreen(),
        ),
        GoRoute(
          name: AppRoutes.addPatient,
          path: 'add',
          builder: (context, state) => AddPatientScreen(),
        ),
        GoRoute(
          name: AppRoutes.search,
          path: 'search',
          builder: (context, state) => SearchScreen(),
        ),
        GoRoute(
          name: AppRoutes.reports,
          path: 'reports',
          builder: (context, state) => ReportsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    );
  },
);
