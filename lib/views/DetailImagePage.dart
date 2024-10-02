import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:absensitoko/themes/fonts/Fonts.dart';

class DetailProfilePicturePage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  const DetailProfilePicturePage({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Foto Profil'),
        backgroundColor: Colors.black,
        // titleTextStyle: FontTheme.size22Appbar(color: Colors.white),
        iconTheme: const IconThemeData(
          color: Colors.white, // Ubah warna ikon menjadi putih
        ),
      ),
      body: Hero(
        tag: 'profile-picture',
        transitionOnUserGestures: true,
        flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
          return ScaleTransition(
            scale: animation,
            child: toContext.widget,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return Container(
                width: size,
                height: size,
                color: Colors.blue,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
