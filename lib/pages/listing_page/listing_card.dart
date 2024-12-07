import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';
import 'listings_details_page.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final bool isList;

  const ListingCard({
    Key? key,
    required this.listing,
    this.isList = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran boyutuna göre font boyutlarını ayarlamak için MediaQuery kullanabilirsiniz
    double titleFontSize = MediaQuery.of(context).size.width < 350 ? 16 : 18;
    double priceFontSize = MediaQuery.of(context).size.width < 350 ? 14 : 16;
    double infoFontSize = MediaQuery.of(context).size.width < 350 ? 12 : 14;

    return GestureDetector(
      onTap: () {
        // Detay sayfasına yönlendirme
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: isList
            ? buildListContent(context, titleFontSize, priceFontSize, infoFontSize)
            : buildGridContent(context, titleFontSize, priceFontSize, infoFontSize),
      ),
    );
  }

  Widget buildGridContent(
      BuildContext context, double titleFontSize, double priceFontSize, double infoFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildImage(),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: buildInfo(context, titleFontSize, priceFontSize, infoFontSize),
        ),
      ],
    );
  }

  Widget buildListContent(
      BuildContext context, double titleFontSize, double priceFontSize, double infoFontSize) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          child: buildImage(width: 120, height: 120),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: buildInfo(context, titleFontSize, priceFontSize, infoFontSize),
          ),
        ),
      ],
    );
  }

  Widget buildImage({double width = double.infinity, double height = 150}) {
    return CachedNetworkImage(
      imageUrl: listing.imageUrl.isNotEmpty ? listing.imageUrl.first : '',
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      ),
    );
  }

  Widget buildInfo(
      BuildContext context, double titleFontSize, double priceFontSize, double infoFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İlan Başlığı - Tek Satır
        Text(
          listing.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
          maxLines: 1, // Tek satır
          overflow: TextOverflow.ellipsis, // Taşma durumunda üç nokta
        ),
        const SizedBox(height: 6),
        // Fiyat
        Text(
          '${listing.price.toStringAsFixed(2)} ₺',
          style: TextStyle(
            color: Colors.green,
            fontSize: priceFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Lokasyon Bilgisi (Mahalle hariç)
        if (listing.city != null && listing.district != null)
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${listing.district}, ${listing.city}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: infoFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}