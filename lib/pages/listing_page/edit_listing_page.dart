// lib/pages/listing_page/edit_listing_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/listing_model.dart';
import '../../services/location_service.dart';
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../models/neighborhood_model.dart';
import 'package:carousel_slider/carousel_slider.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> currentData;

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

  // Form alanları
  late String _title;
  late String _description;
  late double _price;
  late ListingType _listingType;
  double? _size;
  String? _cityName;
  String? _districtName;
  String? _neighborhoodName;
  String? _storageType;
  Map<String, bool> _features = {};
  String? _startDate;
  String? _endDate;

  // Yeni alanlar
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

  bool isUpdating = false;

  // Resim URL'leri
  late List<String> _imageUrls;

  // Dropdown verileri
  List<City> _cities = [];
  List<District> _districts = [];
  List<Neighborhood> _neighborhoods = [];

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
    _fetchCities();
  }

  void _initializeFormFields() {
    _title = widget.currentData['title'] ?? '';
    _description = widget.currentData['description'] ?? '';
    _price = (widget.currentData['price'] as num).toDouble();
    _listingType = widget.currentData['listingType'] == 'deposit'
        ? ListingType.deposit
        : ListingType.storage;
    _size = (widget.currentData['size'] as num?)?.toDouble();
    _cityName = widget.currentData['city']?.toString(); // Şehir ismi
    _districtName = widget.currentData['district']?.toString(); // İlçe ismi
    _neighborhoodName = widget.currentData['neighborhood']?.toString(); // Mahalle ismi
    _storageType = widget.currentData['storageType']?.toString();
    _features = widget.currentData['features'] != null
        ? Map<String, bool>.from(widget.currentData['features'] as Map<dynamic, dynamic>)
        : {};
    _startDate = widget.currentData['startDate']?.toString();
    _endDate = widget.currentData['endDate']?.toString();

    // Yeni alanlar
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

  Future<void> _fetchCities() async {
    try {
      List<City> cities = await _locationService.getCities();
      setState(() {
        _cities = cities;
      });

      // Şehir ismi doğrulaması
      if (_cityName != null && !_cities.any((city) => city.sehirAdi.toLowerCase() == _cityName!.toLowerCase())) {
        // Eğer _cityName, şehir isimleriyle eşleşmiyorsa hata fırlat
        throw Exception('Şehir bulunamadı: $_cityName');
      }

      // Eğer şehir ismi doğruysa, ilçeleri çek
      if (_cityName != null) {
        final matchedCity = _cities.firstWhere(
          (city) => city.sehirAdi.toLowerCase() == _cityName!.toLowerCase(),
          orElse: () => throw Exception('Şehir bulunamadı: $_cityName'),
        );
        _fetchDistricts(matchedCity.id);
      }
    } catch (e) {
      print('Şehirler alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şehirler alınırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _fetchDistricts(String cityId) async {
    try {
      List<District> districts = await _locationService.getDistricts(cityId);
      setState(() {
        _districts = districts;
      });

      // İlçe ismi doğrulaması
      if (_districtName != null && !_districts.any((district) => district.ilceAdi.toLowerCase() == _districtName!.toLowerCase())) {
        // Eğer _districtName, ilçe isimleriyle eşleşmiyorsa hata fırlat
        throw Exception('İlçe bulunamadı: $_districtName');
      }

      // Eğer ilçe ismi doğruysa, mahalleleri çek
      if (_districtName != null) {
        final matchedDistrict = _districts.firstWhere(
          (district) => district.ilceAdi.toLowerCase() == _districtName!.toLowerCase(),
          orElse: () => throw Exception('İlçe bulunamadı: $_districtName'),
        );
        _fetchNeighborhoods(cityId, matchedDistrict.id);
      }
    } catch (e) {
      print('İlçeler alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlçeler alınırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _fetchNeighborhoods(String cityId, String districtId) async {
    try {
      List<Neighborhood> neighborhoods = await _locationService.getNeighborhoods(cityId, districtId);
      setState(() {
        _neighborhoods = neighborhoods;
      });

      // Mahalle ismi doğrulaması
      if (_neighborhoodName != null && !_neighborhoods.any((neighborhood) => neighborhood.mahalleAdi.toLowerCase() == _neighborhoodName!.toLowerCase())) {
        // Eğer _neighborhoodName, mahalle isimleriyle eşleşmiyorsa hata fırlat
        throw Exception('Mahalle bulunamadı: $_neighborhoodName');
      }
    } catch (e) {
      print('Mahalleler alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mahalleler alınırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isUpdating = true;
    });

    try {
      final listingRef = FirebaseFirestore.instance.collection('listings').doc(widget.listingId);
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
        'startDate': _startDate,
        'endDate': _endDate,
        // Yeni alanlar
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla güncellendi.')),
      );
      Navigator.pop(context, true); // Başarılı güncelleme durumunda true döndür
    } catch (e) {
      print('İlan güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan güncellenirken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  // Başlık Alanı
  Widget _buildTitleField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextFormField(
          initialValue: _title,
          decoration: const InputDecoration(
            labelText: 'Başlık',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Başlık boş olamaz' : null,
          onSaved: (value) => _title = value!,
        ),
      ),
    );
  }

  // Açıklama Alanı
  Widget _buildDescriptionField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextFormField(
          initialValue: _description,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty ? 'Açıklama boş olamaz' : null,
          onSaved: (value) => _description = value!,
        ),
      ),
    );
  }

  // Fiyat Alanı
  Widget _buildPriceField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextFormField(
          initialValue: _price.toString(),
          decoration: const InputDecoration(
            labelText: 'Fiyat (TL)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Fiyat boş olamaz';
            if (double.tryParse(value) == null) return 'Geçerli bir fiyat giriniz';
            return null;
          },
          onSaved: (value) => _price = double.parse(value!),
        ),
      ),
    );
  }

  // İlan Türü Alanı
  Widget _buildListingTypeField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
              setState(() {
                _listingType = newValue;
              });
            }
          },
          validator: (value) => value == null ? 'İlan türü seçiniz' : null,
          onSaved: (value) => _listingType = value!,
        ),
      ),
    );
  }

  // Büyüklük Alanı
  Widget _buildSizeField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextFormField(
          initialValue: _size?.toString(),
          decoration: const InputDecoration(
            labelText: 'Büyüklük (m²)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.square_foot),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty && double.tryParse(value) == null)
              return 'Geçerli bir büyüklük giriniz';
            return null;
          },
          onSaved: (value) => _size = value != null && value.isNotEmpty ? double.parse(value) : null,
        ),
      ),
    );
  }

  // Şehir, İlçe, Mahalle Alanları
  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Şehir Dropdown
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: _cityName,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _cities.map((City city) {
                return DropdownMenuItem<String>(
                  value: city.sehirAdi, // Şehir ismi olarak ayarlandı
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
                      (city) => city.sehirAdi.toLowerCase() == newValue.toLowerCase(),
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
              validator: (value) => value == null || value.isEmpty ? 'Şehir seçiniz' : null,
              onSaved: (value) => _cityName = value!,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // İlçe Dropdown
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: _districtName,
              decoration: const InputDecoration(
                labelText: 'İlçe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _districts.map((District district) {
                return DropdownMenuItem<String>(
                  value: district.ilceAdi, // İlçe ismi olarak ayarlandı
                  child: Text(district.ilceAdi),
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
                      (district) => district.ilceAdi.toLowerCase() == newValue.toLowerCase(),
                      orElse: () => throw Exception('İlçe bulunamadı: $newValue'),
                    );
                    _fetchNeighborhoods(_cities.firstWhere((city) => city.sehirAdi == _cityName!).id, matchedDistrict.id);
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              validator: (value) => value == null || value.isEmpty ? 'İlçe seçiniz' : null,
              onSaved: (value) => _districtName = value!,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mahalle Dropdown
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: _neighborhoodName,
              decoration: const InputDecoration(
                labelText: 'Mahalle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _neighborhoods.map((Neighborhood neighborhood) {
                return DropdownMenuItem<String>(
                  value: neighborhood.mahalleAdi, // Mahalle ismi olarak ayarlandı
                  child: Text(neighborhood.mahalleAdi),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _neighborhoodName = newValue;
                });
              },
              validator: (value) => value == null || value.isEmpty ? 'Mahalle seçiniz' : null,
              onSaved: (value) => _neighborhoodName = value!,
            ),
          ),
        ),
      ],
    );
  }

  // Depolama Türü Alanı
  Widget _buildStorageTypeField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextFormField(
          initialValue: _storageType,
          decoration: const InputDecoration(
            labelText: 'Depolama Türü',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.storage),
          ),
          onSaved: (value) => _storageType = value,
        ),
      ),
    );
  }

  // Özellikler Bölümü
  Widget _buildFeaturesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Özellikler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _buildFeatureChip('securityCamera', 'Güvenlik Kamerası'),
                _buildFeatureChip('alarmSystem', 'Alarm Sistemi'),
                _buildFeatureChip('twentyFourSevenSecurity', '24/7 Güvenlik'),
                // Diğer özellikler eklenebilir
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Özellik Chip'i Yardımcı Metodu
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

  // Tarih Alanları
  Widget _buildDateFields() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              initialValue: _startDate,
              decoration: const InputDecoration(
                labelText: 'Başlangıç Tarihi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              onSaved: (value) => _startDate = value,
              // İsteğe bağlı olarak Date Picker ekleyebilirsiniz
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              initialValue: _endDate,
              decoration: const InputDecoration(
                labelText: 'Bitiş Tarihi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              onSaved: (value) => _endDate = value,
              // İsteğe bağlı olarak Date Picker ekleyebilirsiniz
            ),
          ),
        ),
      ],
    );
  }

  // Ek Alanlar (Yeni Alanlar)
  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eşya Türü
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
        ),
        const SizedBox(height: 16),

        // Eşya Boyutları
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eşya Boyutları (metre cinsinden)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _itemDimensions?['length']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Uzunluk',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null)
                            return 'Geçerli bir uzunluk giriniz';
                          return null;
                        },
                        onSaved: (value) {
                          if (_itemDimensions == null) _itemDimensions = {};
                          _itemDimensions!['length'] =
                              value != null && value.isNotEmpty ? double.parse(value) : 0.0;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _itemDimensions?['width']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Genişlik',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null)
                            return 'Geçerli bir genişlik giriniz';
                          return null;
                        },
                        onSaved: (value) {
                          if (_itemDimensions == null) _itemDimensions = {};
                          _itemDimensions!['width'] =
                              value != null && value.isNotEmpty ? double.parse(value) : 0.0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _itemDimensions?['height']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Yükseklik',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null)
                      return 'Geçerli bir yükseklik giriniz';
                    return null;
                  },
                  onSaved: (value) {
                    if (_itemDimensions == null) _itemDimensions = {};
                    _itemDimensions!['height'] =
                        value != null && value.isNotEmpty ? double.parse(value) : 0.0;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Eşya Ağırlığı
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              initialValue: _itemWeight?.toString(),
              decoration: const InputDecoration(
                labelText: 'Eşya Ağırlığı (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null)
                  return 'Geçerli bir ağırlık giriniz';
                return null;
              },
              onSaved: (value) => _itemWeight =
                  value != null && value.isNotEmpty ? double.parse(value) : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sıcaklık Kontrolü Gerekiyor
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text('Sıcaklık Kontrolü Gerekiyor'),
            value: _requiresTemperatureControl ?? false,
            onChanged: (bool value) {
              setState(() {
                _requiresTemperatureControl = value;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Kuru Ortam Gerekiyor
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text('Kuru Ortam Gerekiyor'),
            value: _requiresDryEnvironment ?? false,
            onChanged: (bool value) {
              setState(() {
                _requiresDryEnvironment = value;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Sigorta Gerekiyor
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text('Sigorta Gerekiyor'),
            value: _insuranceRequired ?? false,
            onChanged: (bool value) {
              setState(() {
                _insuranceRequired = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Yasaklı Şartlar
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              initialValue: _prohibitedConditions != null
                  ? _prohibitedConditions!.join(', ')
                  : '',
              decoration: const InputDecoration(
                labelText: 'Yasaklı Şartlar (virgül ile ayrılmış)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.rule),
              ),
              onSaved: (value) => _prohibitedConditions = value != null && value.isNotEmpty
                  ? value.split(',').map((e) => e.trim()).toList()
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sahip Teslim Alacak mı?
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text('Sahip Teslim Alacak mı?'),
            value: _ownerPickup ?? false,
            onChanged: (bool value) {
              setState(() {
                _ownerPickup = value;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Teslimat Detayları
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
        ),
        const SizedBox(height: 16),

        // Ek Notlar
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
        ),
        const SizedBox(height: 16),

        // Tercih Edilen Özellikler
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                    // Diğer tercih edilen özellikler eklenebilir
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tercih Edilen Özellik Chip'i Yardımcı Metodu
  Widget _buildPreferredFeatureChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _preferredFeatures?.contains(label) ?? false,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _preferredFeatures = _preferredFeatures ?? [];
            _preferredFeatures!.add(label);
          } else {
            _preferredFeatures?.remove(label);
          }
        });
      },
    );
  }

  // Güncelle Butonu
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

  // Resim Gösterme Bölümü
  Widget _buildImagesSection() {
    return _imageUrls.isNotEmpty
        ? CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              autoPlay: false,
            ),
            items: _imageUrls.map((url) {
              return Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  );
                },
              );
            }).toList(),
          )
        : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Resimleri Gösterme
                _buildImagesSection(),
                const SizedBox(height: 16),

                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildPriceField(),
                const SizedBox(height: 16),
                _buildListingTypeField(),
                const SizedBox(height: 16),
                _buildSizeField(),
                const SizedBox(height: 16),
                _buildLocationFields(),
                const SizedBox(height: 16),
                _buildStorageTypeField(),
                const SizedBox(height: 16),
                _buildFeaturesSection(),
                const SizedBox(height: 16),
                _buildDateFields(),
                const SizedBox(height: 16),
                _buildAdditionalFields(),
                const SizedBox(height: 24),
                _buildUpdateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}