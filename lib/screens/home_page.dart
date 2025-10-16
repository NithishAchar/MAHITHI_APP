import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job/screens/course_content_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _jobSectionIndex = 0;
  late AnimationController _animationController;
  final List<Map<String, dynamic>> jobApplications = [];
  final List<Map<String, dynamic>> placedStudents = [];
  final List<Map<String, dynamic>> posts = [];
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadJobApplications();
    _loadPlacedStudents();
    _loadPosts();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Add listener for real-time updates
    SharedPreferences.getInstance().then((prefs) {
      prefs.reload(); // Ensure we have latest data
      _loadPosts(); // Initial load
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final Map<String, dynamic> userMap = json.decode(userData);
      setState(() {
        _userType = userMap['type'];
      });
    }
  }

  bool get _isFaculty => _userType == 'faculty';
  bool get _isStudent => _userType == 'student';
  bool get _isPublic => _userType == 'public';

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0 || _isPublic
              ? 'MAHITHI'
              : _selectedIndex == 1
                  ? 'Job Updates'
                  : _selectedIndex == 2
                      ? 'Create Post'
                      : _selectedIndex == 3
                          ? 'Learn'
                          : 'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          if (_selectedIndex == 0 && !_isPublic)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            )
          else if (_selectedIndex == 1 && !_isPublic)
            IconButton(
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.work_outline),
              ),
              onPressed: () {},
            ),
        ],
      ),
      body: _isPublic
          ? Column(
              children: [
                Expanded(
                  child: posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.post_add_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPosts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: posts.length,
                            itemBuilder: (context, index) =>
                                PostCard(post: posts[index]),
                          ),
                        ),
                ),
              ],
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                // Home Feed
                Column(
                  children: [
                    Expanded(
                      child: posts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.post_add_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_isFaculty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first post!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPosts,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: posts.length,
                                itemBuilder: (context, index) =>
                                    PostCard(post: posts[index]),
                              ),
                            ),
                    ),
                  ],
                ),
                // Jobs Updates
                if (!_isPublic) _buildJobsSection(),
                // Create Post
                if (!_isPublic) const CreatePostScreen(),
                // Learn Page
                if (!_isPublic) _buildLearnSection(),
                // Profile Page
                if (!_isPublic) _buildProfileSection(),
              ],
            ),
      bottomNavigationBar: _isPublic
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: bottomPadding + 10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.home_rounded,
                        Icons.home_outlined,
                        'Home',
                      ),
                      _buildNavItem(
                        1,
                        Icons.work_rounded,
                        Icons.work_outline_rounded,
                        'Jobs',
                      ),
                      _buildAddButton(),
                      _buildNavItem(
                        3,
                        Icons.book,
                        Icons.book_outlined,
                        'Learn',
                      ),
                      _buildProfileItem(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }

  Widget _buildProfileItem() {
    final isSelected = _selectedIndex == 4;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ProfilePage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.scaled,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Profile',
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseContentPage(
                  courseTitle: title,
                  courseColor: color,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlacedStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final students = prefs.getStringList('placedStudents') ?? [];
    setState(() {
      placedStudents.clear();
      for (var student in students) {
        final Map<String, dynamic> studentMap = json.decode(student);
        placedStudents.add(studentMap);
      }
      // Sort students by batch year in descending order (newest first)
      placedStudents.sort(
        (a, b) => int.parse(b['batch']).compareTo(int.parse(a['batch'])),
      );
    });
  }

  Future<void> _savePlacedStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final students =
        placedStudents.map((student) => json.encode(student)).toList();
    await prefs.setStringList('placedStudents', students);
  }

  void _addPlacedStudent() async {
    if (!_isFaculty) return;

    final nameController = TextEditingController();
    final companyController = TextEditingController();
    final packageController = TextEditingController();
    final batchController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Placed Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: packageController,
                decoration: const InputDecoration(
                  labelText: 'Package (LPA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null && context.mounted) {
                          imagePath = image.path;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image captured')),
                          );
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null && context.mounted) {
                          imagePath = image.path;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image selected')),
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                ],
              ),
              if (imagePath != null) ...[
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(imagePath!), fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  companyController.text.isNotEmpty &&
                  packageController.text.isNotEmpty &&
                  batchController.text.isNotEmpty &&
                  imagePath != null) {
                final student = {
                  'name': nameController.text,
                  'company': companyController.text,
                  'package': packageController.text,
                  'batch': batchController.text,
                  'imagePath': imagePath,
                  'date': DateTime.now().toString(),
                };

                final prefs = await SharedPreferences.getInstance();
                final students = prefs.getStringList('placedStudents') ?? [];
                students.add(json.encode(student));
                await prefs.setStringList('placedStudents', students);

                setState(() {
                  placedStudents.add(student);
                  placedStudents.sort(
                    (a, b) => int.parse(
                      b['batch'],
                    ).compareTo(int.parse(a['batch'])),
                  );
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student added successfully'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill all fields and select an image',
                    ),
                  ),
                );
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadJobApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final jobs = prefs.getStringList('jobApplications') ?? [];
    setState(() {
      jobApplications.clear();
      for (var job in jobs) {
        final Map<String, dynamic> jobMap = json.decode(job);
        // Remove jobs older than 30 days
        final jobDate = DateTime.parse(jobMap['date']);
        if (DateTime.now().difference(jobDate).inDays <= 30) {
          jobApplications.add(jobMap);
        }
      }
      // Sort jobs by date in descending order (newest first)
      jobApplications.sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );
    });
  }

  Future<void> _saveJobApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final jobs = jobApplications.map((job) => json.encode(job)).toList();
    await prefs.setStringList('jobApplications', jobs);
  }

  void _addNewJobApplication(BuildContext context) {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final locationController = TextEditingController();
    final packageController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: packageController,
              decoration: const InputDecoration(
                labelText: 'Package (LPA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Job URL',
                hintText: 'Enter job application link',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Insert new job at the beginning of the list
                jobApplications.insert(0, {
                  'title': titleController.text,
                  'company': companyController.text,
                  'location': locationController.text,
                  'package': packageController.text,
                  'url': urlController.text,
                  'date': DateTime.now().toIso8601String(),
                });
              });
              _saveJobApplications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPosts = prefs.getStringList('posts') ?? [];
    if (mounted) {
      setState(() {
        posts.clear();
        for (var post in savedPosts) {
          posts.add(json.decode(post));
        }
        // Sort posts by date (newest first)
        posts.sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final Map<String, dynamic> userMap = json.decode(userData);
      if (userMap['profileImage'] != null) {
        // Delete the image file
        final file = File(userMap['profileImage']);
        if (await file.exists()) {
          await file.delete();
        }
        // Update user data without the image
        userMap.remove('profileImage');
        await prefs.setString('userData', json.encode(userMap));
        setState(() {});
      }
    }
  }

  Widget _buildProfileSection() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _selectedIndex = 0);
            },
          ),
          title: const Text(
            '@Naisyaatat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.brown,
            ),
          ),
          actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onLongPress: _isFaculty ? _deleteProfileImage : null,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat('Posts', '245'),
                          _buildProfileStat('Followers', '12.3K'),
                          _buildProfileStat('Following', '435'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alana Maesya',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Digital Creator',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Creating digital content and sharing my journey 🚀\nLet\'s connect! 💫',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Share Profile',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on)),
                        Tab(icon: Icon(Icons.bookmark_border)),
                      ],
                      labelColor: Colors.brown,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.brown,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          GridView.builder(
                            padding: const EdgeInsets.all(1),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                            itemCount: 0,
                            itemBuilder: (context, index) => Container(),
                          ),
                          GridView.builder(
                            padding: const EdgeInsets.all(1),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                            itemCount: 0,
                            itemBuilder: (context, index) => Container(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobsSection() {
    return Column(
      children: [
        // Section Headers
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _jobSectionIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _jobSectionIndex = 0),
                    child: Text(
                      'Job Applications',
                      style: TextStyle(
                        color: _jobSectionIndex == 0
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _jobSectionIndex == 1
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _jobSectionIndex = 1),
                    child: Text(
                      'Placed Students',
                      style: TextStyle(
                        color: _jobSectionIndex == 1
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section Content
        Expanded(
          child: IndexedStack(
            index: _jobSectionIndex,
            children: [
              // Job Applications List
              Scaffold(
                body: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobApplications.length,
                  itemBuilder: (context, index) {
                    final job = jobApplications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors
                                  .primaries[index % Colors.primaries.length]
                                  .withAlpha(51),
                              child: Icon(
                                Icons.business_center,
                                color: Colors
                                    .primaries[index % Colors.primaries.length],
                              ),
                            ),
                            title: Text(job['title']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Company: ${job['company']}'),
                                Text('Location: ${job['location']}'),
                                Text('Package: ${job['package']} LPA'),
                                if (job['url']?.isNotEmpty ?? false)
                                  InkWell(
                                    onTap: () async {
                                      final url = Uri.parse(job['url']);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'URL: ${job['url']}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Text('2h ago'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                floatingActionButton: _isFaculty
                    ? FloatingActionButton(
                        onPressed: () => _addNewJobApplication(context),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.add),
                      )
                    : null,
              ),

              // Placed Students List
              Scaffold(
                body: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: placedStudents.length,
                  itemBuilder: (context, index) {
                    final student = placedStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: student['imagePath'] != null
                              ? FileImage(File(student['imagePath']))
                              : null,
                          child: student['imagePath'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(student['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Company: ${student['company']}'),
                            Text('Package: ${student['package']} LPA'),
                            Text('Batch: ${student['batch']}'),
                          ],
                        ),
                        trailing: _isFaculty
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final students =
                                      prefs.getStringList('placedStudents') ??
                                          [];
                                  students.removeAt(index);
                                  await prefs.setStringList(
                                    'placedStudents',
                                    students,
                                  );
                                  setState(() {
                                    placedStudents.removeAt(index);
                                  });
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
                floatingActionButton: _isFaculty
                    ? FloatingActionButton(
                        onPressed: _addPlacedStudent,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.add),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearnSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Course',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildCourseCard(
            'BCA',
            'Bachelor of Computer Applications',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildCourseCard('B.COM', 'Bachelor of Commerce', Colors.green),
          const SizedBox(height: 16),
          _buildCourseCard(
            'BBA',
            'Bachelor of Business Administration',
            Colors.orange,
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDeleting = false;
  final bool _isExpanded = false;
  bool _isLiked = false;
  bool _isSharing = false;
  int _likeCount = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final _commentController = TextEditingController();
  bool _isPostingComment = false;
  String? _userType;
  bool _showCommentInput = false;
  bool _showComments = false;
  final ScrollController _scrollController = ScrollController();
  static const int _visibleCommentsCount = 4;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _likeCount = widget.post['likes'] ?? 0;
    _initializeVideoController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videoController?.dispose();
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final Map<String, dynamic> userMap = json.decode(userData);
      setState(() {
        _userType = userMap['type'];
      });
    }
  }

  bool get _isFaculty => _userType == 'faculty';

  Future<void> _initializeVideoController() async {
    if (widget.post['mediaType'] == 'video' &&
        widget.post['mediaPath'] != null) {
      try {
        // Skip video initialization on web platform
        if (kIsWeb) {
          setState(() => _isVideoInitialized = false);
          return;
        }

        _videoController = VideoPlayerController.file(
          File(widget.post['mediaPath']!),
        );
        await _videoController!.initialize();
        setState(() => _isVideoInitialized = true);
      } catch (e) {
        print('Error initializing video: $e');
        setState(() => _isVideoInitialized = false);
      }
    }
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post['mediaPath'] != widget.post['mediaPath']) {
      _initializeVideoController();
    }
  }

  Future<void> _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    return Future.value();
  }

  Future<void> _sharePost() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      String? mediaPath = widget.post['mediaPath'];
      String content = '';

      if (widget.post['title']?.isNotEmpty == true) {
        content += widget.post['title']!;
      }
      if (widget.post['content']?.isNotEmpty == true) {
        if (content.isNotEmpty) content += '\n\n';
        content += widget.post['content']!;
      }

      if (mediaPath != null && await File(mediaPath).exists()) {
        final file = XFile(mediaPath);
        await Share.shareXFiles(
          [file],
          text: content.isNotEmpty ? content : null,
        );
      } else {
        await Share.share(
          content,
          subject: widget.post['title'] ?? 'Check out this post!',
        );
      }
    } catch (e) {
      print('Share error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _deletePost() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final posts = prefs.getStringList('posts') ?? [];

      final updatedPosts = posts.where((postStr) {
        final post = json.decode(postStr);
        return post['date'] != widget.post['date'];
      }).toList();

      await prefs.setStringList('posts', updatedPosts);

      if (mounted) {
        // Update the parent's state without any navigation
        final homeState = context.findAncestorStateOfType<_HomePageState>();
        if (homeState != null && homeState.mounted) {
          homeState.setState(() {
            homeState.posts
                .removeWhere((post) => post['date'] == widget.post['date']);
          });
        }

        // Show a snackbar with undo option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(8),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                if (mounted) {
                  setState(() => _isDeleting = false);
                  await _animationController.reverse();

                  // Restore the post without navigation
                  final homeState =
                      context.findAncestorStateOfType<_HomePageState>();
                  if (homeState != null && homeState.mounted) {
                    homeState.setState(() {
                      homeState.posts.add(widget.post);
                      homeState.posts.sort((a, b) => DateTime.parse(b['date'])
                          .compareTo(DateTime.parse(a['date'])));
                    });
                    await prefs.setStringList('posts',
                        homeState.posts.map((p) => json.encode(p)).toList());
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Delete error: $e');
      if (mounted) {
        setState(() => _isDeleting = false);
        await _animationController.reverse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete post'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  void _showOptionsMenu() {
    if (!_isFaculty) return;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade700),
              ),
              title: const Text(
                'Delete Post',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text(
                'This action cannot be undone',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                // Just delete without navigation
                _deletePost();
                // Dismiss the bottom sheet
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);

    try {
      final comment = {
        'author': 'User',
        'text': text,
        'date': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final posts = prefs.getStringList('posts') ?? [];

      bool updated = false;
      final updatedPosts = posts.map((postStr) {
        final post = json.decode(postStr);
        if (post['date'] == widget.post['date']) {
          post['comments'] ??= [];
          post['comments'].add(comment);
          updated = true;
        }
        return json.encode(post);
      }).toList();

      if (updated) {
        await prefs.setStringList('posts', updatedPosts);
        setState(() {
          widget.post['comments'] ??= [];
          widget.post['comments'].add(comment);
          _commentController.clear();
          // Close comment input and section after posting
          _showCommentInput = false;
          _showComments = false;
        });
      }
    } catch (e) {
      print('Comment error: $e');
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  Widget _buildCommentInput() {
    if (!_showCommentInput) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 14, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  if (_isPostingComment)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: 14,
                      ),
                      onPressed: _postComment,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    if (!_showComments || widget.post['comments'] == null) {
      return const SizedBox();
    }

    final comments = List.from(widget.post['comments']);
    comments.sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    if (comments.isEmpty) return const SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: min(comments.length * 65.0,
                3 * 65.0), // Optimize height based on comment count
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: comments.length,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentItem(comment, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              comment['author'][0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        comment['author'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(DateTime.parse(comment['date'])),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    comment['text'],
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = widget.post['mediaPath'] != null;
    final date = DateTime.parse(widget.post['date']);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post['author'] ?? 'Faculty Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        Text(
                          'Faculty',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isFaculty)
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: _showOptionsMenu,
                    ),
                ],
              ),
            ),

            // Media Section
            if (hasMedia)
              Stack(
                children: [
                  Hero(
                    tag: 'post_media_${widget.post['date']}',
                    child: Container(
                      width: screenWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: AspectRatio(
                            aspectRatio:
                                16 / 9, // Standard aspect ratio for preview
                            child: widget.post['mediaType'] == 'video'
                                ? _buildVideoPlayer()
                                : _buildImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Expand button
                  if (widget.post['mediaType'] != 'video')
                    Positioned(
                      bottom: 8,
                      right: 24,
                      child: GestureDetector(
                        onTap: _showFullScreenImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Expand',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // Content Section
            if (widget.post['title']?.isNotEmpty == true ||
                widget.post['content']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.post['title']?.isNotEmpty == true) ...[
                      Text(
                        widget.post['title'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.post['content']?.isNotEmpty == true)
                      Text(
                        widget.post['content'] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                  ],
                ),
              ),

            // Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey,
                    count: _likeCount,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    color: (_showComments || _showCommentInput)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    count: widget.post['comments']?.length ?? 0,
                    onTap: () => setState(() {
                      _showComments = !_showComments;
                      _showCommentInput = !_showCommentInput;
                    }),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: _isSharing ? Icons.sync : Icons.share_outlined,
                    color: Colors.grey,
                    onTap: _sharePost,
                  ),
                ],
              ),
            ),

            // Comments Section
            _buildCommentSection(),

            // Comment Input
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      color: Colors.grey[100],
      child: kIsWeb ? _buildWebImage() : _buildNativeImage(),
    );
  }

  Widget _buildWebImage() {
    // For web platform, we need to use base64 data or network images
    // First check if we have media data in base64 format
    if (widget.post['mediaBase64'] != null) {
      try {
        final Uint8List bytes = base64Decode(widget.post['mediaBase64']);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Error loading image from base64: $error");
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 40,
              ),
            );
          },
        );
      } catch (e) {
        print("Error decoding base64 image: $e");
      }
    }

    // Fallback display for web when no valid image data is available
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              "Image not available on web",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeImage() {
    // For mobile/desktop platforms, use Image.file
    try {
      if (widget.post['mediaPath'] == null) {
        // No media path available
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  "Image not available",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      // Check if file exists before loading
      final file = File(widget.post['mediaPath']!);

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image from file: $error");
          // If there's an error loading the file, try using mediaUrl if available
          if (widget.post['mediaUrl'] != null) {
            return Image.network(
              widget.post['mediaUrl'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
              },
            );
          }

          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    } catch (e) {
      print("Error loading file image: $e");

      // Try to use mediaUrl if the file fails
      if (widget.post['mediaUrl'] != null) {
        return Image.network(
          widget.post['mediaUrl'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 40,
              ),
            );
          },
        );
      }

      return Container(
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 40,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (kIsWeb) {
      // Web platform video handling
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                color: Colors.grey,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                "Video preview not available on web",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile/desktop platform video handling
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayer(_videoController!),
        // Video overlay with play button
        AnimatedOpacity(
          opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        // Tap detector for play/pause
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Interactive viewer for zoom and pan
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'post_media_${widget.post['date']}',
                    child: Center(
                      child: kIsWeb
                          ? _buildFullscreenWebImage()
                          : Image.file(
                              File(widget.post['mediaPath']!),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildFullscreenWebImage() {
    if (widget.post['mediaBase64'] != null) {
      try {
        final Uint8List bytes = base64Decode(widget.post['mediaBase64']);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
        );
      } catch (e) {
        print("Error decoding base64 image for fullscreen: $e");
      }
    }

    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              "Image not available on web",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0.0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
            ),
          ),
        );
      },
    );
  }
}

// Create Post Screen
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedMediaPath;
  String? _selectedMediaBase64; // Add this property for web compatibility
  String? _mediaType;
  String? _userType;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final Map<String, dynamic> userMap = json.decode(userData);
      setState(() {
        _userType = userMap['type'];
      });
    }
  }

  bool get _isFaculty => _userType == 'faculty';

  Future<void> _pickMedia() async {
    if (!_isFaculty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only faculty members can create posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Media Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.deepPurple,
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  setState(() {
                    _selectedMediaPath = image.path;
                    _mediaType = 'image';
                  });

                  // Add web support by converting to base64
                  if (kIsWeb) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _selectedMediaBase64 = base64Encode(bytes);
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.deepPurple,
              ),
              title: const Text('Choose Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  setState(() {
                    _selectedMediaPath = image.path;
                    _mediaType = 'image';
                  });

                  // Add web support by converting to base64
                  if (kIsWeb) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _selectedMediaBase64 = base64Encode(bytes);
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Record Video'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final video = await picker.pickVideo(
                  source: ImageSource.camera,
                );
                if (video != null) {
                  setState(() {
                    _selectedMediaPath = video.path;
                    _mediaType = 'video';
                  });

                  // Add web support for video preview (thumbnail) if needed
                  if (kIsWeb) {
                    // For videos, we'd typically need to extract a thumbnail
                    // or use a different approach for web
                    // This is a simplified approach
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.video_library,
                color: Colors.deepPurple,
              ),
              title: const Text('Choose Video'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final video = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null) {
                  setState(() {
                    _selectedMediaPath = video.path;
                    _mediaType = 'video';
                  });

                  // Add web support for video preview (thumbnail) if needed
                  if (kIsWeb) {
                    // For videos, we'd typically need to extract a thumbnail
                    // or use a different approach for web
                    // This is a simplified approach
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishPost() async {
    if (!_isFaculty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only faculty members can create posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.isNotEmpty && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required when adding content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMediaPath == null && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add either media or content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      File? mediaFile;

      // Handle media file for both web and native platforms
      if (_selectedMediaPath != null) {
        if (kIsWeb) {
          // For web platform
          if (_selectedMediaBase64 != null) {
            // Store in SharedPreferences for web
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('lastPostMediaBase64', _selectedMediaBase64!);
            await prefs.setString('lastPostMediaType', _mediaType ?? 'image');

            // Create a virtual file from base64 for web
            final bytes = base64Decode(_selectedMediaBase64!);
            mediaFile = File.fromRawPath(bytes);
          }
        } else {
          // For Android/iOS - create real file from path
          mediaFile = File(_selectedMediaPath!);

          // Verify the file exists on the device
          if (!await mediaFile.exists()) {
            print(
                'Warning: Media file does not exist at path: $_selectedMediaPath');
          }
        }
      }

      // Call the Firebase service to create the post
      await firebaseService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        mediaFile: mediaFile,
        mediaType: _mediaType,
      );

      if (mounted) {
        setState(() {
          _titleController.clear();
          _contentController.clear();
          _selectedMediaPath = null;
          _selectedMediaBase64 = null;
          _mediaType = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Post published successfully! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Publish error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  Future<void> _initializeVideo(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    try {
      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaType == 'video' && _selectedMediaPath != null) {
      _initializeVideo(_selectedMediaPath!);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Create New Post',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                  ),
                  const Spacer(),
                  if (!_isFaculty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Faculty Only',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isFaculty ? _pickMedia : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _selectedMediaPath != null
                        ? Colors.transparent
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFaculty
                          ? Colors.deepPurple.shade300
                          : Colors.grey.shade300,
                      width: _isFaculty ? 2 : 1,
                    ),
                  ),
                  child: _selectedMediaPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_mediaType == 'image')
                                kIsWeb && _selectedMediaBase64 != null
                                    ? Image.memory(
                                        base64Decode(_selectedMediaBase64!),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print(
                                              "Error loading image from base64: $error");
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.file(
                                        File(_selectedMediaPath!),
                                        fit: BoxFit.cover,
                                      )
                              else if (_mediaType == 'video' &&
                                  _videoController != null)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    IconButton(
                                      icon: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_videoController!
                                              .value.isPlaying) {
                                            _videoController!.pause();
                                          } else {
                                            _videoController!.play();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              if (_isFaculty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close),
                                    color: Colors.white,
                                    onPressed: () {
                                      setState(() {
                                        _selectedMediaPath = null;
                                        _mediaType = null;
                                        _videoController?.dispose();
                                        _videoController = null;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: _isFaculty
                                  ? Colors.deepPurple.shade300
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isFaculty ? 'Add Photos/Videos' : 'Faculty Only',
                              style: TextStyle(
                                color: _isFaculty
                                    ? Colors.deepPurple.shade300
                                    : Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isFaculty
                          ? Colors.deepPurple.withOpacity(0.1)
                          : Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: _isFaculty,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Post Title *',
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.title,
                          color: _isFaculty
                              ? Colors.deepPurple.shade300
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _contentController,
                      enabled: _isFaculty,
                      maxLines: 8,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Write your post content here... *',
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.edit_note,
                          color: _isFaculty
                              ? Colors.deepPurple.shade300
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isFaculty
                      ? [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: _isFaculty && !_isLoading ? _publishPost : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFaculty
                        ? Colors.deepPurple.shade800
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isFaculty ? Icons.send : Icons.lock,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isFaculty ? 'Publish Post' : 'Faculty Only',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FacultyUploadSheet extends StatefulWidget {
  final String courseTitle;
  final Color courseColor;

  const FacultyUploadSheet({
    super.key,
    required this.courseTitle,
    required this.courseColor,
  });

  @override
  State<FacultyUploadSheet> createState() => _FacultyUploadSheetState();
}

class _FacultyUploadSheetState extends State<FacultyUploadSheet> {
  // Store media for each course
  Map<String, List<Map<String, dynamic>>> courseMedia = {};

  void _uploadMedia(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Record Video'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final video = await picker.pickVideo(
                  source: ImageSource.camera,
                );
                if (video != null && context.mounted) {
                  setState(() {
                    courseMedia.putIfAbsent(widget.courseTitle, () => []);
                    courseMedia[widget.courseTitle]?.add({
                      'type': 'video',
                      'path': video.path,
                      'date': DateTime.now(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video uploaded to course'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Video from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final video = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null && context.mounted) {
                  setState(() {
                    courseMedia.putIfAbsent(widget.courseTitle, () => []);
                    courseMedia[widget.courseTitle]?.add({
                      'type': 'video',
                      'path': video.path,
                      'date': DateTime.now(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video uploaded to course'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null && context.mounted) {
                  setState(() {
                    courseMedia.putIfAbsent(widget.courseTitle, () => []);
                    courseMedia[widget.courseTitle]?.add({
                      'type': 'image',
                      'path': image.path,
                      'date': DateTime.now(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo uploaded to course'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photo from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null && context.mounted) {
                  setState(() {
                    courseMedia.putIfAbsent(widget.courseTitle, () => []);
                    courseMedia[widget.courseTitle]?.add({
                      'type': 'image',
                      'path': image.path,
                      'date': DateTime.now(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo uploaded to course'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addLink(BuildContext context) {
    final linkController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Resource Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Link Title',
                hintText: 'Enter a title for the link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'Enter resource URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (linkController.text.isNotEmpty &&
                  titleController.text.isNotEmpty) {
                setState(() {
                  courseMedia.putIfAbsent(widget.courseTitle, () => []);
                  courseMedia[widget.courseTitle]?.add({
                    'type': 'link',
                    'title': titleController.text,
                    'url': linkController.text,
                    'date': DateTime.now(),
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link added to course')),
                );
              }
            },
            child: const Text('Add Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upload to ${widget.courseTitle}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUploadOption(
            context,
            'Upload Media',
            Icons.add_photo_alternate,
            widget.courseColor,
            () => _uploadMedia(context),
          ),
          const SizedBox(height: 12),
          _buildUploadOption(
            context,
            'Add Resource Link',
            Icons.link,
            widget.courseColor,
            () => _addLink(context),
          ),
          if (courseMedia[widget.courseTitle]?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            Text(
              'Uploaded Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: widget.courseColor,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              itemCount: courseMedia[widget.courseTitle]?.length ?? 0,
              itemBuilder: (context, index) {
                final media = courseMedia[widget.courseTitle]![index];
                return ListTile(
                  leading: Icon(
                    media['type'] == 'video'
                        ? Icons.video_library
                        : media['type'] == 'image'
                            ? Icons.image
                            : Icons.link,
                    color: widget.courseColor,
                  ),
                  title: Text(
                    media['type'] == 'link'
                        ? media['title']
                        : media['type'] == 'video'
                            ? 'Video'
                            : 'Image',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    media['type'] == 'link'
                        ? media['url']
                        : 'Uploaded on ${media['date'].toString().split('.')[0]}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        courseMedia[widget.courseTitle]?.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resource removed from course'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
