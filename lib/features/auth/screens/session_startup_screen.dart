import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';

class SessionStartupScreen extends ConsumerWidget {
  const SessionStartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: auth.when(
          loading: () => const CircularProgressIndicator(),
          data: (_) => const CircularProgressIndicator(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 44),
                const SizedBox(height: 12),
                const Text('Could not check your sign-in session.'),
                const SizedBox(height: 8),
                Text(
                  ApiException.messageFor(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authProvider.notifier).retryInitialization(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
