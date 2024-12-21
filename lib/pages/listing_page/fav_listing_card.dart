// lib/pages/listing_page/fav_listing_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../services/favorite_service.dart';

class FavListingCard extends StatefulWidget {
  final Listing listing;
  final VoidCallback onTap;

  const FavListingCard({
    Key? key,
    required this.listing,
    required this.onTap,
  }) : super(key: key);

  @override
  _FavListingCardState createState() => _FavListingCardState();
}

class _FavListingCardState extends State<FavListingCard> {
  final FavoriteService _favoriteService = FavoriteService();
  bool isFavorite = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    bool favoriteStatus = await _favoriteService.isFavorite(widget.listing.id);
    setState(() {
      isFavorite = favoriteStatus;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (isFavorite) {
        await _favoriteService.removeFavorite(widget.listing.id);
      } else {
        await _favoriteService.addFavorite(widget.listing.id);
      }
      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      print('Favori işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi sırasında bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, // Kartın tamamına tıklama işlevselliği
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel kısmı
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: widget.listing.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.listing.imageUrl.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                      errorWidget: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                      },
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    )
                  : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
            // Başlık ve açıklama kısmı
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.listing.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Fiyat bilgisi ve favori butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.listing.price} TL',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      IconButton(
                        icon: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                        onPressed: isLoading ? null : _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}