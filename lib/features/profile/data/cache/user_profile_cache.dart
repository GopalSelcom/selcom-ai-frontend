import '../../../../core/data/models/user_model.dart';

/// In-memory user profile for the current auth session.
///
/// Populated on the first [ProfileRepository.getProfile] network fetch (typically
/// Home load). Reused on Profile revisits until [clear] or logout.
/// [markChanged] / [consumeChanged] let Home refresh the header avatar after
/// edit without another GET.
abstract final class UserProfileCache {
  UserProfileCache._();

  /// True after the first successful profile fetch this session.
  static bool isLoaded = false;
  static UserModel? user;

  /// Set when [save] runs from [ProfileRepository.updateProfile]; consumed by Home.
  static bool _changedSinceLastHomeSync = false;

  static void save(UserModel model) {
    isLoaded = true;
    user = model;
  }

  /// Signals Home to apply the cached avatar when the user leaves Profile.
  static void markChanged() {
    _changedSinceLastHomeSync = true;
  }

  /// Returns whether profile changed since Home last synced; clears the flag.
  static bool consumeChanged() {
    if (!_changedSinceLastHomeSync) return false;
    _changedSinceLastHomeSync = false;
    return true;
  }

  /// Cleared on logout / session expiry — next login fetches profile again.
  static void clear() {
    isLoaded = false;
    user = null;
    _changedSinceLastHomeSync = false;
  }
}
