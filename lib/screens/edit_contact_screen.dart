import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class EditContactScreen extends StatefulWidget {
  final String? initialName;
  final String? initialNumber;
  final String? initialEmail;
  final bool isNew;

  const EditContactScreen({
    super.key,
    this.initialName,
    this.initialNumber,
    this.initialEmail,
    this.isNew = false,
  });

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _notesController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _numberController = TextEditingController(text: widget.initialNumber ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _companyController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_nameController.text.isEmpty || _numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and number are required'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text,
      'number': _numberController.text,
      'email': _emailController.text,
      'company': _companyController.text,
      'notes': _notesController.text,
    });
  }

  Future<void> _pickImage() async {
    // Request photo/storage permission
    var status = await Permission.photos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo permission denied'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() {
        _image = File(result.files.single.path!);
      });
    }
  }
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
             ClipRRect(
               borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                 child: Container(
                   decoration: BoxDecoration(
                     color: Theme.of(context).brightness == Brightness.dark 
                       ? Colors.black.withAlpha(200) 
                       : Colors.white.withAlpha(230),
                   ),
                   child: Column(
                     children: [
                       ListTile(
                         leading: const Icon(Icons.photo_library),
                         title: const Text('Choose from gallery'),
                         onTap: () {
                           Navigator.pop(context);
                           _pickImage();
                         },
                       ),
                     ],
                   ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
          ),
          AlertDialog(
            backgroundColor: isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(150),
              ),
            ),
            title: const Text('Delete Contact?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, {'deleted': true}); // Return with deleted flag
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Contact' : 'Edit Contact'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(5),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
               onTap: _saveContact,
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: BackdropFilter(
                   filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(5),
                     child: Center(
                       child: Text(
                         'Save', 
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           color: primaryColor,
                         ),
                       ),
                     ),
                   ),
                 ),
               ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
            // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF121212), const Color(0xFF1E1E24)]
                    : [const Color(0xFFF5F5F7), const Color(0xFFE8E8ED)],
              ),
            ),
          ),
           // Orbs
           Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withAlpha(20), boxShadow: [BoxShadow(color: primaryColor.withAlpha(30), blurRadius: 100, spreadRadius: 20)]))),
           Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(15), boxShadow: [BoxShadow(color: Colors.blue.withAlpha(20), blurRadius: 100, spreadRadius: 20)]))),
           
           // Blur Overlay
           Positioned.fill(
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
               child: Container(color: Colors.transparent),
             ),
           ),

           // Content
           SafeArea(
             child: SingleChildScrollView(
               padding: const EdgeInsets.all(24),
               child: Column(
                 children: [
                   // Avatar
                   GestureDetector(
                     onTap: _showImagePickerOptions,
                     child: Container(
                       width: 100,
                       height: 100,
                       decoration: BoxDecoration(
                         color: primaryColor.withAlpha(30),
                         shape: BoxShape.circle,
                         border: Border.all(color: primaryColor.withAlpha(50)),
                         boxShadow: [
                           BoxShadow(color: primaryColor.withAlpha(30), blurRadius: 20, spreadRadius: 5),
                         ],
                         image: _image != null
                             ? DecorationImage(
                                 image: FileImage(_image!),
                                 fit: BoxFit.cover,
                               )
                             : null,
                       ),
                       child: _image == null
                           ? (_nameController.text.isNotEmpty
                               ? Center(
                                   child: Text(
                                     _nameController.text[0].toUpperCase(),
                                     style: TextStyle(fontSize: 36, color: primaryColor, fontWeight: FontWeight.bold),
                                   ),
                                 )
                               : Icon(Icons.add_a_photo, size: 32, color: primaryColor))
                           : null,
                     ),
                   ),
                   const SizedBox(height: 32),
           
                   // Name Field
                   _buildGlassTextField(
                     controller: _nameController,
                     label: 'Name',
                     icon: Icons.person_outline,
                     onChanged: (value) => setState(() {}),
                   ),
                   const SizedBox(height: 16),
           
                   // Phone Field
                   _buildGlassTextField(
                     controller: _numberController,
                     label: 'Phone',
                     icon: Icons.phone_outlined,
                     keyboardType: TextInputType.phone,
                   ),
                   const SizedBox(height: 16),
           
                   // Email Field
                   _buildGlassTextField(
                     controller: _emailController,
                     label: 'Email',
                     icon: Icons.email_outlined,
                     keyboardType: TextInputType.emailAddress,
                   ),
                   const SizedBox(height: 16),
           
                   // Company Field
                   _buildGlassTextField(
                     controller: _companyController,
                     label: 'Company',
                     icon: Icons.business_outlined,
                   ),
                   const SizedBox(height: 16),
           
                   // Notes Field
                   _buildGlassTextField(
                     controller: _notesController,
                     label: 'Notes',
                     icon: Icons.note_outlined,
                     maxLines: 3,
                   ),
                   const SizedBox(height: 32),
           
                   if (!widget.isNew) ...[
                     const SizedBox(height: 48),
                     ClipRRect(
                       borderRadius: BorderRadius.circular(16),
                       child: BackdropFilter(
                         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                         child: Container(
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: Colors.red.withAlpha(20),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.red.withAlpha(40)),
                           ),
                           child: TextButton.icon(
                             onPressed: _confirmDelete,
                             icon: const Icon(Icons.delete_outline, color: Colors.red),
                             label: const Text('Delete Contact', style: TextStyle(color: Colors.red)),
                             style: TextButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 16),
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                   const SizedBox(height: 50),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
