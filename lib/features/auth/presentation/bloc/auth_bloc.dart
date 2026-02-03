import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../../../../network/api_service.dart';
import '../../data/session/auth_session_storage.dart';
import '../../data/session/auth_session_storage_hive.dart';
import '../../data/session/user_profile_storage_hive.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthRepository? repository, AuthSessionStorage? session})
    : _repo = repository ?? APIService().authRepository,
      _session = session ?? AuthSessionStorageHive.instance,
      super(const AuthState()) {
    on<UsernameChanged>(_onUsernameChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final AuthRepository _repo;
  final AuthSessionStorage? _session;
  final UserProfileStorage _profileStorage = UserProfileStorageHive.instance;
  final _log = getLogger('AuthBloc');

  void _onUsernameChanged(UsernameChanged event, Emitter<AuthState> emit) {
    final username = event.username.trim();
    emit(
      state.copyWith(
        username: username,
        usernameError: username.isEmpty ? 'Username is required' : null,
      ),
    );
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    final password = event.password;
    emit(
      state.copyWith(
        password: password,
        passwordError: password.isEmpty ? 'Password is required' : null,
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Validate
    final usernameError = state.username.isEmpty
        ? 'Username is required'
        : null;
    final passwordError = state.password.isEmpty
        ? 'Password is required'
        : null;

    if (usernameError != null || passwordError != null) {
      emit(
        state.copyWith(
          usernameError: usernameError,
          passwordError: passwordError,
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, apiError: null));
    try {
      final token = await _repo.login(
        username: state.username,
        password: state.password,
      );
      await _session?.write(token);
      // Fetch and persist user profile (non-blocking for navigation errors)
      try {
        final accessToken = token.access?.token;
        if (accessToken != null && accessToken.isNotEmpty) {
          final user = await _repo.getCurrentUser(accessToken: accessToken);
          await _profileStorage.write(user);
        }
      } catch (e) {
        _log.e('User fetch error: $e');
        // Do not fail login if user fetch fails; UI can retry later.
      }
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      _log.e('Login error: $e');
      emit(state.copyWith(isSubmitting: false, apiError: e.toString()));
    }
  }
}
