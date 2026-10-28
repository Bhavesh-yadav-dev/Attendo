import 'dart:io';

import 'package:attendo/services/student_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  // Controllers
  final nameController = TextEditingController();
  final rollController = TextEditingController();

  // Image picker
  final ImagePicker picker = ImagePicker();

  // Selected images
  File? photo1;
  File? photo2;
  File? photo3;

  // Loading state
  bool _loading = false;

  // Pick image — shows bottom sheet with Camera / Gallery choice
  Future<void> pickImage(int imageNumber) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                "Select Photo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.camera_alt_rounded),
                ),
                title: const Text("Camera"),
                subtitle: const Text("Take a new photo"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),

              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library_rounded),
                ),
                title: const Text("Gallery"),
                subtitle: const Text("Choose from gallery"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      if (imageNumber == 1) {
        photo1 = File(pickedFile.path);
      } else if (imageNumber == 2) {
        photo2 = File(pickedFile.path);
      } else if (imageNumber == 3) {
        photo3 = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Student")),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),

            child: Column(
              children: [
                // Student Name
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],

                  decoration: const InputDecoration(
                    labelText: "Student Name",
                    hintText: "Enter student name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Roll Number
                TextField(
                  controller: rollController,
                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  decoration: const InputDecoration(
                    labelText: "Roll Number",
                    hintText: "Enter roll number",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                // Photo 1
                imageSection(
                  title: "Photo 1",
                  image: photo1,
                  onPressed: () => pickImage(1),
                ),

                const SizedBox(height: 20),

                // Photo 2
                imageSection(
                  title: "Photo 2",
                  image: photo2,
                  onPressed: () => pickImage(2),
                ),

                const SizedBox(height: 20),

                // Photo 3
                imageSection(
                  title: "Photo 3",
                  image: photo3,
                  onPressed: () => pickImage(3),
                ),

                const SizedBox(height: 30),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            // Validate name
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter student name"),
                                ),
                              );
                              return;
                            }

                            // Validate roll number
                            if (rollController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter roll number"),
                                ),
                              );
                              return;
                            }

                            // Validate photos
                            if (photo1 == null ||
                                photo2 == null ||
                                photo3 == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select all 3 photos"),
                                ),
                              );
                              return;
                            }

                            setState(() => _loading = true);

                            final result = await StudentApi.addStudent(
                              name: nameController.text.trim(),
                              rollNo: rollController.text.trim(),
                              photo1: photo1!,
                              photo2: photo2!,
                              photo3: photo3!,
                            );

                            setState(() => _loading = false);

                            if (!mounted) return;

                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Clear form after success
                              nameController.clear();
                              rollController.clear();
                              setState(() {
                                photo1 = null;
                                photo2 = null;
                                photo3 = null;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Add Student"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable image section
  Widget imageSection({
    required String title,
    required File? image,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          height: 200,

          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(10),
          ),

          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(image, fit: BoxFit.cover),
                )
              : const Center(child: Icon(Icons.image, size: 70)),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.photo),
            label: const Text("Pick Image"),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    super.dispose();
  }
}
