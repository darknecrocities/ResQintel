import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  File? _coverImage;
  String _profileImageUrl = '';
  String _coverImageUrl = '';

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _isEditingBio = false;
  bool _isEditingLocation = false;
  bool _isEditingJobTitle = false;
  bool _isEditingEducation = false;
  bool _isEditingSkills = false;

  String fullName = '';
  String phone = '';
  String email = '';
  String birthday = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          fullName = "${data['firstname']} ${data['lastname']}";
          email = data['email'];
          phone = data['phone'];
          birthday = data['birthday'];

          _profileImageUrl = data.containsKey('profileImageUrl')
              ? data['profileImageUrl'] as String
              : '';
          _coverImageUrl = data.containsKey('coverImageUrl')
              ? data['coverImageUrl'] as String
              : '';

          isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile, String fileName) async {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseStorage.instance.ref().child(
      "users/${user.uid}/$fileName.jpg",
    );
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      final url = await _uploadImageToFirebase(file, "profile");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'profileImageUrl': url});

      setState(() {
        _profileImage = file;
        _profileImageUrl = url; // <-- fixed variable name here
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      final url = await _uploadImageToFirebase(file, "cover");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'coverImageUrl': url});

      setState(() {
        _coverImage = file;
        _coverImageUrl = url; // <-- fixed variable name here
      });
    }
  }

  Future<void> _removeProfileImage() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'profileImageUrl': FieldValue.delete()});

    setState(() {
      _profileImage = null;
      _profileImageUrl = '';
    });
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  )
                : Text(
                    controller.text.isEmpty ? 'Not set' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit,
              color: Colors.red,
            ),
            onPressed: isEditing ? onSave : onEdit,
          ),
        ],
      ),
    );
  }

  void _saveAll() {
    // Here, you might want to save the edited fields to Firestore as well
    // (Not implemented yet)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );
    setState(() {
      _isEditingBio = false;
      _isEditingLocation = false;
      _isEditingJobTitle = false;
      _isEditingEducation = false;
      _isEditingSkills = false;
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _jobTitleController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverHeight = 180.0;
    final profileRadius = 64.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAll,
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      GestureDetector(
                        onTap: _pickCoverImage,
                        child: Container(
                          height: coverHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: _coverImage != null
                                ? DecorationImage(
                                    image: FileImage(_coverImage!),
                                    fit: BoxFit.cover,
                                  )
                                : (_coverImageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_coverImageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child: (_coverImage == null && _coverImageUrl.isEmpty)
                              ? Center(
                                  child: Text(
                                    'Tap to upload cover photo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: -profileRadius,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: CircleAvatar(
                                radius: profileRadius,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: profileRadius - 6,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (_profileImageUrl.isNotEmpty
                                            ? NetworkImage(_profileImageUrl)
                                            : null),
                                  child:
                                      (_profileImage == null &&
                                          _profileImageUrl.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 64,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            if (_profileImage != null ||
                                _profileImageUrl.isNotEmpty)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _removeProfileImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    "📞 $phone  |  🎂 $birthday",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEditableField(
                      label: "Bio",
                      controller: _bioController,
                      isEditing: _isEditingBio,
                      maxLines: 3,
                      onEdit: () => setState(() => _isEditingBio = true),
                      onSave: () => setState(() => _isEditingBio = false),
                    ),
                  ),
                  const Divider(height: 40, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildEditableField(
                          label: "Location",
                          controller: _locationController,
                          isEditing: _isEditingLocation,
                          onEdit: () =>
                              setState(() => _isEditingLocation = true),
                          onSave: () =>
                              setState(() => _isEditingLocation = false),
                        ),
                        _buildEditableField(
                          label: "Job Title",
                          controller: _jobTitleController,
                          isEditing: _isEditingJobTitle,
                          onEdit: () =>
                              setState(() => _isEditingJobTitle = true),
                          onSave: () =>
                              setState(() => _isEditingJobTitle = false),
                        ),
                        _buildEditableField(
                          label: "Education",
                          controller: _educationController,
                          isEditing: _isEditingEducation,
                          onEdit: () =>
                              setState(() => _isEditingEducation = true),
                          onSave: () =>
                              setState(() => _isEditingEducation = false),
                        ),
                        _buildEditableField(
                          label: "Skills",
                          controller: _skillsController,
                          isEditing: _isEditingSkills,
                          onEdit: () => setState(() => _isEditingSkills = true),
                          onSave: () =>
                              setState(() => _isEditingSkills = false),
                        ),
                        const SizedBox(height: 20),
                        _FeatureTile(
                          icon: Icons.group,
                          title: "Connections",
                          subtitle: "See and manage your connections",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connections feature tapped!'),
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.event,
                          title: "Events",
                          subtitle: "Upcoming events and webinars",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Events feature tapped!'),
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.message,
                          title: "Messages",
                          subtitle: "Chat with your contacts",
                          onTap: () => _showMessagesDialog(context),
                        ),
                        _FeatureTile(
                          icon: Icons.settings,
                          title: "Settings",
                          subtitle: "Manage account settings",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                        ),
                        _FeatureTile(
                          icon: Icons.help,
                          title: "Help & Support",
                          subtitle: "Get assistance and FAQs",
                          onTap: () => _showHelpSupportDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

void _showMessagesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Messages'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: const [
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Sample message 1'),
              subtitle: Text('Hello from user A!'),
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Sample message 2'),
              subtitle: Text('Reminder: Meeting at 3 PM.'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showHelpSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Help & Support'),
      content: const Text(
        'For assistance about the app, please contact resqintel@gmail.com or call 123-456-7890.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
