class ThemeState {
  final bool isDarkMode;
  final String mapTheme;
  final int accentColorValue;

  const ThemeState({
    this.isDarkMode = false,
    this.mapTheme = 'auto',
    this.accentColorValue = 0xFF00C6E6,
  });

  ThemeState copyWith({bool? isDarkMode, String? mapTheme, int? accentColorValue}) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      mapTheme: mapTheme ?? this.mapTheme,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }
}

class ThemeService {
  // No longer used as ChangeNotifier methods
}





