import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ItemStoragePage extends StatefulWidget {
  const ItemStoragePage({super.key});

  @override
  State<ItemStoragePage> createState() => _ItemStoragePageState();
}

class _ItemStoragePageState extends State<ItemStoragePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
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
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir resim ekleyin!'),
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
              .child('item_storage/${const Uuid().v4()}.jpg');
          final uploadTask = await ref.putFile(image);
          final imageUrl = await uploadTask.ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        // Ortak `listings` koleksiyonuna ekle
        final listingsRef =
            await FirebaseFirestore.instance.collection('listings').add({
          'category': 'Item',
          'title': _titleController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'location': _locationController.text.trim(),
          'images': imageUrls,
          'created_at': Timestamp.now(),
        });

        // `item_storage` koleksiyonuna ekle
        await FirebaseFirestore.instance.collection('item_storage').add({
          'listings_id': listingsRef.id,
          'description': _descriptionController.text.trim(),
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eşya depolama ilanı başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedImages.clear();
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
        title: const Text('Eşya Depolama'),
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
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Konum'),
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen bir konum girin' : null,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages
                        .map(
                          (image) => Stack(
                            children: [
                              Image.file(
                                image,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedImages.remove(image)),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
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
