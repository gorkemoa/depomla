import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/listing_model.dart'; // ListingType burada tanımlı
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../models/neighborhood_model.dart';
import '../../services/location_service.dart';
import '../auth_page/login_page.dart';
import 'listings_details_page.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolörler
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final metreKareController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  // Resimler
  List<File> _imageFiles = [];
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Özellikler
  Map<String, bool> _features = {
    'Güvenlik Kamerası': false,
    'Alarm Sistemi': false,
    '24 Saat Güvenlik': false,
    'Yangın Söndürme Sistemi': false,
  };

  // Lokasyon verileri
  List<City> _citiesList = [];
  List<District> _districtsList = [];
  List<Neighborhood> _neighborhoodsList = [];
  City? _selectedCity;
  District? _selectedDistrict;
  Neighborhood? _selectedNeighborhood;

  // Depolama türü ve ilan türü
  String? _selectedStorageType;
  ListingType? _selectedListingType;
  final List<String> _storageTypes = ['İç Mekan', 'Dış Mekan'];

  // Tarih formatı ve lokasyon servisi
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final LocationService _locationService = LocationService();

  // Yeni alanlar
  String? _itemType;
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _itemWeightController = TextEditingController();
  String? _itemCondition;
  final _specialRequirementsController = TextEditingController();
  bool _requiresTemperatureControl = false;
  bool _requiresDryEnvironment = false;
  bool _insuranceRequired = false;
  List<String> _prohibitedConditions = [];
  bool _ownerPickup = false;
  final _deliveryDetailsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  List<String> _preferredFeatures = [];

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  @override
  void dispose() {
    // Tüm kontrolörleri temizleyin
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    metreKareController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _itemWeightController.dispose();
    _specialRequirementsController.dispose();
    _deliveryDetailsController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  // Kullanıcı doğrulamasını kontrol etme
  Future<void> _checkUserAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      await _loadCities();
    }
  }

  // Şehirleri yükleme
  Future<void> _loadCities() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _citiesList = await _locationService.getCities();
      print('Loaded ${_citiesList.length} cities');
    } catch (e) {
      _showSnackBar('Şehirler yüklenirken hata oluştu: $e');
      print('Error loading cities: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // İlçeleri yükleme
  Future<void> _loadDistricts(String cityId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      _districtsList = await _locationService.getDistricts(cityId);
      print('Loaded ${_districtsList.length} districts for city $cityId');
    } catch (e) {
      _showSnackBar('İlçeler yüklenirken hata oluştu: $e');
      print('Error loading districts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mahalleleri yükleme
  Future<void> _loadNeighborhoods(String cityId, String districtId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      _neighborhoodsList =
          await _locationService.getNeighborhoods(cityId, districtId);
      print(
          'Loaded ${_neighborhoodsList.length} neighborhoods for district $districtId in city $cityId');
    } catch (e) {
      _showSnackBar('Mahalleler yüklenirken hata oluştu: $e');
      print('Error loading neighborhoods: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Tarih seçme fonksiyonu
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent, // Başlık ve buton renkleri
              onPrimary: Colors.white, // Buton metin rengi
              onSurface: Colors.black, // Tarih seçme arka plan rengi
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = _dateFormat.format(picked);
      });
    }
  }

  // Resim seçme fonksiyonu
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
      if (pickedFiles != null) {
        setState(() {
          _imageFiles
              .addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      _showSnackBar('Fotoğraf seçilirken hata oluştu: $e');
      print('Error picking images: $e');
    }
  }

  // Resim kaldırma fonksiyonu
  void _removeImage(int index) {
    setState(() {
      if (index >= 0 && index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      }
    });
  }

  // SnackBar gösterme fonksiyonu
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Resimleri Firebase Storage'a yükleme
  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    try {
      for (var image in _imageFiles) {
        String fileName = Uuid().v4();
        Reference ref =
            FirebaseStorage.instance.ref().child('listing_images').child(fileName);
        UploadTask uploadTask = ref.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    } catch (e) {
      throw Exception('Fotoğraflar yüklenirken hata oluştu: $e');
    }
    return downloadUrls;
  }

  // İlan ekleme fonksiyonu
  Future<void> _addListing() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Lütfen gerekli alanları doldurun.');
      return;
    }

    if (_imageFiles.isEmpty) {
      _showSnackBar('Lütfen en az bir fotoğraf seçin.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      // Fotoğrafları yükleyin
      List<String> imageUrls = await _uploadImages();

      // Yeni bir Listing nesnesi oluşturun
      Listing newListing = Listing(
        id: '', // Firestore'dan alınacak
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        imageUrl: imageUrls,
        userId: user.uid,
        createdAt: Timestamp.now(),
        listingType: _selectedListingType!,
        size: _selectedListingType == ListingType.storage
            ? double.parse(metreKareController.text.trim())
            : null,
        city: _selectedCity?.sehirAdi, // İsimle kaydediyoruz
        district: _selectedDistrict?.ilceAdi, // İsimle kaydediyoruz
        neighborhood: _selectedNeighborhood?.mahalleAdi, // İsimle kaydediyoruz
        storageType: _selectedStorageType,
        features: _selectedListingType == ListingType.storage ? _features : {},
        startDate: startDateController.text.trim(),
        endDate: endDateController.text.trim(),
        // Yeni alanlar
        itemType: _itemType,
        itemDimensions: (_lengthController.text.isNotEmpty &&
                _widthController.text.isNotEmpty &&
                _heightController.text.isNotEmpty)
            ? {
                'length': double.parse(_lengthController.text.trim()),
                'width': double.parse(_widthController.text.trim()),
                'height': double.parse(_heightController.text.trim()),
              }
            : null,
        itemWeight: _itemWeightController.text.isNotEmpty
            ? double.parse(_itemWeightController.text.trim())
            : null,
        requiresTemperatureControl: _requiresTemperatureControl,
        requiresDryEnvironment: _requiresDryEnvironment,
        insuranceRequired: _insuranceRequired,
        prohibitedConditions:
            _prohibitedConditions.isNotEmpty ? _prohibitedConditions : null,
        ownerPickup: _ownerPickup,
        deliveryDetails: _deliveryDetailsController.text.trim().isNotEmpty
            ? _deliveryDetailsController.text.trim()
            : null,
        additionalNotes: _additionalNotesController.text.trim().isNotEmpty
            ? _additionalNotesController.text.trim()
            : null,
        preferredFeatures:
            _preferredFeatures.isNotEmpty ? _preferredFeatures : null,
      );

      // Firestore'a ekleme
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('listings')
          .add(newListing.toMap());

      // ID'yi güncelle
      await docRef.update({'id': docRef.id});

      _showSnackBar('İlan başarıyla eklendi.');
      _resetForm();

      // İlan detay sayfasına yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ListingDetailPage(listing: newListing.copyWith(id: docRef.id)),
        ),
      );
    } catch (e) {
      _showSnackBar('Hata: $e');
      print('Error adding listing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Formu sıfırlama fonksiyonu
  void _resetForm() {
    _formKey.currentState?.reset();
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    metreKareController.clear();
    startDateController.clear();
    endDateController.clear();
    _imageFiles.clear();
    _selectedCity = null;
    _selectedDistrict = null;
    _selectedNeighborhood = null;
    _selectedStorageType = null;
    _features.updateAll((key, value) => false);
    _selectedListingType = null;
    _itemType = null;
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _itemWeightController.clear();
    _requiresTemperatureControl = false;
    _requiresDryEnvironment = false;
    _insuranceRequired = false;
    _prohibitedConditions.clear();
    _ownerPickup = false;
    _deliveryDetailsController.clear();
    _additionalNotesController.clear();
    _preferredFeatures.clear();
  }

  // Boyut alanları için yardımcı widget
  Widget _buildDimensionField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.straighten),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        // İsteğe bağlı validation
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.blueAccent.shade700,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ekle'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Genel Bilgiler
                          Text('Genel Bilgiler', style: titleStyle),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'İlan Başlığı',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.title),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Boş bırakılamaz' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Açıklama',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.description),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Boş bırakılamaz' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<ListingType>(
                            value: _selectedListingType,
                            decoration: InputDecoration(
                              labelText: 'İlan Türü',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.category),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: ListingType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type == ListingType.deposit
                                    ? 'Eşyanı Depolamak'
                                    : 'Depolama'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedListingType = val;
                                // Özellikleri sıfırla eğer ilan türü 'deposit' ise
                                if (_selectedListingType == ListingType.deposit) {
                                  _features.updateAll((key, value) => false);
                                }
                              });
                            },
                            validator: (val) => val == null ? 'Seçim yapın' : null,
                          ),
                          const SizedBox(height: 24),

                          // Fiyat ve Boyut
                          Text('Fiyat ve Boyut', style: titleStyle),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Fiyat (₺)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Boş bırakılamaz.';
                              if (double.tryParse(val) == null)
                                return 'Geçerli bir sayı girin.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_selectedListingType == ListingType.storage)
                            TextFormField(
                              controller: metreKareController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Metre Kare',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.straighten),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (val) {
                                if (_selectedListingType == ListingType.storage) {
                                  if (val == null || val.isEmpty)
                                    return 'Boş bırakılamaz.';
                                  if (double.tryParse(val) == null)
                                    return 'Geçerli bir sayı girin.';
                                }
                                return null;
                              },
                            ),
                          if (_selectedListingType == ListingType.storage)
                            const SizedBox(height: 16),

                          // Konum Bilgileri
                          Text('Konum Bilgileri', style: titleStyle),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<City>(
                            value: _selectedCity,
                            decoration: InputDecoration(
                              labelText: 'Şehir',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_city),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: _citiesList.map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Text(city.sehirAdi),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              setState(() {
                                _selectedCity = val;
                                _selectedDistrict = null;
                                _selectedNeighborhood = null;
                                _districtsList = [];
                                _neighborhoodsList = [];
                              });
                              if (val != null) {
                                await _loadDistricts(val.id);
                              }
                            },
                            validator: (val) => val == null ? 'Seçim yapın' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<District>(
                            value: _selectedDistrict,
                            decoration: InputDecoration(
                              labelText: 'İlçe',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_city),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: _districtsList.map((district) {
                              return DropdownMenuItem(
                                value: district,
                                child: Text(district.ilceAdi),
                              );
                            }).toList(),
                            onChanged: (val) async {
                              setState(() {
                                _selectedDistrict = val;
                                _selectedNeighborhood = null;
                                _neighborhoodsList = [];
                              });
                              if (val != null && _selectedCity != null) {
                                await _loadNeighborhoods(
                                    _selectedCity!.id, val.id);
                              }
                            },
                            validator: (val) => val == null ? 'Seçim yapın' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Neighborhood>(
                            value: _selectedNeighborhood,
                            decoration: InputDecoration(
                              labelText: 'Mahalle',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_city),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: _neighborhoodsList.map((neighborhood) {
                              return DropdownMenuItem(
                                value: neighborhood,
                                child: Text(neighborhood.mahalleAdi),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedNeighborhood = val;
                              });
                            },
                            validator: (val) => val == null ? 'Seçim yapın' : null,
                          ),
                          const SizedBox(height: 24),

                          // Depolama Detayları
                          if (_selectedListingType == ListingType.storage)
                            Text('Depolama Detayları', style: titleStyle),
                          if (_selectedListingType == ListingType.storage)
                            const SizedBox(height: 12),
                          if (_selectedListingType == ListingType.storage)
                            DropdownButtonFormField<String>(
                              value: _selectedStorageType,
                              decoration: InputDecoration(
                                labelText: 'Depolama Türü',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.storage),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              items: _storageTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedStorageType = val;
                                });
                              },
                              validator: (val) => val == null ? 'Seçim yapın' : null,
                            ),
                          if (_selectedListingType == ListingType.storage)
                            const SizedBox(height: 24),

                          // Tarihler
                          Text('Tarihler', style: titleStyle),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: startDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Başlangıç Tarihi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.date_range),
                                onPressed: () =>
                                    _selectDate(context, startDateController),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Seçim yapın' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: endDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Bitiş Tarihi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.date_range),
                                onPressed: () =>
                                    _selectDate(context, endDateController),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                // Bitiş tarihinin başlangıç tarihinden sonra olduğundan emin olun
                                try {
                                  DateTime startDate = _dateFormat
                                      .parse(startDateController.text.trim());
                                  DateTime endDate =
                                      _dateFormat.parse(val.trim());
                                  if (endDate.isBefore(startDate)) {
                                    return 'Bitiş tarihi başlangıç tarihinden önce olamaz.';
                                  }
                                } catch (e) {
                                  return 'Geçerli bir tarih seçin.';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Özellikler - Sadece 'Depolama' ilan türü için göster
                          if (_selectedListingType == ListingType.storage)
                            Text('Özellikler', style: titleStyle),
                          if (_selectedListingType == ListingType.storage)
                            const SizedBox(height: 12),
                          if (_selectedListingType == ListingType.storage)
                            Column(
                              children: _features.keys.map((key) {
                                return CheckboxListTile(
                                  title: Text(key),
                                  value: _features[key],
                                  activeColor: Colors.blueAccent,
                                  onChanged: (val) {
                                    setState(() {
                                      _features[key] = val ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          if (_selectedListingType == ListingType.storage)
                            const SizedBox(height: 24),

                          // Ekstra Bilgiler - Sadece 'Depolama' ilan türü için göster
                          if (_selectedListingType == ListingType.deposit)
                            Text('Ekstra Bilgiler', style: titleStyle),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 12),
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Eşya Türü',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _itemType =
                                      val.trim().isEmpty ? null : val.trim();
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),
                          if (_selectedListingType == ListingType.deposit)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDimensionField(
                                      _lengthController, 'Uzunluk (m)'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDimensionField(
                                      _widthController, 'Genişlik (m)'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDimensionField(
                                      _heightController, 'Yükseklik (m)'),
                                ),
                              ],
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              controller: _itemWeightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Eşya Ağırlığı (kg)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.fitness_center),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (val) {
                                if (val != null &&
                                    val.isNotEmpty &&
                                    double.tryParse(val) == null) {
                                  return 'Geçerli bir sayı girin.';
                                }
                                return null;
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),
                          if (_selectedListingType == ListingType.deposit)
                            SwitchListTile(
                              title: const Text('Sıcaklık Kontrolü Gerekiyor mu?'),
                              activeColor: Colors.blueAccent,
                              value: _requiresTemperatureControl,
                              onChanged: (val) {
                                setState(() {
                                  _requiresTemperatureControl = val;
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            SwitchListTile(
                              title: const Text('Kuru Ortam Gerekiyor mu?'),
                              activeColor: Colors.blueAccent,
                              value: _requiresDryEnvironment,
                              onChanged: (val) {
                                setState(() {
                                  _requiresDryEnvironment = val;
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            SwitchListTile(
                              title: const Text('Sigorta Gerekiyor mu?'),
                              activeColor: Colors.blueAccent,
                              value: _insuranceRequired,
                              onChanged: (val) {
                                setState(() {
                                  _insuranceRequired = val;
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),

                          // Yasaklı Şartlar
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Yasaklı Şartlar',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.block),
                                helperText:
                                    'Virgülle ayrılmış olarak yazın (örn: Açık ateş, Zehirli maddeler)',
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _prohibitedConditions = val
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((element) => element.isNotEmpty)
                                      .toList();
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),

                          // Sahip Pickup
                          if (_selectedListingType == ListingType.deposit)
                            SwitchListTile(
                              title: const Text('Eşyayı Sahibi Alacak mı?'),
                              activeColor: Colors.blueAccent,
                              value: _ownerPickup,
                              onChanged: (val) {
                                setState(() {
                                  _ownerPickup = val;
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),

                          // Teslimat Detayları
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              controller: _deliveryDetailsController,
                              decoration: InputDecoration(
                                labelText: 'Teslimat Detayları',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.delivery_dining),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),

                          // Ek Notlar
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              controller: _additionalNotesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Ek Notlar',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.note),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 16),

                          // Tercih Edilen Özellikler
                          if (_selectedListingType == ListingType.deposit)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Tercih Edilen Özellikler',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.favorite),
                                helperText:
                                    'Virgülle ayrılmış olarak yazın (örn: Güvenli, Kapalı Alan)',
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _preferredFeatures = val
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((element) => element.isNotEmpty)
                                      .toList();
                                });
                              },
                            ),
                          if (_selectedListingType == ListingType.deposit)
                            const SizedBox(height: 24),

                          // Fotoğraflar
                          Text('Fotoğraflar', style: titleStyle),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.blueAccent),
                              ),
                              child: _imageFiles.isEmpty
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.camera_alt,
                                            size: 50, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Fotoğraf Yükle',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ],
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: _imageFiles.length,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                _imageFiles[index],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Gönder Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addListing,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.blueAccent,
                                elevation: 5,
                                shadowColor:
                                    Colors.blueAccent.withOpacity(0.5),
                              ),
                              child: const Text(
                                'Gönder',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          // Yükleme işlemi sırasında ekranın kararmasını önlemek için
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}