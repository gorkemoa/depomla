// lib/pages/add_listing_page.dart

import 'package:flutter/material.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/listing_model.dart';
import '../services/listing_service.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _error;

  // İlan türünü seçmek için enum kullanıyoruz
  ListingType _selectedType = ListingType.deposit;

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileId = const Uuid().v4();
    Reference storageRef =
        FirebaseStorage.instance.ref().child('listing_images').child('$fileId.jpg');
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _addListing() async {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String priceText = priceController.text.trim();

    if (title.isEmpty || description.isEmpty || priceText.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve bir fotoğraf seçin.')),
      );
      return;
    }

    double? price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir fiyat girin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Kullanıcı bilgilerini al
      AuthService authService = AuthService();
      final user = await authService.getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış.');
      }

      // Fotoğrafı yükle
      String imageUrl = await _uploadImage(_imageFile!);

      // İlanı Firestore'a ekle
      Listing listing = Listing(
        id: '',
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
        userId: user.uid,
        createdAt: Timestamp.now(),
        listingType: _selectedType, // listingType parametresini ekledik
      );

      await FirebaseFirestore.instance
          .collection('listings')
          .add(listing.toMap());

      // Başarılı mesajı ve geri dönme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla eklendi.')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('İlan ekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan eklenirken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  // İlan Başlığı
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'İlan Başlığı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // İlan Açıklaması
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'İlan Açıklaması',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // İlan Fiyatı
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Fiyat (₺)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // İlan Türü Seçimi
                  DropdownButtonFormField<ListingType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'İlan Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: ListingType.values.map((ListingType type) {
                      return DropdownMenuItem<ListingType>(
                        value: type,
                        child: Text(type == ListingType.deposit
                            ? 'Eşyalarını Depolamak'
                            : 'Ek Gelir için Eşya Depolamak'),
                      );
                    }).toList(),
                    onChanged: (ListingType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fotoğraf Seçme
                  GestureDetector(
                    onTap: _pickImage,
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // İlan Ekleme Butonu
                  ElevatedButton(
                    onPressed: _addListing,
                    child: const Text('İlan Ekle'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}