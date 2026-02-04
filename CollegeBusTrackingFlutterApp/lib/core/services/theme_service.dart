class ThemeState {
  final bool isDarkMode;

  const ThemeState({this.isDarkMode = false});

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}

class ThemeService {
  // No longer used as ChangeNotifier methods
}





