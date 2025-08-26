import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/onvif_service.dart';

class PTZControl extends StatefulWidget {
  final DeviceModel device;
  final OnvifService onvifService;

  const PTZControl({
    Key? key,
    required this.device,
    required this.onvifService,
  }) : super(key: key);

  @override
  _PTZControlState createState() => _PTZControlState();
}

class _PTZControlState extends State<PTZControl> {
  double _panSpeed = 0.5;
  double _tiltSpeed = 0.5;
  double _zoomSpeed = 0.5;

  void _movePTZ(double pan, double tilt, double zoom) async {
    try {
      // TODO: Get profile token from camera view
      const profileToken = 'Profile_1';

      await widget.onvifService.movePTZ(
        profileToken: profileToken,
        pan: pan * _panSpeed,
        tilt: tilt * _tiltSpeed,
        zoom: zoom * _zoomSpeed,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi điều khiển PTZ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setPreset(int presetNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã set preset $presetNumber'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'PTZ Control',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Direction Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left
              IconButton(
                onPressed: () => _movePTZ(-1, 0, 0),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),

              // Up
              IconButton(
                onPressed: () => _movePTZ(0, 1, 0),
                icon: const Icon(Icons.arrow_upward),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),

              // Down
              IconButton(
                onPressed: () => _movePTZ(0, -1, 0),
                icon: const Icon(Icons.arrow_downward),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),

              // Right
              IconButton(
                onPressed: () => _movePTZ(1, 0, 0),
                icon: const Icon(Icons.arrow_forward),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Zoom Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _movePTZ(0, 0, -1),
                icon: const Icon(Icons.zoom_out),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _movePTZ(0, 0, 1),
                icon: const Icon(Icons.zoom_in),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Speed Controls
          Column(
            children: [
              Row(
                children: [
                  const Text('Pan Speed: '),
                  Expanded(
                    child: Slider(
                      value: _panSpeed,
                      onChanged: (value) {
                        setState(() {
                          _panSpeed = value;
                        });
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: Colors.blue,
                    ),
                  ),
                  Text('${(_panSpeed * 100).toInt()}%'),
                ],
              ),
              Row(
                children: [
                  const Text('Tilt Speed: '),
                  Expanded(
                    child: Slider(
                      value: _tiltSpeed,
                      onChanged: (value) {
                        setState(() {
                          _tiltSpeed = value;
                        });
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: Colors.blue,
                    ),
                  ),
                  Text('${(_tiltSpeed * 100).toInt()}%'),
                ],
              ),
              Row(
                children: [
                  const Text('Zoom Speed: '),
                  Expanded(
                    child: Slider(
                      value: _zoomSpeed,
                      onChanged: (value) {
                        setState(() {
                          _zoomSpeed = value;
                        });
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: Colors.blue,
                    ),
                  ),
                  Text('${(_zoomSpeed * 100).toInt()}%'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Preset Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _setPreset(1),
                child: const Text('Preset 1'),
              ),
              ElevatedButton(
                onPressed: () => _setPreset(2),
                child: const Text('Preset 2'),
              ),
              ElevatedButton(
                onPressed: () => _setPreset(3),
                child: const Text('Preset 3'),
              ),
              ElevatedButton(
                onPressed: () => _setPreset(4),
                child: const Text('Preset 4'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Home and Stop buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Go to home position
                },
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    const profileToken = 'Profile_1';
                    await widget.onvifService
                        .stopPTZ(profileToken: profileToken);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã dừng PTZ'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi dừng PTZ: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
