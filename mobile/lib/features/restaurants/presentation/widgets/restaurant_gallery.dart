import 'package:flutter/material.dart';

/// The restaurant's photos: swipe through them, the dots show where you are, tap one to see it large.
class RestaurantGallery extends StatefulWidget {
  const RestaurantGallery({required this.photos, super.key});

  static const double _maxHeight = 260;

  final List<Uri> photos;

  @override
  State<RestaurantGallery> createState() => _RestaurantGalleryState();
}

class _RestaurantGalleryState extends State<RestaurantGallery> {
  int _page = 0;

  Widget _image(Uri uri, {BoxFit fit = BoxFit.cover}) => Image.network(
        uri.toString(),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
      );

  Widget _placeholder(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.restaurant, size: 56)),
      );

  void _open(Uri uri) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(maxScale: 5, child: Center(child: _image(uri, fit: BoxFit.contain))),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  key: const Key('closePhoto'),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    // 16:9 on a phone, but capped so wide screens don't push the details off-screen.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: (constraints.maxWidth * 9 / 16).clamp(0, RestaurantGallery._maxHeight).toDouble(),
        child: photos.isEmpty
            ? _placeholder(context)
            : Stack(
                children: [
                  PageView.builder(
                    key: const Key('gallery'),
                    itemCount: photos.length,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) => GestureDetector(
                      key: Key('photo-$index'),
                      onTap: () => _open(photos[index]),
                      child: _image(photos[index]),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < photos.length; i++)
                            Container(
                              key: Key(i == _page ? 'dot-active' : 'dot-$i'),
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _page ? Colors.white : Colors.white54,
                                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black38)],
                              ),
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
