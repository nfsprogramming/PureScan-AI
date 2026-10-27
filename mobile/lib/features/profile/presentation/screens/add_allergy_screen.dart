// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/error_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../user/data/user_repository.dart';

class AddAllergyScreen extends ConsumerStatefulWidget {
  const AddAllergyScreen({super.key});

  @override
  ConsumerState<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends ConsumerState<AddAllergyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _otherAllergyController = TextEditingController();
  
  final List<String> _selectedAllergies = [];
  bool _isSaving = false;

  final List<String> _commonAllergies = [
    'Milk', 'Dairy', 'Gluten', 'Wheat', 'Soy', 'Nuts', 'Tree Nuts', 'Peanuts', 'Eggs', 'Seafood', 'Shellfish', 'Fish', 'Sesame'
  ];

  void _toggleAllergy(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        _selectedAllergies.add(allergy);
      }
    });
  }

  Future<void> _saveAllergies() async {
    if (_selectedAllergies.isEmpty && _otherAllergyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an allergy.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final repo = ref.read(userRepositoryProvider);
      final profile = await repo.fetchProfile();
      
      List<String> currentDiets = [];
      List<String> currentAllergies = [];
      List<String> currentHealthGoals = [];
      
      if (profile != null) {
        currentDiets = List<String>.from(profile['diets'] ?? []);
        currentAllergies = List<String>.from(profile['allergies'] ?? []);
        currentHealthGoals = List<String>.from(profile['health_goals'] ?? []);
      }

      for (final a in _selectedAllergies) {
        if (!currentAllergies.contains(a)) {
          currentAllergies.add(a);
        }
      }

      final other = _otherAllergyController.text.trim();
      if (other.isNotEmpty && !currentAllergies.contains(other)) {
        currentAllergies.add(other);
      }

      await repo.updateHealthProfile(
        fullName: profile?['full_name'] ?? '',
        phoneNumber: profile?['phone_number'] ?? '',
        age: profile?['age'] ?? 0,
        bloodGroup: profile?['blood_group'] ?? '',
        sugarLevel: profile?['sugar_level'] ?? '',
        bpLevel: profile?['bp_level'] ?? '',
        diets: currentDiets,
        allergies: currentAllergies,
        healthGoals: currentHealthGoals,
      );

      if (mounted) {
        final String addedName = other.isNotEmpty ? other : _selectedAllergies.first;
        // Push the success splash
        context.pushReplacement('/allergy_success', extra: addedName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorFormatter.getReadableMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Allergy',
          style: GoogleFonts.playfairDisplay(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for an allergen...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Common Allergies Header
                Text(
                  'Common Allergies',
                  style: GoogleFonts.playfairDisplay(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Bento Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _commonAllergies.length,
                  itemBuilder: (context, index) {
                    final allergy = _commonAllergies[index];
                    final isSelected = _selectedAllergies.contains(allergy);
                    
                    return GestureDetector(
                      onTap: () => _toggleAllergy(allergy),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                                ),
                              ),
                              child: isSelected 
                                ? Icon(Icons.check, size: 14, color: Theme.of(context).colorScheme.surface)
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                allergy,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Other Allergy Input
                Text(
                  'Other Allergy (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otherAllergyController,
                    decoration: InputDecoration(
                      hintText: 'Specify other allergy',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                
                // Bottom spacing for fixed button
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Fixed Bottom Action Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 24, bottom: 24, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  shadowColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onPressed: _isSaving ? null : _saveAllergies,
                child: _isSaving
                    ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
                    : const Text('Add to Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
