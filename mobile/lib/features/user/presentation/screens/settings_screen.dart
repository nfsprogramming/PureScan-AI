import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/user/presentation/providers/settings_provider.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final isAdmin = [
      'mohammed.nifras.000555@gmail.com',
      'developer@purescanai.com',
      'admin@purescanai.com',
      'nfs.photographer@gmail.com',
      'developer@email.com',
      'admin@yourdomain.com',
      'developer@yourdomain.com'
    ].contains(currentUserEmail);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'PREFERENCES',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildSettingsGroup(context, [
              _buildSettingsItem(
                context,
                icon: Icons.tune,
                title: 'Clinical Thresholds',
                subtitle: '${settings.clinicalThreshold} sensitivity',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Sensitivity',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'How strict should AI health warnings be for matched ingredients?',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 16),
                            Consumer(
                              builder: (context, ref, child) {
                                final currentThreshold = ref.watch(settingsProvider).clinicalThreshold;
                                return Column(
                                  children: ['High', 'Medium', 'Low'].map((level) {
                                    return RadioListTile<String>(
                                      title: Text(level, style: TextStyle(fontWeight: FontWeight.w500)),
                                      value: level,
                                      // ignore: deprecated_member_use
                                      groupValue: currentThreshold,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      // ignore: deprecated_member_use
                                      onChanged: (val) {
                                        ref.read(settingsProvider.notifier).updateClinicalThreshold(val!);
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.notifications_none,
                title: 'Notification Settings',
                subtitle: 'Manage alerts and daily digests',
                isLast: true,
                onTap: () {
                  context.push('/settings/notifications');
                },
              ),
            ]),
            
            const SizedBox(height: 32),
            

            
            // Admin
            if (isAdmin) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildSettingsGroup(context, [
                _buildSettingsItem(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage and approve new products',
                  isLast: true,
                  onTap: () {
                    context.push('/admin');
                  },
                ),
              ]),
              
              const SizedBox(height: 32),
            ],
            
            // Legal
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'LEGAL',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildSettingsGroup(context, [
              _buildSettingsItem(
                context,
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your health data',
                trailingIcon: Icons.chevron_right,
                onTap: () {
                  context.push('/privacy_policy');
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Rules for using PureScan AI',
                trailingIcon: Icons.chevron_right,
                isLast: true,
                onTap: () {
                  context.push('/terms_of_service');
                },
              ),
            ]),
            
            const SizedBox(height: 48),
            
            // Log Out Button
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFBA1A1A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    IconData trailingIcon = Icons.chevron_right,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF414844).withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(trailingIcon, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 24),
          ],
        ),
      ),
    );
  }
}
