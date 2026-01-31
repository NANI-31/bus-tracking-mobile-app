class ThemeState {
  final bool isDarkMode;
  final bool useBottomNavigation;

  const ThemeState({this.isDarkMode = false, this.useBottomNavigation = false});

  ThemeState copyWith({bool? isDarkMode, bool? useBottomNavigation}) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      useBottomNavigation: useBottomNavigation ?? this.useBottomNavigation,
    );
  }
}

class ThemeService {
  // No longer used as ChangeNotifier methods
}
