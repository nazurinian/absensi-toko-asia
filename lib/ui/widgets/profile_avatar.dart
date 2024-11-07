import 'package:absensitoko/core/constants/items_list.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? pageName;
  final String? photoURL;
  final String? heroTag;
  final VoidCallback? onEdit;

  const ProfileAvatar(
      {super.key, required this.pageName, required this.photoURL, this.heroTag, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.blue,
      minRadius: 80,
      maxRadius: 100,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Hero(
              tag: heroTag ?? 'none',
              transitionOnUserGestures: true,
              placeholderBuilder: (context, heroSize, child) {
                return Opacity(
                  opacity: 0.5,
                  child: child,
                );
              },
              child: CircleAvatar(
                minRadius: 77,
                maxRadius: 97,
                backgroundColor: Colors.transparent,
                child: CachedNetworkImage(
                  imageUrl: photoURL ?? '',
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(AppImage.blankUser.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  useOldImageOnUrlChange: true,
                ),
              ),
            ),
            if (pageName == 'Profile') ...[
              Positioned(
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, right: 5),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.brush, color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
