import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _showPassword = false;
  String? _userType;
  String? _profileImageUrl;
  String? _profileImagePath; // Local file path for preview before upload
  String? _loginTime;

  // Separate animation controllers for different animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with different durations
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

    // Setup animations with curves
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

    // Start initial animations
    _playEntranceAnimations();

    // Load user data
    _loadUserData();
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
    _regNumberController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get Firebase service instance
      final firebaseService = ref.read(firebaseServiceProvider);
      
      // Get user data from Firestore
      final userData = await firebaseService.getUserData();
      
      setState(() {
        _userType = userData['type'];
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _departmentController.text = userData['department'] ?? '';
        _profileImageUrl = userData['profileImageUrl'];
        
        // Set ID fields based on user type
        if (_userType == 'faculty') {
          _facultyIdController.text = userData['facultyId'] ?? '';
        } else {
          _regNumberController.text = userData['regNumber'] ?? '';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
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

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      
      // Create map of updated data
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'department': _departmentController.text,
      };
      
      // Update Firestore document
      await firebaseService.updateUserProfile(userData);

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      
      if (mounted) {
        // Reset and play animations after save
        _slideController.reset();
        _fadeController.reset();
        _scaleController.reset();
        _playEntranceAnimations();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFaculty = _userType == 'faculty';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EC), // Light beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF8B4513),
            ),
            onPressed: () {
              if (_isEditing) {
                _saveUserData();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
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
                          _buildPersonalInfo(isFaculty),
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
      onTap: _isEditing ? _pickImage : null,
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
                : _profileImageUrl != null
                  ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF8B4513),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF8B4513),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
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
          if (_isEditing)
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

  Widget _buildPersonalInfo(bool isFaculty) {
    final departmentOptions = [
      'Principal',
      'Vice Principal',
      'Department of Commerce',
      'Department of Computer Application',
      'Department of Business',
      'Department of Language Administration',
    ];
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
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isFaculty) ...[
                  _buildInfoField(
                    label: 'Faculty Name',
                    value: _nameController.text,
                    icon: Icons.person_outline,
                    isEditable: _isEditing,
                    onChanged: (value) => _nameController.text = value,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Faculty ID',
                    value: _facultyIdController.text,
                    icon: Icons.badge_outlined,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
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
                          const Icon(Icons.business_outlined, size: 20, color: Color(0xFF8B4513)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isEditing
                                ? DropdownButtonFormField<String>(
                                    value: departmentOptions.contains(_departmentController.text)
                                        ? _departmentController.text
                                        : null,
                                    items: departmentOptions
                                        .map((dept) => DropdownMenuItem(
                                              value: dept,
                                              child: Text(dept),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _departmentController.text = value;
                                        });
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Department',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  )
                                : Text(
                                    _departmentController.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF8B4513),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Gmail',
                    value: _emailController.text,
                    icon: Icons.email_outlined,
                    isEditable: _isEditing,
                    onChanged: (value) => _emailController.text = value,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Password',
                    value: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isEditable: false,
                    onChanged: null,
                    suffix: TextButton(
                      onPressed: () {
                        _showPasswordResetDialog();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Color(0xFF8B4513)),
                      ),
                    ),
                  ),
                ] else ...[
                  _buildInfoField(
                    label: 'Registration Number',
                    value: _regNumberController.text,
                    icon: Icons.badge_outlined,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Email',
                    value: _emailController.text,
                    icon: Icons.email_outlined,
                    isEditable: _isEditing,
                    onChanged: (value) => _emailController.text = value,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Password',
                    value: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isEditable: false,
                    onChanged: null,
                    suffix: TextButton(
                      onPressed: () {
                        _showPasswordResetDialog();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Color(0xFF8B4513)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'We will send a password reset link to your email address. Would you like to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final firebaseService = ref.read(firebaseServiceProvider);
                await firebaseService.sendPasswordResetEmail(_emailController.text);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent'),
                      backgroundColor: Color(0xFF8B4513),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending reset email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    bool isReadOnly = false,
    bool isEditable = false,
    bool isPassword = false,
    Function(String)? onChanged,
    Widget? suffix,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF8B4513)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextFormField(
              initialValue: value,
              enabled: isEditable && !isReadOnly,
              obscureText: isPassword && !_showPassword,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                suffixIcon: suffix ?? (isPassword
                    ? IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF8B4513),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      )
                    : null),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
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
        
        // Upload the new image to Firebase Storage
        final firebaseService = ref.read(firebaseServiceProvider);
        final downloadUrl = await firebaseService.uploadProfileImage(File(image.path));
        
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Color(0xFF8B4513),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
