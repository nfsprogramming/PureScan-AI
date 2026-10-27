import 'package:flutter/material.dart';
import 'package:mobile/core/utils/error_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/user/data/user_repository.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  final bool isSetupFlow;
  const HealthProfileScreen({super.key, this.isSetupFlow = false});

  @override
  ConsumerState<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _sugarController = TextEditingController();
  final _bpController = TextEditingController();
  
  String? _selectedBloodGroup;

  List<String> _selectedDiets = [];
  List<String> _selectedAllergies = [];

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final List<String> _availableDiets = [
    'Vegan', 'Vegetarian', 'Keto', 'Paleo', 'Low Sugar', 'Halal', 'Kosher'
  ];

  final List<String> _availableAllergies = [
    'Milk', 'Dairy', 'Gluten', 'Wheat', 'Soy', 'Nuts', 'Tree Nuts', 'Peanuts', 'Eggs', 'Seafood', 'Shellfish', 'Fish', 'Sesame'
  ];

  List<String> _selectedHealthGoals = [];
  final List<String> _availableHealthGoals = [
    'Heart Health', 'Low Sugar', 'Weight Loss', 'High Protein', 'Immunity Boost', 'Energy', 'Digestive Health'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _sugarController.dispose();
    _bpController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(userRepositoryProvider).fetchProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _ageController.text = profile['age']?.toString() ?? '';
          _sugarController.text = profile['sugar_level'] ?? '';
          _bpController.text = profile['bp_level'] ?? '';
          
          final bg = profile['blood_group'];
          _selectedBloodGroup = _bloodGroups.contains(bg) ? bg : null;

          _selectedDiets = List<String>.from(profile['diets'] ?? []);
          _selectedAllergies = List<String>.from(profile['allergies'] ?? []);
          _selectedHealthGoals = List<String>.from(profile['health_goals'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorFormatter.getReadableMessage(e)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateHealthProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        bloodGroup: _selectedBloodGroup ?? '',
        sugarLevel: _sugarController.text.trim(),
        bpLevel: _bpController.text.trim(),
        diets: _selectedDiets,
        allergies: _selectedAllergies,
        healthGoals: _selectedHealthGoals,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorFormatter.getReadableMessage(e)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleDiet(String diet) {
    setState(() {
      if (_selectedDiets.contains(diet)) {
        _selectedDiets.remove(diet);
      } else {
        _selectedDiets.add(diet);
      }
    });
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        _selectedAllergies.add(allergy);
      }
    });
  }

  void _toggleHealthGoal(String goal) {
    setState(() {
      if (_selectedHealthGoals.contains(goal)) {
        _selectedHealthGoals.remove(goal);
      } else {
        _selectedHealthGoals.add(goal);
      }
    });
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: GoogleFonts.playfairDisplay(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle, 
            style: TextStyle(
              fontSize: 14, 
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(color: readOnly ? Colors.grey.shade600 : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBloodGroup,
        decoration: InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: Icon(Icons.water_drop_outlined, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedBloodGroup = val;
          });
        },
      ),
    );
  }

  Widget _buildChips(List<String> options, List<String> selectedOptions, Function(String) onToggle) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 12.0,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          selectedColor: Theme.of(context).colorScheme.secondary,
          checkmarkColor: Theme.of(context).colorScheme.onSurface,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile Setup', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: widget.isSetupFlow ? const SizedBox() : null, // hide back button
        actions: [
          if (widget.isSetupFlow)
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Setup Later', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Personal Information ---
                    _buildSectionTitle('Personal Info', 'We need this to personalize your experience.'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      readOnly: true, // Email is managed by Supabase Auth
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 8),

                    // --- Health Vitals ---
                    _buildSectionTitle('Health Vitals', 'Helps us tailor your nutritional insights.'),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final age = int.tryParse(val);
                                if (age == null || age < 1 || age > 120) return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildDropdown(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _sugarController,
                            label: 'Sugar (mg/dL)',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _bpController,
                            label: 'BP (mmHg)',
                            icon: Icons.favorite_border,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // --- Dietary Preferences ---
                    _buildSectionTitle('Dietary Preferences', 'Select diets to get warned about non-compliant ingredients.'),
                    _buildChips(_availableDiets, _selectedDiets, _toggleDiet),
                    
                    const SizedBox(height: 16),

                    // --- Allergies ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildSectionTitle('Allergies', 'Select allergies to receive high-risk health alerts.')),
                        Padding(
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: IconButton(
                            icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary, size: 36),
                            onPressed: () {
                              context.push('/add_allergy').then((_) => _loadProfile());
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildChips(_availableAllergies, _selectedAllergies, _toggleAllergy),
                    
                    const SizedBox(height: 16),

                    // --- Health Goals ---
                    _buildSectionTitle('Health Goals', 'Select your wellness targets.'),
                    _buildChips(_availableHealthGoals, _selectedHealthGoals, _toggleHealthGoal),
                    
                    const SizedBox(height: 120), // Padding for bottom bar
                  ],
                ),
              ),
            ),
      // --- Save Button Floating Bar ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _isLoading ? null : Container(
        margin: const EdgeInsets.all(24),
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
              : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ),
      ),
    );
  }
}
