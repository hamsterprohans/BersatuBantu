/// Konfigurasi global untuk fitur Banner Carousel.
///
/// Cara mengontrol via CI/CD (ci-cd.yml):
/// ──────────────────────────────────────────
/// Untuk AKTIFKAN banner → pastikan ada env var di ci-cd.yml:
///   BANNER_ENABLED: true
///
/// Untuk NONAKTIFKAN banner → hapus atau comment baris tersebut:
///   # BANNER_ENABLED: true
///
/// Nilai ini diinjeksikan ke binary saat build via `--dart-define=BANNER_ENABLED=true`
/// di Dockerfile, sehingga tidak memerlukan perubahan kode apapun untuk toggle fitur.
/// ──────────────────────────────────────────
class BannerConfig {
  /// Membaca nilai BANNER_ENABLED dari dart-define saat build time.
  /// Default: false (banner tidak tampil jika env var tidak di-set).
  static bool get isEnabled =>
      const String.fromEnvironment('BANNER_ENABLED', defaultValue: 'false')
          .toLowerCase() ==
      'true';
}
