import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class StorageRentalPage extends StatefulWidget {
  const StorageRentalPage({super.key});

  @override
  State<StorageRentalPage> createState() => _StorageRentalPageState();
}

class _StorageRentalPageState extends State<StorageRentalPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  String? _selectedType;
  DateTime? _availableFrom;
  DateTime? _availableUntil;

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        if (_selectedImages.length + pickedFiles.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('En fazla 5 resim seçebilirsiniz.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAd() async {
    if (_formKey.currentState!.validate()) {
      if (_availableFrom == null || _availableUntil == null || _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm alanları doldurun!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Resimleri Firebase Storage'a yükle
        List<String> imageUrls = [];
        for (var image in _selectedImages) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('storage_listings/${const Uuid().v4()}.jpg');
          final uploadTask = await ref.putFile(image);
          final imageUrl = await uploadTask.ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        // Ortak `listings` koleksiyonuna ekle
        final listingsRef =
            await FirebaseFirestore.instance.collection('listings').add({
          'category': 'Storage',
          'title': _titleController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'location': _locationController.text.trim(),
          'images': imageUrls,
          'created_at': Timestamp.now(),
        });

        // `storage_listings` koleksiyonuna ekle
        await FirebaseFirestore.instance.collection('storage_listings').doc(listingsRef.id).set({
          'listings_id': listingsRef.id,
          'description': _descriptionController.text.trim(),
          'area': _areaController.text.trim(),
          'type': _selectedType,
          'available_from': Timestamp.fromDate(_availableFrom!),
          'available_until': Timestamp.fromDate(_availableUntil!),
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depo kiralama ilanı başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedImages.clear();
          _availableFrom = null;
          _availableUntil = null;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depo Kiralama'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen bir başlık girin' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen bir açıklama girin' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty
                        ? 'Lütfen bir fiyat girin'
                        : double.tryParse(value) == null
                            ? 'Geçerli bir fiyat girin'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Metrekare (m²)'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen metrekare girin' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tür'),
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'Oda', child: Text('Oda')),
                      DropdownMenuItem(value: 'Garaj', child: Text('Garaj')),
                      DropdownMenuItem(value: 'Bodrum Katı', child: Text('Bodrum Katı')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) =>
                        value == null ? 'Lütfen bir tür seçin' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImages,
                    child: const Text('Resim Seç'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAd,
                    child: const Text('Gönder'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
