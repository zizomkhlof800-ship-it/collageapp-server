import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/api.dart';

class OfflineImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  const OfflineImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
  });

  @override
  State<OfflineImage> createState() => _OfflineImageState();
}

class _OfflineImageState extends State<OfflineImage> {
  static final Map<String, Uint8List> _memoryCache = {};

  @override
  Widget build(BuildContext context) {
    final resolved =
        widget.url.startsWith('http') || widget.url.startsWith('data:')
        ? widget.url
        : '$baseUrl${widget.url}';

    if (resolved.startsWith('data:image/')) {
      final bytes = _memoryCache.putIfAbsent(
        resolved,
        () => base64Decode(resolved.split(',').last),
      );
      return Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        gaplessPlayback: true,
      );
    }

    return Image.network(
      resolved,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
    );
  }
}
