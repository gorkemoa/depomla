// lib/pages/listing_page/filter_modal.dart

import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final String? selectedItemType;
  final String? selectedStorageType;

  final Function(
    double?,
    double?,
    String?,
    String?,
  ) onApply;

  const FilterPage({
    Key? key,
    this.minPrice,
    this.maxPrice,
    this.selectedItemType,
    this.selectedStorageType,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  double minPrice = 0;
  double maxPrice = 5000;
  RangeValues priceRange = const RangeValues(0, 5000);

  String? selectedItemType;
  String? selectedStorageType;

  List<String> itemTypes = ['Mobilya', 'Elektronik', 'Kıyafet', 'Kitap'];
  List<String> storageTypes = ['Kapalı Depo', 'Açık Depo', 'Soğuk Hava Deposu'];

  @override
  void initState() {
    super.initState();
    minPrice = widget.minPrice ?? 0;
    maxPrice = widget.maxPrice ?? 5000;
    priceRange = RangeValues(minPrice, maxPrice);

    selectedItemType = widget.selectedItemType;
    selectedStorageType = widget.selectedStorageType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtreler', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          TextButton(
            onPressed: () {
              // Temizle
              setState(() {
                priceRange = const RangeValues(0, 5000);
                selectedItemType = null;
                selectedStorageType = null;
              });
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fiyat Aralığı
          const Text('Fiyat Aralığı', style: TextStyle(fontWeight: FontWeight.bold)),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: 5000,
            divisions: 100,
            labels: RangeLabels('${priceRange.start.round()} ₺', '${priceRange.end.round()} ₺'),
            onChanged: (values) {
              setState(() {
                priceRange = values;
              });
            },
          ),
          const SizedBox(height: 16),

          // Eşya Türü
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(labelText: 'Eşya Türü', border: OutlineInputBorder()),
            value: selectedItemType,
            onChanged: (value) {
              setState(() {
                selectedItemType = value;
              });
            },
            items: [null, ...itemTypes].map((type) {
              return DropdownMenuItem<String?>(
                value: type,
                child: Text(type ?? 'Tümü'),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Depolama Türü
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(labelText: 'Depolama Türü', border: OutlineInputBorder()),
            value: selectedStorageType,
            onChanged: (value) {
              setState(() {
                selectedStorageType = value;
              });
            },
            items: [null, ...storageTypes].map((type) {
              return DropdownMenuItem<String?>(
                value: type,
                child: Text(type ?? 'Tümü'),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              widget.onApply(
                priceRange.start,
                priceRange.end,
                selectedItemType,
                selectedStorageType,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Filtreleri Uygula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}