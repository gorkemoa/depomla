import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;

  const FullScreenImagePage({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Hero(
          tag: 'listingImage_${imageUrl.hashCode}',
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
     
    );
  }
}