// lib/pages/edit_listing_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> currentData;

  const EditListingPage({Key? key, required this.listingId, required this.currentData}) : super(key: key);

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _title = widget.currentData['title'];
    _description = widget.currentData['description'];
    _imageUrl = widget.currentData['imageUrl'];
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      // Yükleme göstergesini göstermek için durumu güncelleyin
    });

    try {
      await FirebaseFirestore.instance.collection('listings').doc(widget.listingId).update({
        'title': _title,
        'description': _description,
        'imageUrl': _imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla güncellendi.')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('İlan güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan güncellenirken bir hata oluştu.')),
      );
    } finally {
      // Yükleme göstergesini gizlemek için durumu güncelleyin
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('İlanı Düzenle'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Başlık
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Başlık boş olamaz' : null,
                    onSaved: (value) => _title = value,
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Açıklama boş olamaz' : null,
                    onSaved: (value) => _description = value,
                  ),
                  const SizedBox(height: 16),

                  // Görüntü URL'si
                  TextFormField(
                    initialValue: _imageUrl,
                    decoration: const InputDecoration(
                      labelText: 'Görüntü URL\'si',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Görüntü URL\'si boş olamaz' : null,
                    onSaved: (value) => _imageUrl = value,
                  ),
                  const SizedBox(height: 16),

                  // Güncelle Butonu
                  ElevatedButton.icon(
                    onPressed: _updateListing,
                    icon: const Icon(Icons.save),
                    label: const Text('Güncelle'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              )),
        ));
  }
}