import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/repositories/access_repository.dart';

final qrCodeProvider =
    StateNotifierProvider.autoDispose<QrCodeNotifier, AsyncValue<String?>>(
        (ref) {
  return QrCodeNotifier(ref);
});

class QrCodeNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  QrCodeNotifier(this._ref) : super(const AsyncData(null));

  // --- MÉTODO ACTUALIZADO ---
  Future<void> generateQr(String visitorName, String identityCard,
      DateTime scheduledAt, DateTime scheduledExit) async {
    // Nuevo parámetro

    state = const AsyncLoading();

    try {
      final repo = _ref.read(accessRepoProvider);

      // Enviamos los 4 datos
      final qrToken = await repo.generateQrCode(
          visitorName, identityCard, scheduledAt, scheduledExit);

      state = AsyncData(qrToken);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
