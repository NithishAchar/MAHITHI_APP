import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';

class FacultyRegistrationPage extends ConsumerStatefulWidget {
  const FacultyRegistrationPage({super.key});

  @override
  ConsumerState<FacultyRegistrationPage> createState() =>
      _FacultyRegistrationPageState();
}

class _FacultyRegistrationPageState
    extends ConsumerState<FacultyRegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyIdController = TextEditingController();

  String? _selectedDepartment;
  String? _profileImagePath;
  bool _isLoading = false;
  bool _showPassword = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Department options
  final List<String> _departmentOptions = [
    'Principal',
    'Vice Principal',
    'Department of Commerce',
    'Department of Computer Science',
    'Department of Business Administration',
    'Department of Language',
  ];

  // Department code mapping
  final Map<String, String> _departmentCodes = {
    'Principal': 'PRI',
    'Vice Principal': 'VPR',
    'Department of Commerce': 'BCM',
    'Department of Computer Science': 'BCA',
    'Department of Business Administration': 'BBA',
    'Department of Language': 'LAN',
  };

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Setup animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _playEntranceAnimations();

    // Set listener to auto-generate faculty ID when department changes
    _facultyIdController.text = 'BBHC';
  }

  void _playEntranceAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _facultyIdController.dispose();
    super.dispose();
  }

  void _updateFacultyIdPrefix() {
    if (_selectedDepartment != null) {
      final deptCode = _departmentCodes[_selectedDepartment!] ?? '';

      // Update faculty ID keeping any existing numeric part
      String currentId = _facultyIdController.text;
      String numericPart = '';

      // Extract existing numeric part if any
      RegExp numRegex = RegExp(r'\d{0,3}$');
      var matches = numRegex.allMatches(currentId);
      if (matches.isNotEmpty) {
        numericPart = matches.first.group(0) ?? '';
      }

      // Set new ID with department code and existing numeric part
      _facultyIdController.text = 'BBHC$deptCode$numericPart';
    }
  }

  Future<void> _registerFaculty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);

      // Register faculty using Firebase Auth and Firestore
      await firebaseService.registerFaculty(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        facultyId: _facultyIdController.text,
        department: _selectedDepartment!,
      );

      // If there's a profile image, upload it
      if (_profileImagePath != null) {
        try {
          await firebaseService.uploadProfileImage(File(_profileImagePath!));
        } catch (imageError) {
          // Just log the error but don't fail registration
          print('Error uploading profile image: $imageError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty registered successfully'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );

        // Navigate back or to login
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EC),
      appBar: AppBar(
        title: const Text(
          'Faculty Registration',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B4513),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildProfileIcon(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildRegistrationForm(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF8B4513),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _profileImagePath != null
                  ? Image.file(
                      File(_profileImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF8B4513),
                        );
                      },
                    )
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF8B4513),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    'Faculty Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Faculty Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter faculty name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDepartmentDropdown(),
                const SizedBox(height: 16),
                _buildFacultyIdField(),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildRegisterButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B4513),
                ),
                keyboardType: keyboardType,
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Icon(Icons.business_outlined,
                size: 20, color: Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: InputBorder.none,
                  isDense: true,
                ),
                items: _departmentOptions
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    // Update faculty ID
                    _updateFacultyIdPrefix();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select department';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyIdField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined,
                size: 20, color: Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _facultyIdController,
                decoration: const InputDecoration(
                  labelText: 'Faculty ID',
                  border: InputBorder.none,
                  isDense: true,
                  helperText: 'Format: BBHC[Dept]###',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B4513),
                ),
                onChanged: (value) {
                  // Always ensure the ID starts with BBHC
                  if (!value.startsWith('BBHC')) {
                    _facultyIdController.text =
                        'BBHC' + value.replaceAll('BBHC', '');
                    _facultyIdController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _facultyIdController.text.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter faculty ID';
                  }

                  // Validate faculty ID format: BBHC[Dept]###
                  // Dept can be BCA, BBA, BCM, LAN, PRI, VPR
                  RegExp regex = RegExp(
                    r'^BBHC(BCA|BBA|BCM|LAN|PRI|VPR)[0-9]{3}$',
                  );

                  if (!regex.hasMatch(value)) {
                    return 'Invalid format. Use BBHC[Dept]###';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 20, color: Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF8B4513),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B4513),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registerFaculty,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: const Text(
          'Register Faculty',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
