import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/user_repository.dart';

import 'dashboard_screen.dart';
import 'scan_history_screen.dart';
import 'profile_screen.dart';
import 'package:mobile/features/scanner/presentation/screens/ocr_scanner_screen.dart';
import 'package:mobile/features/user/presentation/widgets/liquid_nav_bar.dart';

class MainNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final mainNavigationProvider = NotifierProvider<MainNavigationNotifier, int>(MainNavigationNotifier.new);

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  final PageController _pageController = PageController();
  bool _hasCheckedProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedProfile) {
        _checkProfileStatus();
      }
    });
  }

  Future<void> _checkProfileStatus() async {
    _hasCheckedProfile = true;
    try {
      // Import needed for user_repository
      final repo = ref.read(userRepositoryProvider);
      final profile = await repo.fetchProfile();
      if (profile != null) {
        final age = profile['age'];
        final hasName = profile['full_name'] != null && profile['full_name'].toString().isNotEmpty;
        if (!hasName || age == null || age == 0) {
          if (mounted) {
            context.push('/health_profile', extra: true);
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (ref.read(mainNavigationProvider) != index) {
      ref.read(mainNavigationProvider.notifier).setIndex(index);
    }
  }

  void _onNavItemTapped(int index) {
    ref.read(mainNavigationProvider.notifier).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainNavigationProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        if (previous != null && (previous - next).abs() > 1) {
          _pageController.jumpToPage(next);
        } else {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    final currentIndex = ref.watch(mainNavigationProvider);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _onNavItemTapped(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              DashboardScreen(),
              ScanHistoryScreen(),
              OcrScannerScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidNavBar(
              selectedIndex: currentIndex,
              onItemSelected: _onNavItemTapped,
            ),
          ),
        ],
      ),
    ));
  }
}
