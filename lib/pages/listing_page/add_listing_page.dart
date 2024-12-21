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
  const AddListingPage({Key? key}) : super(key: key);

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  /// Stepper kontrol değişkeni
  int _currentStep = 0;

  /// Yükleniyor durumunu göstermek için
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  /// Kullanıcı girişi kontrolü
  Future<void> _checkUserAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      /// Kullanıcı yoksa login sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      /// Varsa şehirleri yükle
      await _loadCities();
    }
  }

  /// Her step (adım) için ayrı FormKey
  final _formKeyStep0 = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  //----------------------------------------------------------------------------
  // Step 0: İlan Türü
  //----------------------------------------------------------------------------

  ListingType? _selectedListingType; // deposit veya storage

  //----------------------------------------------------------------------------
  // Step 1: Genel Bilgiler
  //----------------------------------------------------------------------------

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final metreKareController = TextEditingController();

  //----------------------------------------------------------------------------
  // Step 2: Konum & Tarih
  //----------------------------------------------------------------------------

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<City> _citiesList = [];
  List<District> _districtsList = [];
  List<Neighborhood> _neighborhoodsList = [];
  City? _selectedCity;
  District? _selectedDistrict;
  Neighborhood? _selectedNeighborhood;

  final LocationService _locationService = LocationService();

  //----------------------------------------------------------------------------
  // Step 3: Detaylar & Fotoğraflar
  //----------------------------------------------------------------------------

  /// Depolama türleri (Sadece Storage için)
  final List<String> _storageTypes = ['İç Mekan', 'Dış Mekan'];
  String? _selectedStorageType;

  /// Depolama özellikleri (Sadece Storage için)
  Map<String, bool> _features = {
    'Güvenlik Kamerası': false,
    'Alarm Sistemi': false,
    '24 Saat Güvenlik': false,
    'Yangın Söndürme Sistemi': false,
  };

  /// Deposit için ek alanlar
  String? _itemType;
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _itemWeightController = TextEditingController();
  bool _requiresTemperatureControl = false;
  bool _requiresDryEnvironment = false;
  bool _insuranceRequired = false;
  List<String> _prohibitedConditions = [];
  bool _ownerPickup = false;
  final _deliveryDetailsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  List<String> _preferredFeatures = [];

  /// Fotoğraflar
  final _picker = ImagePicker();
  List<File> _imageFiles = [];

  //----------------------------------------------------------------------------
  // Şehir, İlçe, Mahalle Veri Yükleme
  //----------------------------------------------------------------------------

  Future<void> _loadCities() async {
    try {
      setState(() => _isLoading = true);
      _citiesList = await _locationService.getCities();
    } catch (e) {
      _showSnackBar('Şehirler yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    try {
      setState(() => _isLoading = true);
      _districtsList = await _locationService.getDistricts(cityId);
    } catch (e) {
      _showSnackBar('İlçeler yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNeighborhoods(String cityId, String districtId) async {
    try {
      setState(() => _isLoading = true);
      _neighborhoodsList =
          await _locationService.getNeighborhoods(cityId, districtId);
    } catch (e) {
      _showSnackBar('Mahalleler yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //----------------------------------------------------------------------------
  // Tarih Seçimi (BottomSheet + CalendarDatePicker)
  //----------------------------------------------------------------------------

  Future<void> _selectDate({required bool isStartDate}) async {
    DateTime initialDate = DateTime.now();
    if (isStartDate && _startDate != null) {
      initialDate = _startDate!;
    } else if (!isStartDate && _endDate != null) {
      initialDate = _endDate!;
    }

    final DateTime? pickedDate = await showModalBottomSheet<DateTime?>(
      context: context,
      builder: (BuildContext context) {
        DateTime tempDate = initialDate;
        return Container(
          padding: const EdgeInsets.only(top: 16.0),
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Text(
                isStartDate ? 'Başlangıç Tarihi' : 'Bitiş Tarihi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Divider(),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: initialDate,
                  firstDate: DateTime.now(), // Bugünden öncesi kapalı
                  lastDate: DateTime(2100),
                  onDateChanged: (value) => tempDate = value,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, tempDate),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Tarihi Seç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );

    if (pickedDate != null) {
      // Mantık: Bitiş tarihi, başlangıç tarihinden önce olamaz
      if (isStartDate) {
        setState(() {
          _startDate = pickedDate;
          startDateController.text = _dateFormat.format(_startDate!);

          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            // 1 gün sonrasına ayarla
            _endDate = _startDate!.add(const Duration(days: 1));
            endDateController.text = _dateFormat.format(_endDate!);
          }
        });
      } else {
        if (_startDate != null && pickedDate.isBefore(_startDate!)) {
          final nextDay = _startDate!.add(const Duration(days: 1));
          setState(() {
            _endDate = nextDay;
            endDateController.text = _dateFormat.format(nextDay);
          });
          _showSnackBar(
              'Bitiş tarihi başlangıç tarihinden önce olamaz.\n1 gün sonrasına ayarlandı.');
        } else {
          setState(() {
            _endDate = pickedDate;
            endDateController.text = _dateFormat.format(_endDate!);
          });
        }
      }
    }
  }

  //----------------------------------------------------------------------------
  // Fotoğraf Seçme ve Kaldırma
  //----------------------------------------------------------------------------

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
      _showSnackBar('Fotoğraf seçme hatası: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index >= 0 && index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      }
    });
  }

  //----------------------------------------------------------------------------
  // SnackBar
  //----------------------------------------------------------------------------

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  //----------------------------------------------------------------------------
  // Firebase'e Fotoğraf Yükleme
  //----------------------------------------------------------------------------

  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    for (var image in _imageFiles) {
      final fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('listing_images')
          .child(fileName);
      final snapshot = await ref.putFile(image);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }

  //----------------------------------------------------------------------------
  // İlan Ekleme
  //----------------------------------------------------------------------------

  Future<void> _addListing() async {
    if (!_validateAllSteps()) return; // Tüm step’leri doğrula

    // Fotoğraf kontrolü
    if (_imageFiles.isEmpty) {
      _showSnackBar('Lütfen en az bir fotoğraf seçin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış.');
      }

      // Fotoğrafları yükle
      List<String> imageUrls = await _uploadImages();

      // Listing modelini oluştur
      final newListing = Listing(
        id: '',
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
        city: _selectedCity?.sehirAdi,
        district: _selectedDistrict?.ilceAdi,
        neighborhood: _selectedNeighborhood?.mahalleAdi,
        storageType: _selectedStorageType,
        features: _selectedListingType == ListingType.storage ? _features : {},
        startDate: _startDate,
        endDate: _endDate,
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

      // Firestore’a ekle
      final docRef = await FirebaseFirestore.instance
          .collection('listings')
          .add(newListing.toMap());

      await docRef.update({'id': docRef.id});

      _showSnackBar('İlan başarıyla eklendi!');

      // Form sıfırla
      _resetForm();

      // Eklenen ilan detayına pushReplacement
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailPage(listing: newListing.copyWith(id: docRef.id)),
      ),
      );
    } catch (e) {
      _showSnackBar('Hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //----------------------------------------------------------------------------
  // Formları Sıfırlama
  //----------------------------------------------------------------------------

  void _resetForm() {
    _currentStep = 0;
    _formKeyStep0.currentState?.reset();
    _formKeyStep1.currentState?.reset();
    _formKeyStep2.currentState?.reset();
    _formKeyStep3.currentState?.reset();

    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    metreKareController.clear();
    startDateController.clear();
    endDateController.clear();
    _startDate = null;
    _endDate = null;

    _imageFiles.clear();
    _selectedCity = null;
    _selectedDistrict = null;
    _selectedNeighborhood = null;
    _selectedListingType = null;
    _selectedStorageType = null;
    _features.updateAll((key, value) => false);

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

  //----------------------------------------------------------------------------
  // Adım Adım Formlar (Stepper)
  //----------------------------------------------------------------------------

  List<Step> get _steps => [
        Step(
          title: const Text('Tür'),
          state: _stepState(0),
          isActive: _currentStep == 0,
          content: Form(
            key: _formKeyStep0,
            child: Column(
              children: [
                DropdownButtonFormField<ListingType>(
                  value: _selectedListingType,
                  decoration: _inputDecoration(
                      labelText: 'İlan Türü', icon: Icons.category_outlined),
                  items: ListingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == ListingType.deposit
                            ? 'Eşyanı Depolamak' // deposit
                            : 'Depolama',      // storage
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedListingType = val;
                      if (_selectedListingType == ListingType.deposit) {
                        // deposit ise depolama özelliklerini sıfırla
                        _features.updateAll((key, value) => false);
                      }
                    });
                  },
                  validator: (val) => val == null ? 'Seçim yapın' : null,
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Genel'),
          state: _stepState(1),
          isActive: _currentStep == 1,
          content: Form(
            key: _formKeyStep1,
            child: Column(
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: _inputDecoration(
                      labelText: 'İlan Başlığı', icon: Icons.title_outlined),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                      labelText: 'Açıklama',
                      icon: Icons.description_outlined),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      labelText: 'Fiyat (₺)', icon: Icons.attach_money_outlined),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Boş bırakılamaz.';
                    }
                    if (double.tryParse(val) == null) {
                      return 'Geçerli bir sayı girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_selectedListingType == ListingType.storage)
                  TextFormField(
                    controller: metreKareController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        labelText: 'Metre Kare',
                        icon: Icons.square_foot_outlined),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Boş bırakılamaz.';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Geçerli bir sayı girin.';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Konum'),
          state: _stepState(2),
          isActive: _currentStep == 2,
          content: Form(
            key: _formKeyStep2,
            child: Column(
              children: [
                // Şehir
                DropdownButtonFormField<City>(
                  value: _selectedCity,
                  decoration: _inputDecoration(
                      labelText: 'Şehir',
                      icon: Icons.location_city_outlined),
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
                const SizedBox(height: 10),
                // İlçe
                DropdownButtonFormField<District>(
                  value: _selectedDistrict,
                  decoration: _inputDecoration(
                      labelText: 'İlçe', icon: Icons.map_outlined),
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
                      await _loadNeighborhoods(_selectedCity!.id, val.id);
                    }
                  },
                  validator: (val) => val == null ? 'Seçim yapın' : null,
                ),
                const SizedBox(height: 10),
                // Mahalle
                DropdownButtonFormField<Neighborhood>(
                  value: _selectedNeighborhood,
                  decoration: _inputDecoration(
                      labelText: 'Mahalle', icon: Icons.location_on_outlined),
                  items: _neighborhoodsList.map((n) {
                    return DropdownMenuItem(
                      value: n,
                      child: Text(n.mahalleAdi),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tarih Seçimi',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                // Başlangıç Tarihi
                TextFormField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: _inputDecoration(
                    labelText: 'Başlangıç Tarihi',
                    icon: Icons.calendar_today_outlined,
                    suffix: Icons.arrow_drop_down,
                  ),
                  onTap: () => _selectDate(isStartDate: true),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Tarih seçilmedi'
                      : null,
                ),
                const SizedBox(height: 10),
                // Bitiş Tarihi
                TextFormField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: _inputDecoration(
                    labelText: 'Bitiş Tarihi',
                    icon: Icons.calendar_month_outlined,
                    suffix: Icons.arrow_drop_down,
                  ),
                  onTap: () => _selectDate(isStartDate: false),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Tarih seçilmedi';
                    }
                    if (_startDate != null && _endDate != null) {
                      if (_endDate!.isBefore(_startDate!)) {
                        return 'Bitiş, başlangıçtan önce olamaz.';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Detay'),
          state: _stepState(3),
          isActive: _currentStep == 3,
          content: Form(
            key: _formKeyStep3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Storage özelse
                  if (_selectedListingType == ListingType.storage) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Depolama Türü',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    _buildStorageTypeDropdown(),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Özellikler',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    _buildStorageFeatures(),
                  ],
                  // Deposit özelse
                  if (_selectedListingType == ListingType.deposit) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Eşya Bilgileri',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    _buildItemTypeField(),
                    const SizedBox(height: 8),
                    _buildDimensionsFields(),
                    const SizedBox(height: 8),
                    _buildItemWeightField(),
                    const SizedBox(height: 8),
                    _buildDepositSwitches(),
                    const SizedBox(height: 8),
                    _buildProhibitedConditionsField(),
                    const SizedBox(height: 8),
                    _buildOwnerPickupSwitch(),
                    const SizedBox(height: 8),
                    _buildDeliveryDetailsField(),
                    const SizedBox(height: 8),
                    _buildAdditionalNotesField(),
                    const SizedBox(height: 8),
                    _buildPreferredFeaturesField(),
                  ],
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Fotoğraflar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  _buildImagesPicker(),
                ],
              ),
            ),
          ),
        ),
      ];

  StepState _stepState(int index) {
    if (_currentStep == index) {
      return StepState.editing;
    } else if (_currentStep > index) {
      return StepState.complete;
    }
    return StepState.indexed;
  }

  void _onStepContinue() {
    switch (_currentStep) {
      case 0:
        if (_formKeyStep0.currentState!.validate()) {
          setState(() => _currentStep++);
        }
        break;
      case 1:
        if (_formKeyStep1.currentState!.validate()) {
          setState(() => _currentStep++);
        }
        break;
      case 2:
        if (_formKeyStep2.currentState!.validate()) {
          if (_startDate == null) {
            _showSnackBar('Başlangıç tarihi seçilmeli.');
            return;
          }
          if (_endDate == null) {
            _showSnackBar('Bitiş tarihi seçilmeli.');
            return;
          }
          if (_endDate!.isBefore(_startDate!)) {
            _showSnackBar('Bitiş tarihi, başlangıçtan önce olamaz.');
            return;
          }
          setState(() => _currentStep++);
        }
        break;
      case 3:
        if (_formKeyStep3.currentState!.validate()) {
          _addListing();
        }
        break;
    }
  }

  void _onStepCancel() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  bool _validateAllSteps() {
    if (!_formKeyStep0.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return false;
    }
    if (!_formKeyStep1.currentState!.validate()) {
      setState(() => _currentStep = 1);
      return false;
    }
    if (!_formKeyStep2.currentState!.validate()) {
      setState(() => _currentStep = 2);
      return false;
    }
    if (!_formKeyStep3.currentState!.validate()) {
      setState(() => _currentStep = 3);
      return false;
    }
    return true;
  }

  //----------------------------------------------------------------------------
  // Scaffold
  //----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ekle'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              steps: _steps,
              type: StepperType.horizontal,
              physics: const ClampingScrollPhysics(), // Tüm cihaz boyutları
              controlsBuilder: (context, details) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _onStepCancel,
                        child: const Text('Geri'),
                      ),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1
                            ? 'İlanı Kaydet'
                            : 'Devam',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  // Ortak Input Decoration
  //----------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    IconData? suffix,
    String? helper,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helper,
      prefixIcon: Icon(icon),
      suffixIcon: suffix != null ? Icon(suffix) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  //----------------------------------------------------------------------------
  // Depolama Türü (Storage)
  //----------------------------------------------------------------------------

  Widget _buildStorageTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStorageType,
      decoration: _inputDecoration(
        labelText: 'Depolama Türü',
        icon: Icons.storage_outlined,
      ),
      items: _storageTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedStorageType = val);
      },
      validator: (val) => val == null ? 'Seçim yapın' : null,
    );
  }

  //----------------------------------------------------------------------------
  // Özellikler (Storage)
  //----------------------------------------------------------------------------

  Widget _buildStorageFeatures() {
    return Column(
      children: _features.keys.map((key) {
        return CheckboxListTile(
          title: Text(key),
          value: _features[key],
          onChanged: (val) => setState(() => _features[key] = val ?? false),
        );
      }).toList(),
    );
  }

  //----------------------------------------------------------------------------
  // Eşya Türü (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildItemTypeField() {
    return TextFormField(
      decoration: _inputDecoration(labelText: 'Eşya Türü', icon: Icons.category),
      onChanged: (val) {
        setState(() {
          _itemType = val.trim().isEmpty ? null : val.trim();
        });
      },
    );
  }

  //----------------------------------------------------------------------------
  // Boyut Alanları (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildDimensionsFields() {
    return Row(
      children: [
        Expanded(
          child: _buildDimensionField(_lengthController, 'Uzunluk (m)'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDimensionField(_widthController, 'Genişlik (m)'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDimensionField(_heightController, 'Yükseklik (m)'),
        ),
      ],
    );
  }

  Widget _buildDimensionField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(labelText: label, icon: Icons.straighten),
    );
  }

  //----------------------------------------------------------------------------
  // Eşya Ağırlığı (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildItemWeightField() {
    return TextFormField(
      controller: _itemWeightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(
          labelText: 'Eşya Ağırlığı (kg)', icon: Icons.scale_outlined),
      validator: (val) {
        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
          return 'Geçerli bir sayı girin.';
        }
        return null;
      },
    );
  }

  //----------------------------------------------------------------------------
  // Deposit Switch'ler
  //----------------------------------------------------------------------------

  Widget _buildDepositSwitches() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Sıcaklık Kontrolü Gerekli'),
          value: _requiresTemperatureControl,
          onChanged: (val) => setState(() => _requiresTemperatureControl = val),
        ),
        SwitchListTile(
          title: const Text('Kuru Ortam Gerekli'),
          value: _requiresDryEnvironment,
          onChanged: (val) => setState(() => _requiresDryEnvironment = val),
        ),
        SwitchListTile(
          title: const Text('Sigorta Gerekli'),
          value: _insuranceRequired,
          onChanged: (val) => setState(() => _insuranceRequired = val),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // Yasaklı Şartlar (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildProhibitedConditionsField() {
    return TextFormField(
      decoration: _inputDecoration(
        labelText: 'Yasaklı Şartlar',
        icon: Icons.block_outlined,
        helper: 'Örnek: Açık ateş, Zehirli maddeler (virgülle ayrılmış)',
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
    );
  }

  //----------------------------------------------------------------------------
  // Eşyayı Sahibi mi Alacak? (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildOwnerPickupSwitch() {
    return SwitchListTile(
      title: const Text('Eşyayı Sahibi Alacak mı?'),
      value: _ownerPickup,
      onChanged: (val) => setState(() => _ownerPickup = val),
    );
  }

  //----------------------------------------------------------------------------
  // Teslimat Detayları (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildDeliveryDetailsField() {
    return TextFormField(
      controller: _deliveryDetailsController,
      decoration: _inputDecoration(
          labelText: 'Teslimat Detayları',
          icon: Icons.delivery_dining_outlined),
    );
  }

  //----------------------------------------------------------------------------
  // Ek Notlar (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildAdditionalNotesField() {
    return TextFormField(
      controller: _additionalNotesController,
      maxLines: 3,
      decoration: _inputDecoration(
          labelText: 'Ek Notlar', icon: Icons.note_alt_outlined),
    );
  }

  //----------------------------------------------------------------------------
  // Tercih Edilen Özellikler (Deposit)
  //----------------------------------------------------------------------------

  Widget _buildPreferredFeaturesField() {
    return TextFormField(
      decoration: _inputDecoration(
        labelText: 'Tercih Edilen Özellikler',
        icon: Icons.favorite_border_outlined,
        helper: 'Örnek: Güvenli, Kapalı Alan (virgülle ayrılmış)',
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
    );
  }

  //----------------------------------------------------------------------------
  // Fotoğraf Yükleme Alanı
  //----------------------------------------------------------------------------

  Widget _buildImagesPicker() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: _imageFiles.isEmpty
          ? InkWell(
              onTap: _pickImages,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 6),
                  Text('Fotoğraf Yükle', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              itemCount: _imageFiles.length,
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Farklı ekran boyutlarında otomatik uyumlu
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
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
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  
}