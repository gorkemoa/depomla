// lib/pages/add_listing_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/listing_model.dart';
import 'listings_details_page.dart';

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

  Future<void> _addListing() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Lütfen tüm alanları doldurun ve bir fotoğraf seçin.')),
      );
      return;
    }

    double? price = double.tryParse(priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir fiyat girin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcı bilgilerini al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      // Fotoğrafı yükle
      String fileId = const Uuid().v4();
      String imageUrl = await FirebaseStorage.instance
          .ref()
          .child('listing_images')
          .child('$fileId.jpg')
          .putFile(_imageFile!)
          .then((snapshot) => snapshot.ref.getDownloadURL());

      // İlanı oluştur
      Listing listing = Listing(
        id: '', // ID, Firestore tarafından otomatik atanacak
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        imageUrl: imageUrl,
        userId: user.uid,
        createdAt: Timestamp.now(),
        listingType: _selectedType,
      );

      // Firestore'a ilan ekle
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('listings')
          .add(listing.toMap());

      // Firestore tarafından atanan ID'yi ilan nesnesine ekle
      listing = listing.copyWith(id: docRef.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla eklendi.')),
      );

// Formu sıfırla
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
      setState(() {
        _imageFile = null;
      });

// İlan detayına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListingDetailPage(listing: listing),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
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
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni İlan Oluştur',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Fotoğraf Seçme
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt,
                                    size: 50, color: Colors.grey),
                                Text('Fotoğraf Yükle',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // İlan Başlığı
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'İlan Başlığı',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // İlan Açıklaması
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fiyat Girişi
                  TextField(
                    controller: priceController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Fiyat (₺)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // İlan Türü
                  DropdownButtonFormField<ListingType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'İlan Türü',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ListingType.values.map((ListingType type) {
                      return DropdownMenuItem<ListingType>(
                        value: type,
                        child: Text(type == ListingType.deposit
                            ? 'Eşyalarını Depolamak'
                            : 'Ek Gelir için Depolamak'),
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
                  const SizedBox(height: 20),

                  // İlan Ekle Butonu
                  ElevatedButton(
                    onPressed: _addListing,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('İlan Ekle'),
                  ),
                ],
              ),
            ),
    );
  }
}
