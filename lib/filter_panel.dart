// lib/filter_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterPanel extends StatefulWidget {
  final RangeValues selectedPriceRange;
  final double minPrice;
  final double maxPrice;
  final DateTime? selectedDateFrom;
  final DateTime? selectedDateTo;
  final String searchTerm;
  final Function(RangeValues, DateTime?, DateTime?, String) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterPanel({
    Key? key,
    required this.selectedPriceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.searchTerm,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _FilterPanelState createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late RangeValues _tempPriceRange;
  DateTime? _tempDateFrom;
  DateTime? _tempDateTo;
  late String _tempSearchTerm;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempPriceRange = widget.selectedPriceRange;
    _tempDateFrom = widget.selectedDateFrom;
    _tempDateTo = widget.selectedDateTo;
    _tempSearchTerm = widget.searchTerm;
    _searchController.text = _tempSearchTerm;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    DateTime initialDate = isFrom
        ? (_tempDateFrom ?? DateTime.now())
        : (_tempDateTo ??
            (_tempDateFrom != null
                ? _tempDateFrom!.add(Duration(days: 1))
                : DateTime.now().add(Duration(days: 1))));
    DateTime firstDate =
        isFrom ? DateTime(2000) : (_tempDateFrom ?? DateTime.now());
    DateTime lastDate = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _tempDateFrom = picked;
          if (_tempDateTo != null && _tempDateTo!.isBefore(_tempDateFrom!)) {
            _tempDateTo = null;
          }
        } else {
          _tempDateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Filtreleri Uygula',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF02aee7),
                ),
              ),
              const SizedBox(height: 16),
              // Arama Çubuğu
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İlanlarda Ara...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF02aee7)),
                  suffixIcon: _tempSearchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xFF02aee7)),
                          onPressed: () {
                            setState(() {
                              _tempSearchTerm = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        const BorderSide(color: Color(0xFF02aee7)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _tempSearchTerm = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Fiyat Aralığı
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fiyat Aralığı'),
                  RangeSlider(
                    values: _tempPriceRange,
                    min: widget.minPrice,
                    max: widget.maxPrice,
                    divisions: 100,
                    labels: RangeLabels(
                      '${_tempPriceRange.start.toInt()}₺',
                      '${_tempPriceRange.end.toInt()}₺',
                    ),
                    activeColor: const Color(0xFF02aee7),
                    inactiveColor:
                        const Color(0xFF02aee7).withOpacity(0.3),
                    onChanged: (values) {
                      setState(() {
                        _tempPriceRange = values;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tarih Filtrelemesi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tarih Aralığı'),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectDate(context, true),
                          child: Text(_tempDateFrom == null
                              ? 'Başlangıç Tarihi'
                              : 'Başlangıç: ${DateFormat('dd/MM/yyyy').format(_tempDateFrom!)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _tempDateFrom == null
                              ? null
                              : () => _selectDate(context, false),
                          child: Text(_tempDateTo == null
                              ? 'Bitiş Tarihi'
                              : 'Bitiş: ${DateFormat('dd/MM/yyyy').format(_tempDateTo!)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filtreleri Temizleme ve Uygulama Butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onClearFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Filtreleri Temizle'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(
                        _tempPriceRange,
                        _tempDateFrom,
                        _tempDateTo,
                        _tempSearchTerm,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02aee7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
