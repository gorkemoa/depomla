import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<File> _selectedImages = [];
  final String _ownerId = "user_12345"; // Örnek Kullanıcı ID
  final String _listingId = const Uuid().v4();
  String _selectedType = "oda";
  bool _isAvailable = true;
  bool _isUploading = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _selectedImages) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('listings/$_listingId/${const Uuid().v4()}.jpg');
      final uploadTask = await ref.putFile(image);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }
    return imageUrls;
  }

  Future<void> _addListing() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String priceText = _priceController.text.trim();
    final String location = _locationController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        priceText.isEmpty ||
        location.isEmpty ||
        _availableFrom == null ||
        _availableUntil == null ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanlar doldurulmalıdır!')),
      );
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir fiyat girin!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrls = await _uploadImages();

      await FirebaseFirestore.instance.collection('listings').doc(_listingId).set({
        "listing_id": _listingId,
        "owner_id": _ownerId,
        "title": title,
        "description": description,
        "location": location,
        "type": _selectedType,
        "price": price,
        "available_from": Timestamp.fromDate(_availableFrom!),
        "available_until": Timestamp.fromDate(_availableUntil!),
        "images": imageUrls,
        "is_available": _isAvailable,
        "created_at": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla eklendi!')),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    _selectedImages.clear();
    _availableFrom = null;
    _availableUntil = null;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _availableFrom = picked;
        } else {
          _availableUntil = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İlan Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField('Başlık', _titleController),
            const SizedBox(height: 10),
            _buildTextField('Açıklama', _descriptionController, maxLines: 3),
            const SizedBox(height: 10),
            _buildTextField('Fiyat', _priceController, keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            _buildTextField('Konum', _locationController),
            const SizedBox(height: 10),
            _buildDropdown(),
            const SizedBox(height: 10),
            _buildDatePickers(),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _addListing,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('İlanı Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: const [
        DropdownMenuItem(value: "oda", child: Text("Oda")),
        DropdownMenuItem(value: "bodrum", child: Text("Bodrum")),
        DropdownMenuItem(value: "garaj", child: Text("Garaj")),
      ],
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Tür',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _selectDate(context, true),
            child: Text(
              _availableFrom == null
                  ? 'Başlangıç Tarihi'
                  : 'Başlangıç: ${_availableFrom!.toLocal()}',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _selectDate(context, false),
            child: Text(
              _availableUntil == null
                  ? 'Bitiş Tarihi'
                  : 'Bitiş: ${_availableUntil!.toLocal()}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _pickImages,
          child: const Text('Resimleri Seç'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedImages.map((image) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                image,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
