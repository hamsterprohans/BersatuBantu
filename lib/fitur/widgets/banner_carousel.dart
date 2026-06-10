import 'dart:async';
import 'package:flutter/material.dart';

/// Enum untuk tipe background banner
enum BannerImageType {
  /// Gambar dari assets lokal, misal: 'assets/banners/banner1.png'
  asset,

  /// Gambar dari URL internet
  network,

  /// Tidak pakai gambar — hanya gradient
  none,
}

/// Data model untuk setiap slide banner
///
/// CARA PAKAI GAMBAR CUSTOM:
/// ─────────────────────────────────────────────────────────────────────────
/// 1. Taruh file PNG hasil export Figma ke folder:
///       assets/banners/nama_banner.png
///
/// 2. Di BannerItem, isi field:
///       imageAsset: 'assets/banners/nama_banner.png'
///       imageType : BannerImageType.asset
///
/// 3. Kalau mau pakai URL (dari internet/Supabase storage):
///       imageAsset: 'https://..../banner.png'
///       imageType : BannerImageType.network
///
/// 4. Kalau tidak pakai gambar (hanya gradient):
///       imageType: BannerImageType.none   ← (default)
/// ─────────────────────────────────────────────────────────────────────────
///
/// CARA GANTI REDIRECT:
/// ─────────────────────────────────────────────────────────────────────────
/// Ubah bagian onTap: () => Navigator.push(...) di masing-masing dashboard:
///   • Personal  → lib/fitur/dashboard/dashboard_screen.dart
///   • Organisasi→ lib/fitur/dashboard/dashboard_organisasi.dart
///   • Admin     → lib/fitur/dashboard/admin_home.dart
/// ─────────────────────────────────────────────────────────────────────────
class BannerItem {
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  /// Path asset lokal (contoh: 'assets/banners/banner1.png')
  /// atau URL network (contoh: 'https://example.com/banner.png')
  /// Kosongkan / null jika tidak pakai gambar
  final String? imageAsset;

  /// Tipe sumber gambar. Default: BannerImageType.none (hanya gradient)
  final BannerImageType imageType;

  /// Jika pakai gambar, apakah teks + tombol tetap ditampilkan di atas gambar?
  /// Default: true
  final bool showTextOverImage;

  const BannerItem({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
    this.imageAsset,
    this.imageType = BannerImageType.none,
    this.showTextOverImage = true,
  });
}

/// Banner carousel yang auto-slide, clickable, dan berlaku semua role
class BannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final double height;
  final Duration autoPlayDuration;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 175,
    this.autoPlayDuration = const Duration(seconds: 4),
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                return _BannerCard(banner: banner);
              },
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicators
          if (widget.banners.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF364057)
                        : const Color(0xFF364057).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatefulWidget {
  final BannerItem banner;
  const _BannerCard({required this.banner});

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Buat widget gambar background (asset atau network)
  Widget? _buildBackgroundImage(BannerItem banner) {
    if (banner.imageType == BannerImageType.none || banner.imageAsset == null) {
      return null;
    }

    final ImageProvider imageProvider = banner.imageType == BannerImageType.asset
        ? AssetImage(banner.imageAsset!) as ImageProvider
        : NetworkImage(banner.imageAsset!);

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final hasImage = banner.imageType != BannerImageType.none &&
        banner.imageAsset != null;

    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        banner.onTap();
      },
      onTapCancel: () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Gradient tetap sebagai fallback / overlay base
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: banner.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: banner.gradientColors.last.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── LAYER 1: Gambar custom (jika ada) ──────────────────────
              if (hasImage) _buildBackgroundImage(banner)!,

              // ── LAYER 2: Overlay gelap tipis agar teks tetap terbaca ───
              if (hasImage && banner.showTextOverImage)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── LAYER 3: Dekorasi lingkaran (hanya jika tidak ada gambar) ─
              if (!hasImage) ...[
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Watermark icon
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      banner.icon,
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ],

              // ── LAYER 4: Konten teks + tombol ─────────────────────────
              if (!hasImage || banner.showTextOverImage)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Label pill di atas
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(banner.icon, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              banner.buttonText.split(' ').first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'CircularStd',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Judul, subtitle, dan tombol CTA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              fontFamily: 'CircularStd',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontFamily: 'CircularStd',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Tombol CTA
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              banner.buttonText,
                              style: TextStyle(
                                color: banner.gradientColors.first,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'CircularStd',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
