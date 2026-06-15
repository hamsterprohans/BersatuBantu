import 'package:bersatubantu/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bersatubantu/providers/volunteer_event_provider.dart';
import 'package:bersatubantu/fitur/pilihdaftar/register_volunteer_screen.dart'
    show EventDetailBottomSheet;
import 'package:bersatubantu/fitur/postingkegiatan/postingkegiatan.dart';
import 'package:bersatubantu/fitur/widgets/bottom_navbar.dart';
import 'package:bersatubantu/fitur/dashboard/dashboard_screen.dart';
import 'package:bersatubantu/fitur/donasi/donasi_screen.dart';
import 'package:bersatubantu/fitur/aturprofile/aturprofile.dart';

class AksiScreen extends StatefulWidget {
  final bool forceOrganizationMode;
  final int? requestId;

  const AksiScreen({
    super.key,
    this.forceOrganizationMode = false,
    this.requestId,
  });

  @override
  State<AksiScreen> createState() => _AksiScreenState();
}

class _AksiScreenState extends State<AksiScreen> {
  final int _selectedIndex = 2; // Aksi menu index
  final supabase = Supabase.instance.client;
  bool _isOrganization = false;
  String _selectedFilter = 'Semua';
  String _selectedCategory = 'Semua';

  final List<String> _filters = ['Semua', 'Aktif', 'Selesai'];
  final List<String> _categories = [
    'Semua',
    'Bencana Alam',
    'Pendidikan',
    'Kesehatan',
    'Kemiskinan',
  ];

  @override
  void initState() {
    super.initState();
    // If forceOrganizationMode is true, set _isOrganization directly
    if (widget.forceOrganizationMode) {
      _isOrganization = true;
    } else {
      _loadUserRole();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VolunteerEventProvider>(
        context,
        listen: false,
      ).loadOpenEvents();
    });
  }

  Future<void> _loadUserRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final resp = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = resp == null ? null : (resp['role'] as String?);
      if (mounted) {
        setState(() {
          _isOrganization = (role == 'organization');
        });
      }
    } catch (e) {
      // ignore errors; default to non-organization
      if (mounted) {
        setState(() {
          _isOrganization = false;
        });
      }
    }
  }

  void _openEventDetail(String eventId) {
    final userId = supabase.auth.currentUser?.id ?? '';
    final provider = Provider.of<VolunteerEventProvider>(
      context,
      listen: false,
    );
    provider.loadEventDetails(eventId: eventId, userId: userId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EventDetailBottomSheet(eventId: eventId, userId: userId),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Filter Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'CircularStd',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pilih Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'CircularStd',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) {
            return RadioListTile<String>(
              title: Text(category),
              value: category,
              groupValue: _selectedCategory,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (index == _selectedIndex) return;

    // Org mode: pop ke org dashboard dan kirim target index agar langsung dinavigasi
    if (widget.forceOrganizationMode) {
      Navigator.of(context).pop(index);
      return;
    }

    Widget screen;
    switch (index) {
      case 0:
        screen = const DashboardScreen();
        break;
      case 1:
        screen = const DonasiScreen();
        break;
      case 2:
        return;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryLightColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF364057),
                fontFamily: 'CircularStd',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aksi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'CircularStd',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Filter and Category buttons
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFilterButton(
                              icon: Icons.filter_list_rounded,
                              label: 'Filter',
                              onTap: () => _showFilterDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterButton(
                              icon: Icons.category_rounded,
                              label: 'Category',
                              onTap: () => _showCategoryDialog(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Tambah Aksi (hanya untuk organisasi)
                    if (_isOrganization)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final provider = Provider.of<VolunteerEventProvider>(context, listen: false);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostingKegiatanScreen(requestId: widget.requestId ?? 0),
                                ),
                              );
                              if (result == true && mounted) {
                                provider.loadOpenEvents();
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                            label: const Text(
                              'Tambah Aksi Baru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'CircularStd',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),

                    // Events list
                    Expanded(
                      child: Consumer<VolunteerEventProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoadingOpenEvents) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            );
                          }

                          // Filter events based on selected filters
                          final allEvents = provider.openEvents;
                          final filteredEvents = allEvents.where((e) {
                            // Filter by status
                            if (_selectedFilter != 'Semua') {
                              final now = DateTime.now();
                              final isCompleted = e.endTime.isBefore(now);

                              if (_selectedFilter == 'Aktif' && isCompleted) {
                                return false;
                              }
                              if (_selectedFilter == 'Selesai' && !isCompleted) {
                                return false;
                              }
                            }

                            // Filter by category (search in title, description)
                            if (_selectedCategory != 'Semua') {
                              final title = e.title.toLowerCase();
                              final description = (e.description ?? '')
                                  .toLowerCase();
                              final city = (e.city ?? '').toLowerCase();
                              final searchTerm = _selectedCategory
                                  .toLowerCase();

                              if (!title.contains(searchTerm) &&
                                  !description.contains(searchTerm) &&
                                  !city.contains(searchTerm)) {
                                return false;
                              }
                            }

                            return true;
                          }).toList();

                          if (filteredEvents.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.volunteer_activism_outlined,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada Kegiatan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                      fontFamily: 'CircularStd',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kegiatan volunteer akan muncul di sini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                      fontFamily: 'CircularStd',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => provider.loadOpenEvents(),
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Muat Ulang',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () => provider.loadOpenEvents(),
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, idx) {
                                final e = filteredEvents[idx];
                                return GestureDetector(
                                  onTap: () => _openEventDetail(e.id),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey[300]!,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: e.coverImageUrl != null
                                              ? Image.network(
                                                  e.coverImageUrl!,
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          height: 180,
                                                          color:
                                                              Colors.grey[200],
                                                          child: Icon(
                                                            Icons.image,
                                                            size: 50,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                        );
                                                      },
                                                )
                                              : Container(
                                                  height: 180,
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.volunteer_activism,
                                                    size: 50,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'CircularStd',
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(e.startTime)} WIB',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      e.location ??
                                                          e.city ??
                                                          'Lokasi tidak tersedia',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 12,
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
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            BottomNavBar(
              currentIndex: _selectedIndex,
              onTap: (index) => _navigateToScreen(context, index),
            ),
          ],
        ),
      ),

    );
  }
}
