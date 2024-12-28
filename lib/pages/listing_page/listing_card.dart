import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';
import 'edit_listing_page.dart';
import 'listings_details_page.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final bool isEditable; // Düzenlenebilir mi kontrolü

  const ListingCard({
    Key? key,
    required this.listing,
    this.isEditable = false, // Varsayılan olarak düzenleme kapalı
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingDetailPage(listing: listing),
              ),
            );
          },
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${listing.price.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${listing.district}, ${listing.city}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isEditable)
          Positioned(
            top: 0,
            right: 3,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: const Text(
                'Düzenle',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Belirgin arka plan rengi
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditListingPage(
                      listingId: listing.id,
                      currentData: listing.toMap(),
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('İlan başarıyla güncellendi.')),
                    );
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: listing.imageUrl.isNotEmpty ? listing.imageUrl.first : '',
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 140,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 140,
        color: Colors.grey.shade200,
        child: const Icon(Icons.error),
      ),
    );
  }
}