import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'organization_setup_screen.dart';
import 'organizations_controller.dart';

class OrganizationEditScreen extends ConsumerWidget {
  final int organizationId;

  const OrganizationEditScreen({super.key, required this.organizationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationProvider(organizationId));
    return orgAsync.when(
      data: (org) => OrganizationSetupScreen(initial: org),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
