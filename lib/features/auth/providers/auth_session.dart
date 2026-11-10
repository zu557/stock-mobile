import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const authTokenStorageKey = 'stock_flow_better_auth_bearer_token';

class AuthSessionEvents extends ChangeNotifier {
  void sessionExpired() => notifyListeners();
}

final authSessionEventsProvider = Provider<AuthSessionEvents>((ref) {
  final events = AuthSessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
