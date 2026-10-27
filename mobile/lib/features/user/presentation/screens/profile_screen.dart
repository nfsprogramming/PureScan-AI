// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/error_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:mobile/features/user/data/user_repository.dart';
import 'package:mobile/features/user/presentation/providers/local_avatar_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _userName = 'Loading...';
  String _userInitials = '...';
  List<String> _allergies = [];
  List<String> _diets = [];
  List<String> _healthGoals = [];
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ref.read(userRepositoryProvider).fetchProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['full_name']?.isNotEmpty == true ? profile['full_name'] : 'Health Conscious User';
          _userInitials = _userName.isNotEmpty ? _userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() : 'U';
          if (_userInitials.isEmpty) _userInitials = 'U';
          _allergies = List<String>.from(profile['allergies'] ?? []);
          _diets = List<String>.from(profile['diets'] ?? []);
          _healthGoals = List<String>.from(profile['health_goals'] ?? []);
          _profileImageUrl = profile['profile_image'];
        });
      }
    } catch (e) {
      // Ignore errors and keep defaults
      if (mounted) {
        setState(() {
          _userName = 'Health Conscious User';
          _userInitials = 'U';
          _allergies = [];
          _diets = [];
          _healthGoals = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Top App Bar
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            leadingWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PureScan AI',
                    style: GoogleFonts.playfairDisplay(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () async {
                  await context.push('/settings');
                  _loadUserProfile();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Intro
                Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _uploadProfilePhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final localAvatar = ref.watch(localAvatarProvider);
                              return Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                                      blurRadius: 30,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  image: localAvatar != null
                                      ? DecorationImage(
                                          image: FileImage(File(localAvatar)),
                                          fit: BoxFit.cover,
                                        )
                                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty 
                                          ? DecorationImage(
                                              image: NetworkImage(_profileImageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                                ),
                                child: _isUploading 
                                  ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary) 
                                  : ((localAvatar == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                      ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 48)
                                      : null),
                              );
                            }
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.surface, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Dietary Preferences Card
                GestureDetector(
                  onTap: () async {
                    await context.push('/health_profile'); // The old profile screen for dietary preferences
                    _loadUserProfile();
                  },
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Health Profile',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Manage your personal details, vitals, and dietary preferences',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE1E3E4)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Allergies',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await context.push('/health_profile');
                                _loadUserProfile();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allergies.isEmpty
                              ? [Text('No allergies selected', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontStyle: FontStyle.italic))]
                              : _allergies.map((a) => _buildChip(a)).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Diets',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await context.push('/health_profile');
                                _loadUserProfile();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _diets.isEmpty
                              ? [Text('No diets selected', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontStyle: FontStyle.italic))]
                              : _diets.map((d) => _buildChip(d)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Health Goals Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Health Goals',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await context.push('/health_profile');
                              _loadUserProfile();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_healthGoals.isEmpty)
                        Text('No health goals selected', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontStyle: FontStyle.italic))
                      else
                        ..._healthGoals.map((goal) {
                          IconData icon = Icons.check_circle_outline;
                          Color iconColor = Theme.of(context).colorScheme.primary;
                          Color bgColor = Theme.of(context).colorScheme.secondary;
                          
                          if (goal.contains('Heart')) {
                            icon = Icons.favorite;
                            iconColor = Color(0xFFBA1A1A);
                            bgColor = Color(0xFFFFDAD6);
                          } else if (goal.contains('Sugar')) {
                            icon = Icons.water_drop;
                          } else if (goal.contains('Weight')) {
                            icon = Icons.fitness_center;
                          } else if (goal.contains('Protein')) {
                            icon = Icons.restaurant;
                          } else if (goal.contains('Energy')) {
                            icon = Icons.bolt;
                          } else if (goal.contains('Digestive')) {
                            icon = Icons.spa;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildGoalRow(icon, goal, iconColor, bgColor),
                          );
                        }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Links List
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildLinkItem('My Health Profile', () async { 
                        await context.push('/health_profile');
                        _loadUserProfile();
                      }),
                      Padding(
                        padding: EdgeInsets.only(left: 56),
                        child: Divider(height: 1, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
                      ),
                      _buildLinkItem('Saved Ingredients', () => context.push('/bookmarks')),
                      _buildLinkItem('Notification Settings', () {
                        context.push('/settings/notifications');
                      }),
                      _buildLinkItem('Appearance & Themes', () {
                        context.push('/settings/theme');
                      }),
                      _buildLinkItem('Saved Products', () {
                        context.push('/saved_products');
                      }),
                      _buildLinkItem('Scientific Sources', () => context.push('/scientific_sources')),
                      _buildLinkItem('Help & Support', () => context.push('/help_support'), isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // padding for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildGoalRow(IconData icon, String label, Color iconColor, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(String title, VoidCallback onTap, {bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(
            bottom: BorderSide(color: Color(0xFFE1E3E4), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileExt = image.name.split('.').last;
      final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, File(image.path));

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await ref.read(userRepositoryProvider).updateProfileImage(imageUrl);

      // Save locally so the UI updates immediately on all screens without network dependency
      await ref.read(localAvatarProvider.notifier).saveLocalAvatar(File(image.path));

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (error) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.getReadableMessage(error))),
        );
      }
    }
  }
}
