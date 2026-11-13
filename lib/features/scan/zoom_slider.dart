import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A slider over the camera: left = no zoom, right = maximum zoom.
class ZoomSlider extends StatefulWidget {
  const ZoomSlider({super.key, required this.camera});

  final MobileScannerController camera;

  @override
  State<ZoomSlider> createState() => _ZoomSliderState();
}

class _ZoomSliderState extends State<ZoomSlider> {
  double _zoom = 0; // 0..1, the scale mobile_scanner expects

  void _onChanged(double value) {
    setState(() => _zoom = value);
    widget.camera.setZoomScale(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black54,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.zoom_out, color: Colors.white),
          ),
          Expanded(child: Slider(value: _zoom, onChanged: _onChanged)),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.zoom_in, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
