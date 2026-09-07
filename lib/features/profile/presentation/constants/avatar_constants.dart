class ProfileAvatars {
  ProfileAvatars._();

  static const String defaultAvatarId = 'avatar_01';

  static const Map<String, String> avatarMap = {
    'avatar_01': 'assets/images/auth/avatar_01.png',
    'avatar_02': 'assets/images/auth/avatar_02.png',
    'avatar_03': 'assets/images/auth/avatar_03.png',
  };

  static const List<String> allIds = [
    'avatar_01',
    'avatar_02',
    'avatar_03',
  ];

  static String assetPathFor(String? avatarId) {
    if (avatarId != null && avatarMap.containsKey(avatarId)) {
      return avatarMap[avatarId]!;
    }
    return avatarMap[defaultAvatarId]!;
  }
}
