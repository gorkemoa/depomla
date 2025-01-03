// lib/pages/auth_page/settings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../models/neighborhood_model.dart';
import '../../models/user_model.dart';
import '../../notifications_page.dart';
import '../../services/location_service.dart';
import '../info_change_page/change_password_page.dart';
import '../info_change_page/change_email_page.dart'; // Yeni eklenen import

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? userModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userModel = UserModel.fromDocument(doc);
          });
        }
      } catch (e) {
        print('Hata: $e');
        _showSnackBar('Kullanıcı bilgileri alınırken hata oluştu.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showSnackBar('Kullanıcı giriş yapmamış.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  void _navigateToChangeEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangeEmailPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userModel == null
              ? const Center(child: Text('Kullanıcı bilgileri alınamadı.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      EditProfilePage(userModel: userModel!),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.notifications, color: Colors.blueAccent),
                        title: const Text('Bildirimler'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.blueAccent),
                        title: const Text('Şifre Değiştir'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _navigateToChangePassword,
                      ),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.blueAccent),
                        title: const Text('E-posta Değiştir'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _navigateToChangeEmail,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final UserModel userModel;

  const EditProfilePage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  String? _displayName;
  String? _email;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  List<City> _cities = [];
  List<District> _districts = [];
  List<Neighborhood> _neighborhoods = [];
  bool _isUpdating = false;
  bool isLoading = true; // Durum değişkeni eklendi

  // Konum verilerini önbelleğe almak için haritalar
  final Map<String, String> _citiesMap = {};
  final Map<String, String> _districtsMap = {};
  final Map<String, String> _neighborhoodsMap = {};

  @override
  void initState() {
    super.initState();
    _displayName = widget.userModel.displayName;
    _email = widget.userModel.email;
    _selectedCity = widget.userModel.city == 'Seçilmemiş' ? null : widget.userModel.city;
    _selectedDistrict = widget.userModel.district == 'Seçilmemiş' ? null : widget.userModel.district;
    _selectedNeighborhood =
        widget.userModel.neighborhood == 'Seçilmemiş' ? null : widget.userModel.neighborhood;

    _loadAllLocations().then((_) {
      _fetchUserLocationNames();
    });
  }

  /// Tüm şehir, ilçe ve mahalle verilerini önbelleğe alır
  Future<void> _loadAllLocations() async {
    try {
      // Şehirleri getir
      final cities = await _locationService.getCities();
      setState(() {
        _cities = cities;
        for (var city in cities) {
          _citiesMap[city.id] = city.sehirAdi;
        }
      });

      // Kullanıcının seçtiği şehre ait ilçeleri getir
      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        final districts = await _locationService.getDistricts(_selectedCity!);
        setState(() {
          _districts = districts;
          _districtsMap.clear();
          for (var district in districts) {
            _districtsMap[district.id] = district.ilceAdi;
          }
        });
      }

      // Kullanıcının seçtiği ilçeye ait mahalleleri getir
      if (_selectedCity != null &&
          _selectedCity!.isNotEmpty &&
          _selectedDistrict != null &&
          _selectedDistrict!.isNotEmpty) {
        final neighborhoods =
            await _locationService.getNeighborhoods(_selectedCity!, _selectedDistrict!);
        setState(() {
          _neighborhoods = neighborhoods;
          _neighborhoodsMap.clear();
          for (var neighborhood in neighborhoods) {
            _neighborhoodsMap[neighborhood.id] = neighborhood.mahalleAdi;
          }
        });
       
      }
    } catch (e) {
      print('Konum verileri yüklenirken hata: $e');
      _showSnackBar('Konum verileri yüklenirken hata oluştu.');
    }
  }

  /// Kullanıcının konum isimlerini önbellekten alır
  Future<void> _fetchUserLocationNames() async {
    try {
      // Bu aşamada, eğer seçili şehir veya ilçe varsa, onların varlığını kontrol edin
      if (_selectedCity != null && !_citiesMap.containsKey(_selectedCity)) {
        print('Selected city $_selectedCity not found in cities map.');
        _selectedCity = null;
      }
      if (_selectedDistrict != null && !_districtsMap.containsKey(_selectedDistrict)) {
        print('Selected district $_selectedDistrict not found in districts map.');
        _selectedDistrict = null;
      }
      if (_selectedNeighborhood != null && !_neighborhoodsMap.containsKey(_selectedNeighborhood)) {
        print('Selected neighborhood $_selectedNeighborhood not found in neighborhoods map.');
        _selectedNeighborhood = null;
      }
    } catch (e) {
      print("Hata: $e");
      // Hata durumunda kullanıcıya uygun bir mesaj gösterebilirsiniz.
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Belirli bir koleksiyondan ID'ye karşılık gelen ismi önbellekten alır
  String _getNameFromCache(String collection, String? id) {
    if (id == null || id.isEmpty) return "Seçilmemiş";
    switch (collection) {
      case 'cities':
        return _citiesMap[id] ?? "Şehir belirtilmemiş";
      case 'districts':
        return _districtsMap[id] ?? "İlçe belirtilmemiş";
      case 'neighborhoods':
        return _neighborhoodsMap[id] ?? "Mahalle belirtilmemiş";
      default:
        return "Seçilmemiş";
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    if (cityId.isEmpty) return;
    try {
      final districts = await _locationService.getDistricts(cityId);
      setState(() {
        _districts = districts;
        _districtsMap.clear();
        for (var district in districts) {
          _districtsMap[district.id] = district.ilceAdi;
        }
      });
      print('Loaded districts for city $cityId: ${_districtsMap.keys.join(', ')}');
    } catch (e) {
      print('İlçeler yüklenirken hata: $e');
      _showSnackBar('İlçeler yüklenirken hata oluştu.');
    }
  }

  Future<void> _loadNeighborhoods(String cityId, String districtId) async {
    if (districtId.isEmpty) return;
    try {
      final neighborhoods = await _locationService.getNeighborhoods(cityId, districtId);
      setState(() {
        _neighborhoods = neighborhoods;
        _neighborhoodsMap.clear();
        for (var neighborhood in neighborhoods) {
          _neighborhoodsMap[neighborhood.id] = neighborhood.mahalleAdi;
        }
      });
      print('Loaded neighborhoods for district $districtId: ${_neighborhoodsMap.keys.join(', ')}');
    } catch (e) {
      print('Mahalleler yüklenirken hata: $e');
      _showSnackBar('Mahalleler yüklenirken hata oluştu.');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isUpdating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _displayName,
        // 'email': _email, // E-posta güncellemesini ayrı sayfadan yapacağımız için bu satırı kaldırdık veya yorum satırı yaptık
        'city': _selectedCity ?? 'Seçilmemiş',
        'district': _selectedDistrict ?? 'Seçilmemiş',
        'neighborhood': _selectedNeighborhood ?? 'Seçilmemiş',
      });

      _showSnackBar('Profil başarıyla güncellendi.');
    } catch (e) {
      print('Güncelleme hatası: $e');
      _showSnackBar('Profil güncellenirken hata oluştu.');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String>? validator,
  }) {
    // Geçerli değerin items listesinde olup olmadığını kontrol edin
    bool isValidValue = value == null || items.any((item) {
      if (item is City) {
        return item.id == value;
      } else if (item is District) {
        return item.id == value;
      } else if (item is Neighborhood) {
        return item.id == value;
      }
      return false;
    });

    return DropdownButtonFormField<String>(
      value: isValidValue ? value : null, // Geçerli değilse null yap
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Lütfen $label seçiniz',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text("Seçilmemiş"),
        ),
        ...items.map<DropdownMenuItem<String>>((item) {
          String id;
          String name;
          if (item is City) {
            id = item.id;
            name = item.sehirAdi;
          } else if (item is District) {
            id = item.id;
            name = item.ilceAdi;
          } else if (item is Neighborhood) {
            id = item.id;
            name = item.mahalleAdi;
          } else {
            id = '';
            name = 'Bilinmeyen';
          }
          return DropdownMenuItem<String>(
            value: id.isNotEmpty ? id : null, // Boş id'leri null olarak ayarlayın
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ],
      onChanged: (selectedValue) {
        onChanged(selectedValue);
      },
      validator: validator,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      dropdownColor: Colors.white,
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutuna göre responsive padding
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Stack(
      children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? screenWidth * 0.2 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Adınız
                      TextFormField(
                        initialValue: _displayName,
                        decoration: InputDecoration(
                          labelText: 'Adınız',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ad boş olamaz.' : null,
                        onSaved: (value) => _displayName = value,
                      ),
                      const SizedBox(height: 16),
                      // E-posta (Okunabilir veya read-only olarak ayarlanabilir)
                      TextFormField(
                        initialValue: _email,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _navigateToChangeEmail,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true, // E-posta alanını okunabilir hale getirdik
                        // Validator ve onSaved fonksiyonlarını kaldırdık veya yorum satırı yaptık
                      ),
                      const SizedBox(height: 16),
                      // Şehir Seçiniz
                      _buildDropdown(
                        label: 'Şehir Seçiniz',
                        value: _selectedCity,
                        items: _cities,
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                            _selectedDistrict = null;
                            _selectedNeighborhood = null;
                            _districts = [];
                            _neighborhoods = [];
                          });
                          if (value != null) {
                            _loadDistricts(value);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Şehir seçimi zorunludur.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // İlçe Seçiniz
                      _buildDropdown(
                        label: 'İlçe Seçiniz',
                        value: _selectedDistrict,
                        items: _districts,
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                            _selectedNeighborhood = null;
                            _neighborhoods = [];
                          });
                          if (value != null && _selectedCity != null) {
                            _loadNeighborhoods(_selectedCity!, value);
                          }
                        },
                        validator: (value) {
                          if (_selectedCity == null) {
                            return null;
                          }
                          if (value == null) {
                            return 'İlçe seçimi zorunludur.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Mahalle Seçiniz
                      _buildDropdown(
                        label: 'Mahalle Seçiniz',
                        value: _selectedNeighborhood,
                        items: _neighborhoods,
                        onChanged: (value) {
                          setState(() {
                            _selectedNeighborhood = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedDistrict == null) {
                            return null;
                          }
                          if (value == null) {
                            return 'Mahalle seçimi zorunludur.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Kaydet Butonu
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  void _navigateToChangeEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangeEmailPage()),
    );
  }
}