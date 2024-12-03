// lib/pages/listing_page/add_listing_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/listing_model.dart';
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../models/neighborhood_model.dart';
import '../../services/location_service.dart';
import 'listings_details_page.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllerlar
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController metreKareController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  // Diğer değişkenler
  List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Özellikler için
  Map<String, bool> _features = {
    'Güvenlik Kamerası': false,
    'Alarm Sistemi': false,
    '24 Saat Güvenlik': false,
    'Yangın Söndürme Sistemi': false,
  };

  // Şehir, İlçe, Mahalle gibi alanlar için modellerden listeler
  List<City> _citiesList = [];
  List<District> _districtsList = [];
  List<Neighborhood> _neighborhoodsList = [];
  bool _isCitiesLoading = false;
  bool _isDistrictsLoading = false;
  bool _isNeighborhoodsLoading = false;

  // Seçilen değerler
  City? _selectedCity;
  District? _selectedDistrict;
  Neighborhood? _selectedNeighborhood;
  String? _selectedStorageType;
  ListingType? _selectedListingType;

  final List<String> _storageTypes = ['İç Mekan', 'Dış Mekan'];
  
  // Tarih formatlama
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Stepper için
  int _currentStep = 0;

  // LocationService instance
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isCitiesLoading = true;
    });
    try {
      _citiesList = await _locationService.getCities();
      print('Loaded cities: ${_citiesList.map((city) => city.sehirAdi).toList()}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şehirler yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isCitiesLoading = false;
      });
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    setState(() {
      _isDistrictsLoading = true;
    });
    try {
      _districtsList = await _locationService.getDistricts(cityId);
      print('Loaded districts: ${_districtsList.map((district) => district.ilceAdi).toList()}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlçeler yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isDistrictsLoading = false;
      });
    }
  }

  Future<void> _loadNeighborhoods(String cityId, String districtId) async {
    setState(() {
      _isNeighborhoodsLoading = true;
    });
    try {
      _neighborhoodsList = await _locationService.getNeighborhoods(cityId, districtId);
      print('Loaded neighborhoods: ${_neighborhoodsList.map((n) => n.mahalleAdi).toList()}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mahalleler yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isNeighborhoodsLoading = false;
      });
    }
  }

  // Tarih seçici
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        controller.text = _dateFormat.format(picked);
      });
    }
  }

  // Fotoğraf seçme
  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(imageQuality: 50);
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
      });
      print('Picked ${pickedFiles.length} images.');
    }
  }

  // Fotoğraf silme
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
    print('Removed image at index: $index');
  }

  // İlan ekleme işlemi
  Future<void> _addListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir fotoğraf seçin.')),
      );
      return;
    }

    double? price = double.tryParse(priceController.text.trim());
    double? metreKare = _selectedListingType == ListingType.storage
        ? double.tryParse(metreKareController.text.trim())
        : null;

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir fiyat giriniz.')),
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

      // Fotoğrafları Firebase Storage'a yükle ve URL'leri al
      List<String> imageUrls = [];
      for (var imageFile in _imageFiles) {
        String fileId = const Uuid().v4();
        String imageUrl = await FirebaseStorage.instance
            .ref()
            .child('listing_images')
            .child('$fileId.jpg')
            .putFile(imageFile)
            .then((snapshot) => snapshot.ref.getDownloadURL());
        imageUrls.add(imageUrl);
      }
      print('Uploaded images and obtained URLs.');

      // Seçilen özellikleri filtrele
      Map<String, bool> selectedFeatures = {};
      _features.forEach((key, value) {
        if (value) selectedFeatures[key] = value;
      });

      // İlanı oluştur
      Listing listing = Listing(
        id: '', // Firestore tarafından otomatik atanacak
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        imageUrl: imageUrls,
        userId: user.uid,
        createdAt: Timestamp.now(),
        listingType: _selectedListingType!,
        size: metreKare,
        city: _selectedCity?.sehirAdi,
        district: _selectedDistrict?.ilceAdi,
        neighborhood: _selectedNeighborhood?.mahalleAdi,
        storageType: _selectedStorageType,
        features: selectedFeatures,
        startDate: startDateController.text.trim().isNotEmpty
            ? startDateController.text.trim()
            : null,
        endDate: endDateController.text.trim().isNotEmpty
            ? endDateController.text.trim()
            : null,
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
      _formKey.currentState!.reset();
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
      metreKareController.clear();
      startDateController.clear();
      endDateController.clear();
      setState(() {
        _imageFiles = [];
        _selectedCity = null;
        _selectedDistrict = null;
        _selectedNeighborhood = null;
        _selectedStorageType = null;
        _features.updateAll((key, value) => false);
        _currentStep = 0;
        _selectedListingType = null;
      });

      // İlan detayına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ListingDetailPage(listing: listing),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      print('Error adding listing: $e');
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
    metreKareController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  // Stepper adımlarını oluşturma
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Genel Bilgiler'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            // İlan Türü Seçimi
            DropdownButtonFormField<ListingType>(
              value: _selectedListingType,
              decoration: InputDecoration(
                labelText: 'İlan Türü *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ListingType.values.map((ListingType type) {
                return DropdownMenuItem<ListingType>(
                  value: type,
                  child: Text(type == ListingType.deposit ? 'Eşyanı Depolamak' : 'Depolama'),
                );
              }).toList(),
              onChanged: (ListingType? newValue) {
                setState(() {
                  _selectedListingType = newValue;
                  // Eğer depozito seçildiyse, size alanını sıfırla
                  if (_selectedListingType != ListingType.storage) {
                    metreKareController.clear();
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'İlan türü seçmelisiniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // İlan Başlığı
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'İlan Başlığı *',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İlan başlığı boş olamaz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // İlan Açıklaması
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Açıklama *',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama boş olamaz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fiyat Girişi
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Fiyat (₺) *',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Fiyat boş olamaz.';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Geçerli bir fiyat girin.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Metre Kare Girişi (Koşullu)
            if (_selectedListingType == ListingType.storage) ...[
              TextFormField(
                controller: metreKareController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Metre Kare *',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (_selectedListingType == ListingType.storage) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Metre kare boş olamaz.';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Geçerli bir metre kare değeri girin.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('Konum Bilgileri'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            // Şehir Seçimi
            DropdownButtonFormField<City>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: 'Şehir *',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _isCitiesLoading
                  ? [
                      DropdownMenuItem(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                        value: null,
                      )
                    ]
                  : _citiesList.map((City city) {
                      return DropdownMenuItem<City>(
                        value: city,
                        child: Text(city.sehirAdi),
                      );
                    }).toList(),
              onChanged: (City? newCity) async {
                setState(() {
                  _selectedCity = newCity;
                  _selectedDistrict = null;
                  _selectedNeighborhood = null;
                  _districtsList = [];
                  _neighborhoodsList = [];
                });
                if (newCity != null) {
                  await _loadDistricts(newCity.id);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Şehir seçmelisiniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // İlçe Seçimi
            DropdownButtonFormField<District>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'İlçe *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _isDistrictsLoading
                  ? [
                      DropdownMenuItem(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                        value: null,
                      )
                    ]
                  : _districtsList.map((District district) {
                      return DropdownMenuItem<District>(
                        value: district,
                        child: Text(district.ilceAdi),
                      );
                    }).toList(),
              onChanged: (District? newDistrict) async {
                setState(() {
                  _selectedDistrict = newDistrict;
                  _selectedNeighborhood = null;
                  _neighborhoodsList = [];
                });
                if (newDistrict != null && _selectedCity != null) {
                  await _loadNeighborhoods(_selectedCity!.id, newDistrict.id);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'İlçe seçmelisiniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mahalle Seçimi
            DropdownButtonFormField<Neighborhood>(
              value: _selectedNeighborhood,
              decoration: InputDecoration(
                labelText: 'Mahalle *',
                prefixIcon: const Icon(Icons.house),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _isNeighborhoodsLoading
                  ? [
                      DropdownMenuItem(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                        value: null,
                      )
                    ]
                  : _neighborhoodsList.map((Neighborhood neighborhood) {
                      return DropdownMenuItem<Neighborhood>(
                        value: neighborhood,
                        child: Text(neighborhood.mahalleAdi),
                      );
                    }).toList(),
              onChanged: (Neighborhood? newNeighborhood) {
                setState(() {
                  _selectedNeighborhood = newNeighborhood;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Mahalle seçmelisiniz.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Depolama Detayları'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            // Depolama Türü Seçimi
            DropdownButtonFormField<String>(
              value: _selectedStorageType,
              decoration: InputDecoration(
                labelText: 'Depolama Türü *',
                prefixIcon: const Icon(Icons.storage),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _storageTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStorageType = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Depolama türü seçmelisiniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Başlangıç Tarihi
            TextFormField(
              controller: startDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Başlangıç Tarihi *',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(context, startDateController),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlangıç tarihi seçmelisiniz.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bitiş Tarihi
            TextFormField(
              controller: endDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Bitiş Tarihi',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(context, endDateController),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Özellikler
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Özellikler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: _features.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: _features[key],
                  onChanged: (bool? value) {
                    setState(() {
                      _features[key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Fotoğraflar'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            // Fotoğraf Seçme
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: _imageFiles.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Fotoğraf Yükle', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _imageFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFiles[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
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
            const SizedBox(height: 16),
            if (_imageFiles.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_imageFiles.length} Fotoğraf Seçildi',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
      Step(
        title: const Text('Son Adım'),
        isActive: _currentStep >= 4,
        state: _currentStep >= 4 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            const Text(
              'İlanınızı oluşturmak için son butona tıklayın.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addListing,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.blueAccent,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('İlan Ekle'),
            ),
          ],
        ),
      ),
    ];
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
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < _buildSteps().length - 1) {
                    // İlerleme
                    setState(() {
                      _currentStep += 1;
                    });
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    // Geri alma
                    setState(() {
                      _currentStep -= 1;
                    });
                  }
                },
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  return Row(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == _buildSteps().length - 1 ? 'Son Adım' : 'İleri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Geri'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                    ],
                  );
                },
                steps: _buildSteps(),
              ),
            ),
    );
  }
}