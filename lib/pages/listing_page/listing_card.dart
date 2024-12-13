// lib/pages/listing_page/listing_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';
import 'listings_details_page.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({
    Key? key,
    required this.listing
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive font sizes
    double titleFontSize = MediaQuery.of(context).size.width < 350 ? 16 : 18;
    double priceFontSize = MediaQuery.of(context).size.width < 350 ? 14 : 16;
    double infoFontSize = MediaQuery.of(context).size.width < 350 ? 12 : 14;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildImage(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${listing.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: priceFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildLocation(infoFontSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: CachedNetworkImage(
        imageUrl: listing.imageUrl.isNotEmpty ? listing.imageUrl.first : '',
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero, // Geçiş efektini kaldır
        fadeOutDuration: Duration.zero, // Geçiş efektini kaldır
        placeholder: (context, url) => Container(
          height: 140,
          color: Colors.grey.shade300,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 140,
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        ),
      ),
    );
  }

  Widget buildLocation(double infoFontSize) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 14, color: Colors.grey),
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
    );
  }
}