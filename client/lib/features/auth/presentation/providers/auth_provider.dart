import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = AsyncNotifierProvider<AuthNotifier, Map<String, dynamic>?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).login(email, password);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalDetails,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            role: role,
            additionalDetails: additionalDetails,
          );
    });
  }

}
