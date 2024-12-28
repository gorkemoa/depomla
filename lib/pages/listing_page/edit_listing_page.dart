// lib/pages/listing_page/edit_listing_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/listing_model.dart';
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../models/neighborhood_model.dart';
import '../../services/location_service.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;                // Düzenlenecek ilanın ID’si
  final Map<String, dynamic> currentData; // Mevcut ilan verileri

  const EditListingPage({
    Key? key,
    required this.listingId,
    required this.currentData,
  }) : super(key: key);

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  // Temel Form Alanları
  late String _title;          
  late String _description;    
  late double _price;          
  late ListingType _listingType; 
  double? _size;               
  String? _cityName;           
  String? _districtName;       
  String? _neighborhoodName;   

  // Storage’e özgü
  String? _storageType;        
  Map<String, bool> _features = {}; 
  final List<String> _storageTypes = ['İç Mekan', 'Dış Mekan'];

  // Tarihler
  DateTime? _startDate;
  DateTime? _endDate;

  // Deposit'e özgü
  String? _itemType;           
  Map<String, double>? _itemDimensions; 
  double? _itemWeight;         
  bool? _requiresTemperatureControl; 
  bool? _requiresDryEnvironment;     
  bool? _insuranceRequired;          
  List<String>? _prohibitedConditions; 
  bool? _ownerPickup;            
  String? _deliveryDetails;      
  String? _additionalNotes;      
  List<String>? _preferredFeatures; 

  // Yükleniyor mu?
  bool isUpdating = false;

  // Resim URL'leri ve dosyalar
  List<String> _imageUrls = [];
  List<File> _newImageFiles = [];

  // Şehir / İlçe / Mahalle için veriler
  List<City> _cities = [];
  List<District> _districts = [];
  List<Neighborhood> _neighborhoods = [];

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
    _fetchCities();
  }

  /// Form alanlarını doldurmak için mevcut verileri çek
  void _initializeFormFields() {
    _title = widget.currentData['title'] ?? '';
    _description = widget.currentData['description'] ?? '';
    _price = (widget.currentData['price'] as num).toDouble();

    _listingType = (widget.currentData['listingType'] == 'deposit')
        ? ListingType.deposit
        : ListingType.storage;

    _size = (widget.currentData['size'] as num?)?.toDouble();
    _cityName = widget.currentData['city']?.toString();
    _districtName = widget.currentData['district']?.toString();
    _neighborhoodName = widget.currentData['neighborhood']?.toString();

    _storageType = widget.currentData['storageType']?.toString();
    _features = widget.currentData['features'] != null
        ? Map<String, bool>.from(widget.currentData['features'] as Map<dynamic, dynamic>)
        : {};

    // Tarih alanlarını doğru tipte dönüştürme
    if (widget.currentData['startDate'] is Timestamp) {
      _startDate = (widget.currentData['startDate'] as Timestamp).toDate();
    } else if (widget.currentData['startDate'] is DateTime) {
      _startDate = widget.currentData['startDate'] as DateTime;
    } else if (widget.currentData['startDate'] is String) {
      _startDate = DateTime.tryParse(widget.currentData['startDate']);
    }

    if (widget.currentData['endDate'] is Timestamp) {
      _endDate = (widget.currentData['endDate'] as Timestamp).toDate();
    } else if (widget.currentData['endDate'] is DateTime) {
      _endDate = widget.currentData['endDate'] as DateTime;
    } else if (widget.currentData['endDate'] is String) {
      _endDate = DateTime.tryParse(widget.currentData['endDate']);
    }

    // Deposit / Storage ek alanlar
    _itemType = widget.currentData['itemType']?.toString();
    _itemDimensions = widget.currentData['itemDimensions'] != null
        ? Map<String, double>.from(widget.currentData['itemDimensions'] as Map<dynamic, dynamic>)
        : null;
    _itemWeight = (widget.currentData['itemWeight'] as num?)?.toDouble();
    _requiresTemperatureControl = widget.currentData['requiresTemperatureControl'] as bool?;
    _requiresDryEnvironment = widget.currentData['requiresDryEnvironment'] as bool?;
    _insuranceRequired = widget.currentData['insuranceRequired'] as bool?;

    _prohibitedConditions = widget.currentData['prohibitedConditions'] != null
        ? List<String>.from(widget.currentData['prohibitedConditions'] as List<dynamic>)
        : null;

    _ownerPickup = widget.currentData['ownerPickup'] as bool?;
    _deliveryDetails = widget.currentData['deliveryDetails']?.toString();
    _additionalNotes = widget.currentData['additionalNotes']?.toString();
    _preferredFeatures = widget.currentData['preferredFeatures'] != null
        ? List<String>.from(widget.currentData['preferredFeatures'] as List<dynamic>)
        : null;

    // Resim URL'lerini al
    _imageUrls = widget.currentData['imageUrl'] is List
        ? List<String>.from(widget.currentData['imageUrl'] as List<dynamic>)
        : [widget.currentData['imageUrl']?.toString() ?? ''];
  }

  //----------------------------------------------------------------------------
  // 2) Şehir / İlçe / Mahalle Verilerini Çekme
  //----------------------------------------------------------------------------

  Future<void> _fetchCities() async {
    try {
      _cities = await _locationService.getCities();
      setState(() {});

      if (_cityName != null) {
        final matchedCity = _cities.firstWhere(
          (city) => city.sehirAdi.toLowerCase() == _cityName!.toLowerCase(),
          orElse: () => throw Exception('Şehir bulunamadı: $_cityName'),
        );
        _fetchDistricts(matchedCity.id);
      }
    } catch (e) {
      print('Şehirler alınırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şehirler alınırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _fetchDistricts(String cityId) async {
    try {
      _districts = await _locationService.getDistricts(cityId);
      setState(() {});

      if (_districtName != null) {
        final matchedDistrict = _districts.firstWhere(
          (district) => district.ilceAdi.toLowerCase() == _districtName!.toLowerCase(),
          orElse: () => throw Exception('İlçe bulunamadı: $_districtName'),
        );
        _fetchNeighborhoods(cityId, matchedDistrict.id);
      }
    } catch (e) {
      print('İlçeler alınırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlçeler alınırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _fetchNeighborhoods(String cityId, String districtId) async {
    try {
      _neighborhoods = await _locationService.getNeighborhoods(cityId, districtId);
      setState(() {});
    } catch (e) {
      print('Mahalleler alınırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mahalleler alınırken hata oluştu: $e')),
      );
    }
  }

  //----------------------------------------------------------------------------
  // 3) İlanı Güncelleme
  //----------------------------------------------------------------------------

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isUpdating = true);

    try {
      // Yeni eklenen resimler varsa bunları yükle
      List<String> newImageUrls = [];
      for (File image in _newImageFiles) {
        // Firebase Storage'a yükleme işlemi burada gerçekleştirilmelidir
        // Örneğin:
        // String fileName = Uuid().v4();
        // Reference ref = FirebaseStorage.instance.ref().child('listing_images').child(fileName);
        // UploadTask uploadTask = ref.putFile(image);
        // TaskSnapshot snapshot = await uploadTask;
        // String downloadUrl = await snapshot.ref.getDownloadURL();
        // newImageUrls.add(downloadUrl);
        // Bu örnekte placeholder olarak direkt ekliyoruz
        newImageUrls.add(image.path); // Gerçek uygulamada yukarıdaki kodu kullanın
      }

      // Eski resimleri koruyup, yeni resimleri eklemek için
      List<String> updatedImageUrls = List.from(_imageUrls)..addAll(newImageUrls);

      final listingRef = FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId);

      await listingRef.update({
        'title': _title,
        'description': _description,
        'price': _price,
        'listingType': _listingType == ListingType.deposit ? 'deposit' : 'storage',
        'size': _size,
        'city': _cityName,
        'district': _districtName,
        'neighborhood': _neighborhoodName,
        'storageType': _storageType,
        'features': _features,
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        // Deposit / Storage ek alanlar
        'itemType': _itemType,
        'itemDimensions': _itemDimensions,
        'itemWeight': _itemWeight,
        'requiresTemperatureControl': _requiresTemperatureControl,
        'requiresDryEnvironment': _requiresDryEnvironment,
        'insuranceRequired': _insuranceRequired,
        'prohibitedConditions': _prohibitedConditions,
        'ownerPickup': _ownerPickup,
        'deliveryDetails': _deliveryDetails,
        'additionalNotes': _additionalNotes,
        'preferredFeatures': _preferredFeatures,
        'imageUrl': updatedImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla güncellendi.')),
      );
      Navigator.pop(context, true); // Düzenleme sonrası geri dön
    } catch (e) {
      print('İlan güncellenirken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan güncellenirken bir hata oluştu: $e')),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  //----------------------------------------------------------------------------
  // 4) İlan Silme Butonu
  //----------------------------------------------------------------------------

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isUpdating = true);

    try {
      final listingRef = FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId);

      await listingRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla silindi.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('İlan silinirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan silinirken bir hata oluştu: $e')),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  //----------------------------------------------------------------------------
  // 5) Form Alanları
  //----------------------------------------------------------------------------

  /// Başlık (title)
  Widget _buildTitleField() {
    return _buildCardField(
      child: TextFormField(
        initialValue: _title,
        decoration: const InputDecoration(
          labelText: 'Başlık',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.title),
        ),
        validator: (value) => (value == null || value.isEmpty)
            ? 'Başlık boş olamaz'
            : null,
        onSaved: (value) => _title = value!.trim(),
      ),
    );
  }

  /// Açıklama (description)
  Widget _buildDescriptionField() {
    return _buildCardField(
      child: TextFormField(
        initialValue: _description,
        decoration: const InputDecoration(
          labelText: 'Açıklama',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
        ),
        maxLines: 3,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Açıklama boş olamaz' : null,
        onSaved: (value) => _description = value!.trim(),
      ),
    );
  }

  /// Fiyat (price)
  Widget _buildPriceField() {
    return _buildCardField(
      child: TextFormField(
        initialValue: _price.toString(),
        decoration: const InputDecoration(
          labelText: 'Fiyat (TL)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.attach_money),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Fiyat boş olamaz';
          if (double.tryParse(value) == null) {
            return 'Geçerli bir fiyat giriniz';
          }
          return null;
        },
        onSaved: (value) => _price = double.parse(value!),
      ),
    );
  }

  /// İlan Türü (listingType)
  Widget _buildListingTypeField() {
    return _buildCardField(
      child: DropdownButtonFormField<ListingType>(
        value: _listingType,
        decoration: const InputDecoration(
          labelText: 'İlan Türü',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category),
        ),
        items: ListingType.values.map((ListingType type) {
          return DropdownMenuItem<ListingType>(
            value: type,
            child: Text(type == ListingType.deposit ? 'Depozito' : 'Depolama'),
          );
        }).toList(),
        onChanged: (ListingType? newValue) {
          if (newValue != null) {
            setState(() => _listingType = newValue);
          }
        },
        validator: (value) => value == null ? 'İlan türü seçiniz' : null,
        onSaved: (value) => _listingType = value!,
      ),
    );
  }

  /// Depolama için Büyüklük (size)
  Widget _buildSizeField() {
    return _buildCardField(
      child: TextFormField(
        initialValue: _size?.toString(),
        decoration: const InputDecoration(
          labelText: 'Büyüklük (m²)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.square_foot),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (_listingType == ListingType.storage && (value == null || value.isEmpty)) {
            return 'Büyüklük boş olamaz';
          }
          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
            return 'Geçerli bir büyüklük giriniz';
          }
          return null;
        },
        onSaved: (value) => _size =
            (value != null && value.isNotEmpty) ? double.parse(value) : null,
      ),
    );
  }

  /// Depolama Türü için Dropdown (İç Mekan / Dış Mekan)
  Widget _buildStorageTypeFieldDropdown() {
    return _buildCardField(
      child: DropdownButtonFormField<String>(
        value: _storageType,
        decoration: const InputDecoration(
          labelText: 'Depolama Türü',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.storage),
        ),
        items: _storageTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _storageType = newValue;
          });
        },
        validator: (value) {
          if (_listingType == ListingType.storage && (value == null || value.isEmpty)) {
            return 'Depolama türü seçiniz';
          }
          return null;
        },
        onSaved: (value) => _storageType = value!,
      ),
    );
  }

  /// Şehir / İlçe / Mahalle
  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Şehir
        _buildCardField(
          child: DropdownButtonFormField<String>(
            value: _cityName,
            decoration: const InputDecoration(
              labelText: 'Şehir',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            items: _cities.map((City city) {
              return DropdownMenuItem<String>(
                value: city.sehirAdi,
                child: Text(city.sehirAdi),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _cityName) {
                setState(() {
                  _cityName = newValue;
                  _districtName = null;
                  _neighborhoodName = null;
                  _districts = [];
                  _neighborhoods = [];
                });
                try {
                  final matchedCity = _cities.firstWhere(
                    (c) => c.sehirAdi.toLowerCase() == newValue.toLowerCase(),
                    orElse: () => throw Exception('Şehir bulunamadı: $newValue'),
                  );
                  _fetchDistricts(matchedCity.id);
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Şehir seçiniz' : null,
            onSaved: (value) => _cityName = value!,
          ),
        ),
        const SizedBox(height: 16),

        // İlçe
        _buildCardField(
          child: DropdownButtonFormField<String>(
            value: _districtName,
            decoration: const InputDecoration(
              labelText: 'İlçe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            items: _districts.map((District d) {
              return DropdownMenuItem<String>(
                value: d.ilceAdi,
                child: Text(d.ilceAdi),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _districtName) {
                setState(() {
                  _districtName = newValue;
                  _neighborhoodName = null;
                  _neighborhoods = [];
                });
                try {
                  final matchedDistrict = _districts.firstWhere(
                    (dis) => dis.ilceAdi.toLowerCase() == newValue.toLowerCase(),
                    orElse: () => throw Exception('İlçe bulunamadı: $newValue'),
                  );
                  _fetchNeighborhoods(
                    _cities.firstWhere((c) => c.sehirAdi == _cityName!).id,
                    matchedDistrict.id,
                  );
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            validator: (value) =>
                (value == null || value.isEmpty) ? 'İlçe seçiniz' : null,
            onSaved: (value) => _districtName = value!,
          ),
        ),
        const SizedBox(height: 16),

        // Mahalle
_buildCardField(
  child: DropdownButtonFormField<String>(
    value: _neighborhoodName,
    decoration: const InputDecoration(
      labelText: 'Mahalle',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.location_city),
    ),
    items: _neighborhoods.map((Neighborhood n) {
      return DropdownMenuItem<String>(
        value: n.mahalleAdi,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7, // Genişlik kısıtlaması
          child: RichText(
            overflow: TextOverflow.visible,
            text: TextSpan(
              text: n.mahalleAdi,
              style: const TextStyle(
                fontSize: 14, // Menüdeki font boyutu
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }).toList(),
    onChanged: (String? newValue) {
      setState(() {
        _neighborhoodName = newValue;
      });
    },
    selectedItemBuilder: (BuildContext context) {
      return _neighborhoods.map((Neighborhood n) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6, // Genişlik kısıtlaması
          child: RichText(
            overflow: TextOverflow.visible,
            text: TextSpan(
              text: _neighborhoodName == n.mahalleAdi && _neighborhoodName != null
                  ? _neighborhoodName!
                  : n.mahalleAdi,
              style: const TextStyle(
                fontSize: 12, // Seçim alanındaki font boyutu
                color: Colors.black,
              ),
            ),
          ),
        );
      }).toList();
    },
    validator: (value) =>
        (value == null || value.isEmpty) ? 'Mahalle seçiniz' : null,
    onSaved: (value) => _neighborhoodName = value!,
  ),
),
      ],
    );
  }

  /// Depolama Özellikleri (Storage)
  Widget _buildFeaturesSection() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Depolama Özellikleri',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _buildFeatureChip('securityCamera', 'Güvenlik Kamerası'),
              _buildFeatureChip('alarmSystem', 'Alarm Sistemi'),
              _buildFeatureChip('twentyFourSevenSecurity', '24/7 Güvenlik'),
            ],
          ),
        ],
      ),
    );
  }

  // Yardımcı metod: Tek bir özellik Chip’i
  Widget _buildFeatureChip(String key, String label) {
    return FilterChip(
      label: Text(label),
      selected: _features[key] ?? false,
      onSelected: (bool selected) {
        setState(() {
          _features[key] = selected;
        });
      },
    );
  }

  /// Tarih Alanları (startDate, endDate)
  Widget _buildDateFields() {
    return Column(
      children: [
        _buildCardField(
          child: GestureDetector(
            onTap: () => _selectDate(isStartDate: true),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Başlangıç Tarihi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _startDate != null
                      ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                      : '',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Başlangıç tarihi seçiniz' : null,
                onSaved: (value) {
                  // _startDate zaten seçilmiş durumda
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCardField(
          child: GestureDetector(
            onTap: () => _selectDate(isStartDate: false),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Bitiş Tarihi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                controller: TextEditingController(
                  text: _endDate != null
                      ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
                      : '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitiş tarihi seçiniz';
                  }
                  if (_startDate != null && _endDate != null) {
                    if (_endDate!.isBefore(_startDate!)) {
                      return 'Bitiş tarihi, başlangıçtan önce olamaz.';
                    }
                  }
                  return null;
                },
                onSaved: (value) {
                  // _endDate zaten seçilmiş durumda
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tarih Seçme İşlemi
  Future<void> _selectDate({required bool isStartDate}) async {
    DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          if (_startDate != null && pickedDate.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bitiş tarihi, başlangıç tarihinden önce olamaz.'),
              ),
            );
            return;
          }
          _endDate = pickedDate;
        }
      });
    }
  }

  /// Deposit’e özgü ek alanlar
  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eşya Türü
        _buildCardField(
          child: TextFormField(
            initialValue: _itemType,
            decoration: const InputDecoration(
              labelText: 'Eşya Türü',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            onSaved: (value) => _itemType = value,
          ),
        ),
        const SizedBox(height: 16),

        // Eşya Boyutları
        _buildItemDimensionsFields(),
        const SizedBox(height: 16),

        // Eşya Ağırlığı
        _buildCardField(
          child: TextFormField(
            initialValue: _itemWeight?.toString(),
            decoration: const InputDecoration(
              labelText: 'Eşya Ağırlığı (kg)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSaved: (value) => _itemWeight =
                (value != null && value.isNotEmpty) ? double.parse(value) : null,
          ),
        ),
        const SizedBox(height: 16),

        // Sıcaklık Kontrolü, Kuru Ortam, Sigorta
        _buildCardField(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sıcaklık Kontrolü Gerekiyor'),
                value: _requiresTemperatureControl ?? false,
                onChanged: (bool value) {
                  setState(() => _requiresTemperatureControl = value);
                },
              ),
              SwitchListTile(
                title: const Text('Kuru Ortam Gerekiyor'),
                value: _requiresDryEnvironment ?? false,
                onChanged: (bool value) {
                  setState(() => _requiresDryEnvironment = value);
                },
              ),
              SwitchListTile(
                title: const Text('Sigorta Gerekiyor'),
                value: _insuranceRequired ?? false,
                onChanged: (bool value) {
                  setState(() => _insuranceRequired = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Yasaklı Şartlar
        _buildCardField(
          child: TextFormField(
            initialValue: _prohibitedConditions != null
                ? _prohibitedConditions!.join(', ')
                : '',
            decoration: const InputDecoration(
              labelText: 'Yasaklı Şartlar (virgül ile ayrılmış)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.rule),
            ),
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _prohibitedConditions = value.split(',').map((e) => e.trim()).toList();
              } else {
                _prohibitedConditions = null;
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Sahip Teslim Alacak mı?
        _buildCardField(
          child: SwitchListTile(
            title: const Text('Sahip Teslim Alacak mı?'),
            value: _ownerPickup ?? false,
            onChanged: (bool value) {
              setState(() => _ownerPickup = value);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Teslimat Detayları
        _buildCardField(
          child: TextFormField(
            initialValue: _deliveryDetails,
            decoration: const InputDecoration(
              labelText: 'Teslimat Detayları',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.delivery_dining),
            ),
            onSaved: (value) => _deliveryDetails = value,
          ),
        ),
        const SizedBox(height: 16),

        // Ek Notlar
        _buildCardField(
          child: TextFormField(
            initialValue: _additionalNotes,
            decoration: const InputDecoration(
              labelText: 'Ek Notlar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            onSaved: (value) => _additionalNotes = value,
          ),
        ),
        const SizedBox(height: 16),

        // Tercih Edilen Özellikler
        _buildPreferredFeaturesSection(),
      ],
    );
  }

  /// Eşya Boyutları
  Widget _buildItemDimensionsFields() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Eşya Boyutları (metre cinsinden)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Uzunluk
              Expanded(
                child: TextFormField(
                  initialValue: _itemDimensions?['length']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Uzunluk',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) {
                    if (_itemDimensions == null) _itemDimensions = {};
                    _itemDimensions!['length'] =
                        (value != null && value.isNotEmpty) ? double.parse(value) : 0.0;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Genişlik
              Expanded(
                child: TextFormField(
                  initialValue: _itemDimensions?['width']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Genişlik',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) {
                    if (_itemDimensions == null) _itemDimensions = {};
                    _itemDimensions!['width'] =
                        (value != null && value.isNotEmpty) ? double.parse(value) : 0.0;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Yükseklik
              Expanded(
                child: TextFormField(
                  initialValue: _itemDimensions?['height']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Yükseklik',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (value) {
                    if (_itemDimensions == null) _itemDimensions = {};
                    _itemDimensions!['height'] =
                        (value != null && value.isNotEmpty) ? double.parse(value) : 0.0;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tercih Edilen Özellikler
  Widget _buildPreferredFeaturesSection() {
    return _buildCardField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tercih Edilen Özellikler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _buildPreferredFeatureChip('Güvenli'),
              _buildPreferredFeatureChip('Kapalı Alan'),
              _buildPreferredFeatureChip('Hızlı Erişim'),
            ],
          ),
        ],
      ),
    );
  }

  /// Tek bir tercih edilen özellik Chip’i
  Widget _buildPreferredFeatureChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _preferredFeatures?.contains(label) ?? false,
      onSelected: (bool selected) {
        setState(() {
          _preferredFeatures ??= [];
          if (selected) {
            _preferredFeatures!.add(label);
          } else {
            _preferredFeatures!.remove(label);
          }
        });
      },
    );
  }

  //----------------------------------------------------------------------------
  // 6) Resim Galerisi + Resim Düzenleme
  //----------------------------------------------------------------------------

  /// İlan Resimlerini gösterir ve düzenleme imkanı sunar
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imageUrls.isNotEmpty
            ? CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  autoPlay: false,
                ),
                items: _imageUrls.map((url) {
                  return Builder(
                    builder: (context) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey);
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: GestureDetector(
                              onTap: () => _removeImage(url),
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
                  );
                }).toList(),
              )
            : const Center(
                child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
        const SizedBox(height: 16),
        // Yeni resim ekleme butonu
        ElevatedButton.icon(
          onPressed: _pickNewImages,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Yeni Resim Ekle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Yeni eklenen resimleri göster
        _newImageFiles.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni Eklenen Resimler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _newImageFiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _newImageFiles[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
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
                ],
              )
            : Container(),
      ],
    );
  }

  /// Yeni resim seçme işlemi
  Future<void> _pickNewImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      print('Yeni resim seçme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni resim seçme hatası: $e')),
      );
    }
  }

  /// Eski resimleri silme işlemi
  void _removeImage(String url) {
    setState(() {
      _imageUrls.remove(url);
    });
  }

  /// Yeni eklenen resimleri silme işlemi
  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  //----------------------------------------------------------------------------
  // 7) Güncelle ve Sil Butonları
  //----------------------------------------------------------------------------

  /// Güncelle Butonu
  Widget _buildUpdateButton() {
    return ElevatedButton.icon(
      onPressed: isUpdating ? null : _updateListing,
      icon: isUpdating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.save),
      label: Text(isUpdating ? 'Güncelleniyor...' : 'Güncelle'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  /// Silme Butonu
  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: isUpdating ? null : _deleteListing,
      icon: isUpdating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.delete),
      label: Text(isUpdating ? 'Siliniyor...' : 'İlanı Sil'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 8) Yardımcı Kart Sarmalayıcı (UI)
  //----------------------------------------------------------------------------

  Widget _buildCardField({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 9) build() Metodu
  //----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Resimler Carousel
                  _buildImagesSection(),
                  const SizedBox(height: 16),

                  // Temel Alanlar
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildPriceField(),
                  const SizedBox(height: 16),
                  _buildListingTypeField(),
                  const SizedBox(height: 16),

                  // Sadece storage türü ise 'size' (m²) ve 'storageType' göster
                  if (_listingType == ListingType.storage) ...[
                    _buildSizeField(),
                    const SizedBox(height: 16),
                    _buildStorageTypeFieldDropdown(),
                    const SizedBox(height: 16),
                  ],

                  // Şehir / İlçe / Mahalle
                  _buildLocationFields(),
                  const SizedBox(height: 16),

                  // Storage’e özgü alanlar
                  if (_listingType == ListingType.storage) ...[
                    _buildFeaturesSection(),
                    const SizedBox(height: 16),
                  ],

                  // Tarih alanları
                  _buildDateFields(),
                  const SizedBox(height: 16),

                  // Deposit’e özgü alanlar
                  if (_listingType == ListingType.deposit) ...[
                    _buildAdditionalFields(),
                    const SizedBox(height: 16),
                  ],

                  // Güncelle ve Sil Butonları
                  _buildUpdateButton(),
                  const SizedBox(height: 8),
                  _buildDeleteButton(),
                ],
              ),
            ),
          ),
          if (isUpdating)
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
}