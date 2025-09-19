import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../models/kosan.dart';
import '../../core/di.dart';
import '../map/map_screen.dart';
import '../explore/explore_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

class DetailScreen extends StatefulWidget {
  final Kosan kosan;
  
  const DetailScreen({super.key, required this.kosan});
  
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Kosan? _detailKosan;
  bool _loading = true;
  bool _isFavorite = false;
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    MapScreen(),
    ExploreScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }
  
  Future<void> _loadDetail() async {
    try {
      final response = await DI.api.raw.get('/api/kosan/${widget.kosan.id}');
      final data = response.data['data'] as Map<String, dynamic>;
      setState(() {
        _detailKosan = Kosan.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _detailKosan = widget.kosan;
        _loading = false;
      });
      
      // Show error dialog
      if (mounted) {
        _showErrorDialog();
      }
    }
  }
  
  void _showErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: CupertinoColors.systemRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text('Server Error'),
            ],
          ),
          content: Text('Data tidak ditemukan'),
          actions: [
            CupertinoDialogAction(
              child: Text('Coba Lagi'),
              onPressed: () {
                Navigator.of(context).pop();
                _loadDetail();
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final kosan = _detailKosan ?? widget.kosan;
    
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar dengan gambar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: CupertinoColors.white,
                leading: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CupertinoColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.black,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: _isFavorite ? CupertinoColors.systemRed : CupertinoColors.black,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.share,
                        color: CupertinoColors.black,
                      ),
                    ),
                    onPressed: () {
                      // Implementasi share
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _loading
                      ? Container(
                          color: CupertinoColors.systemGrey5,
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        )
                      : _buildImageCarousel(kosan),
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and title
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Rp 500.000',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.systemRed,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '120 Views',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kosan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (index) => const Icon(
                              CupertinoIcons.star_fill,
                              size: 16,
                              color: CupertinoColors.systemYellow,
                            )),
                            const SizedBox(width: 8),
                            const Text(
                              '(4.6)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '• 10 Review',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kosan.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
          
          // Bottom action buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          border: Border(
            top: BorderSide(
              color: CupertinoColors.systemGrey5,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Favorite button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.systemGrey4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: _isFavorite ? CupertinoColors.systemRed : CupertinoColors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Buy Now button
            Expanded(
              child: CupertinoButton(
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  'Sewa Sekarang',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  // Implementasi sewa
                },
              ),
            ),
          ],
        ),
      ),
    ),
    ],
  ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _currentIndex,
        items: const [
          Icon(CupertinoIcons.map, size: 30, color: Colors.white),
          Icon(CupertinoIcons.compass, size: 30, color: Colors.white),
          Icon(CupertinoIcons.bookmark, size: 30, color: Colors.white),
          Icon(CupertinoIcons.person, size: 30, color: Colors.white),
        ],
        onTap: (i) {
          setState(() {
            _currentIndex = i;
          });
          // Navigate to different screens based on index
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/map');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/explore');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/saved');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildImageCarousel(Kosan kosan) {
    List<String> images = [];
    if (kosan.imageUrls.isNotEmpty) {
      images = kosan.imageUrls;
    } else {
      final imageUrl = kosan.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images = [imageUrl];
      }
    }
    
    if (images.isEmpty) {
      return Container(
        color: CupertinoColors.systemGrey5,
        child: const Center(
          child: Icon(
            CupertinoIcons.photo,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
        ),
      );
    }
    
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  size: 64,
                  color: CupertinoColors.systemGrey3,
                ),
              ),
            );
          },
        );
      },
    );
  }
}