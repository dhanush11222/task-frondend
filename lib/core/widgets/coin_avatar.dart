import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, required this.url, required this.symbol, this.size = 40});

  final String? url;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        symbol.isEmpty ? '?' : symbol[0].toUpperCase(),
        style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
