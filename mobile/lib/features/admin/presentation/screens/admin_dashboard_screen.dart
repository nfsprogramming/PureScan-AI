// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final String? initialRequestId;
  const AdminDashboardScreen({super.key, this.initialRequestId});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<dynamic> _submissions = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  bool _isAccessRestricted = false;
  bool _isAuthenticationRequired = false;
  bool _hasPartialError = false;
  
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  void _checkAuthAndLoad() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _loadData();
    } else {
      // Wait for auth initialization
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.session != null) {
          _authSubscription?.cancel();
          _loadData();
        }
      });
      // Fallback timeout in case auth is already initialized but truly signed out
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isLoading && Supabase.instance.client.auth.currentSession == null) {
          setState(() {
            _isLoading = false;
            _isAuthenticationRequired = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isAccessRestricted = false;
      _isAuthenticationRequired = false;
      _hasPartialError = false;
    });

    final repo = ref.read(adminRepositoryProvider);
    
    final results = await Future.wait([
      repo.fetchStats(),
      repo.fetchSubmissions(),
    ]);

    if (!mounted) return;

    final statsRes = results[0] as AdminResult<Map<String, dynamic>>;
    final subsRes = results[1] as AdminResult<List<dynamic>>;

    // Handle Authentication Required
    if (statsRes is AdminAuthenticationRequired || subsRes is AdminAuthenticationRequired) {
      setState(() {
        _isLoading = false;
        _isAuthenticationRequired = true;
      });
      return;
    }

    // Handle Unauthorized
    if (statsRes is AdminUnauthorized || subsRes is AdminUnauthorized) {
      setState(() {
        _isLoading = false;
        _isAccessRestricted = true;
      });
      return;
    }

    // Handle complete failure
    if (statsRes is! AdminSuccess && subsRes is! AdminSuccess) {
      String errorMessage = 'Unable to load admin data. Please try again.';
      
      if (statsRes is AdminNetworkError || subsRes is AdminNetworkError) {
        errorMessage = 'Unable to connect. Please check your internet connection and try again.';
      } else if (statsRes is AdminDatabaseError || subsRes is AdminDatabaseError) {
        errorMessage = 'A database error occurred. Please try again later.';
      }

      setState(() {
        _isLoading = false;
        _error = errorMessage;
      });
      return;
    }

    // Handle partial success
    setState(() {
      _stats = statsRes is AdminSuccess ? (statsRes as AdminSuccess<Map<String, dynamic>>).data : null;
      _submissions = subsRes is AdminSuccess ? (subsRes as AdminSuccess<List<dynamic>>).data : [];
      _hasPartialError = statsRes is! AdminSuccess || subsRes is! AdminSuccess;
      _isLoading = false;
    });

    if (widget.initialRequestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final target = _submissions.firstWhere(
            (s) => s['id'] == widget.initialRequestId,
            orElse: () => null,
          );
          if (target != null) {
            _showApproveDialog(target);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request already processed or not found.')),
            );
          }
        } catch (e) {
          // ignore
        }
      });
    }
  }

  void _showApproveDialog(dynamic submission) {
    final TextEditingController nameController = TextEditingController(text: submission['product_name']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Barcode: ${submission['barcode']}'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Final Product Name', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(adminRepositoryProvider);
                final success = await repo.approveSubmission(submission['id'], nameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved!')));
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to approve.')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Approve'),
            ),
          ],
        );
      }
    );
  }

  void _reject(String id) async {
    final repo = ref.read(adminRepositoryProvider);
    final success = await repo.rejectSubmission(id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected.')));
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reject.')));
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessRestricted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have permission to access the Admin Dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Go Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Authentication Required',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to access the Admin Dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticationRequired
              ? _buildAuthenticationRequired()
              : _isAccessRestricted
                  ? _buildAccessRestricted()
                  : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_hasPartialError)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Some data couldn't be loaded.",
                                        style: TextStyle(color: Colors.orange.shade900),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadData,
                                      child: const Text('Retry'),
                                    )
                                  ],
                                ),
                              ),
                            
                            // Stats Grid
                            if (_stats != null) ...[
                              Text(
                                'Overview',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.5,
                                children: [
                                  _buildStatCard('Total Products', '${_stats!['total_products']}', Icons.inventory_2, Colors.blue),
                                  _buildStatCard('Total Scans', '${_stats!['total_scans']}', Icons.qr_code_scanner, Colors.purple),
                                  _buildStatCard('Pending', '${_stats!['pending_submissions']}', Icons.pending_actions, Colors.orange),
                                  _buildStatCard('Approved', '${_stats!['approved_products']}', Icons.check_circle, Colors.green),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                            
                            // Pending Submissions List
                            Text(
                              'Pending Submissions',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_submissions.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending products',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _submissions.length,
                                itemBuilder: (context, index) {
                                  final sub = _submissions[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Text(sub['product_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Barcode: ${sub['barcode']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () => _reject(sub['id']),
                                            tooltip: 'Reject',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            onPressed: () => _showApproveDialog(sub),
                                            tooltip: 'Approve',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
