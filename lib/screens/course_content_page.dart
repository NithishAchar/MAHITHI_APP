import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CourseContentPage extends StatefulWidget {
  final String courseTitle;
  final Color courseColor;

  const CourseContentPage({
    super.key,
    required this.courseTitle,
    required this.courseColor,
  });

  @override
  State<CourseContentPage> createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> {
  final List<Map<String, dynamic>> courseContent = [];
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourseContent();
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

  Future<void> _loadCourseContent() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getStringList('${widget.courseTitle}_content') ?? [];
    setState(() {
      courseContent.clear();
      for (var item in content) {
        final Map<String, dynamic> contentMap = json.decode(item);
        courseContent.add(contentMap);
      }
      // Sort content by date in descending order (newest first)
      courseContent.sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );
    });
  }

  Future<void> _saveCourseContent() async {
    final prefs = await SharedPreferences.getInstance();
    final content = courseContent.map((item) => json.encode(item)).toList();
    await prefs.setStringList('${widget.courseTitle}_content', content);
  }

  bool get _isFaculty => _userType == 'faculty';
  bool get _isStudent => _userType == 'student';
  bool get _isPublic => _userType == 'public';

  void _uploadMedia() async {
    if (!_isFaculty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                        courseContent.add({
                          'type': 'video',
                          'path': video.path,
                          'date': DateTime.now().toString(),
                        });
                      });
                      await _saveCourseContent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video uploaded')),
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
                        courseContent.add({
                          'type': 'video',
                          'path': video.path,
                          'date': DateTime.now().toString(),
                        });
                      });
                      await _saveCourseContent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video uploaded')),
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
                        courseContent.add({
                          'type': 'image',
                          'path': image.path,
                          'date': DateTime.now().toString(),
                        });
                      });
                      await _saveCourseContent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo uploaded')),
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
                        courseContent.add({
                          'type': 'image',
                          'path': image.path,
                          'date': DateTime.now().toString(),
                        });
                      });
                      await _saveCourseContent();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo uploaded')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _addLink() async {
    if (!_isFaculty) return;

    final linkController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () async {
                  if (linkController.text.isNotEmpty &&
                      titleController.text.isNotEmpty) {
                    setState(() {
                      courseContent.add({
                        'type': 'link',
                        'title': titleController.text,
                        'url': linkController.text,
                        'date': DateTime.now().toString(),
                      });
                    });
                    await _saveCourseContent();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Link added')));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle),
        backgroundColor: widget.courseColor.withOpacity(0.1),
      ),
      body: Column(
        children: [
          if (_isFaculty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadMedia,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.courseColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addLink,
                      icon: const Icon(Icons.link),
                      label: const Text('Add Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.courseColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child:
                courseContent.isEmpty
                    ? Center(
                      child: Text(
                        'No content uploaded yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: courseContent.length,
                      itemBuilder: (context, index) {
                        final content = courseContent[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              content['type'] == 'video'
                                  ? Icons.video_library
                                  : content['type'] == 'image'
                                  ? Icons.image
                                  : Icons.link,
                              color: widget.courseColor,
                            ),
                            title: Text(
                              content['type'] == 'link'
                                  ? content['title']
                                  : '${content['type'].toString().capitalize()} ${index + 1}',
                            ),
                            subtitle: Text(
                              content['type'] == 'link'
                                  ? content['url']
                                  : content['date'].toString().split('.')[0],
                            ),
                            trailing:
                                _isFaculty
                                    ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          courseContent.removeAt(index);
                                        });
                                      },
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
