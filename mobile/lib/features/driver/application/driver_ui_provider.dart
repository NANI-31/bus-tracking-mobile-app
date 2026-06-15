import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DriverDialogType {
  none,
  completeTrip,
  acceptAssignment,
  declineAssignment,
}

class DriverUiState {
  final int bottomNavIndex;
  final bool showDisconnectedBanner;
  final double sheetExtent;
  final DriverDialogType activeDialog;

  const DriverUiState({
    this.bottomNavIndex = 0,
    this.showDisconnectedBanner = false,
    this.sheetExtent = 0.18,
    this.activeDialog = DriverDialogType.none,
  });

  DriverUiState copyWith({
    int? bottomNavIndex,
    bool? showDisconnectedBanner,
    double? sheetExtent,
    DriverDialogType? activeDialog,
  }) {
    return DriverUiState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      showDisconnectedBanner: showDisconnectedBanner ?? this.showDisconnectedBanner,
      sheetExtent: sheetExtent ?? this.sheetExtent,
      activeDialog: activeDialog ?? this.activeDialog,
    );
  }
}

class DriverUiNotifier extends StateNotifier<DriverUiState> {
  DriverUiNotifier() : super(const DriverUiState());

  void setBottomNavIndex(int index) {
    state = state.copyWith(bottomNavIndex: index);
  }

  void setShowDisconnectedBanner(bool show) {
    state = state.copyWith(showDisconnectedBanner: show);
  }

  void setSheetExtent(double extent) {
    state = state.copyWith(sheetExtent: extent);
  }

  void showDialogType(DriverDialogType type) {
    state = state.copyWith(activeDialog: type);
  }

  void clearDialog() {
    state = state.copyWith(activeDialog: DriverDialogType.none);
  }
}

final driverUiStateProvider =
    StateNotifierProvider<DriverUiNotifier, DriverUiState>((ref) {
  return DriverUiNotifier();
});
