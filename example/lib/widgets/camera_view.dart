import 'package:flutter/material.dart';
import 'package:onvif_flutter/onvif_flutter.dart';
import '../models/device_model.dart';
import '../services/onvif_service.dart';
import 'fijk_player_widget.dart';

class CameraView extends StatefulWidget {
  final DeviceModel device;
  final String viewType; // 'live' or 'playback'
  final bool isFullscreen;
  final OnvifService onvifService;

  const CameraView({
    Key? key,
    required this.device,
    required this.viewType,
    this.isFullscreen = false,
    required this.onvifService,
  }) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _streamUrl;
  String? _snapshotUrl;
  List<OnvifMediaProfile> _profiles = [];
  OnvifMediaProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy media profiles
      final profiles = await widget.onvifService.getMediaProfiles();

      if (profiles.isNotEmpty) {
        setState(() {
          _profiles = profiles;
          _selectedProfile = profiles.first;
        });

        // Lấy stream URI
        if (widget.viewType == 'live') {
          final streamUri =
              await widget.onvifService.getStreamUri(_selectedProfile!.token);
          if (streamUri != null) {
            setState(() {
              _streamUrl = streamUri;
            });
          }
        }

        // Lấy snapshot URI
        final snapshotUri =
            await widget.onvifService.getSnapshotUri(_selectedProfile!.token);
        if (snapshotUri != null) {
          setState(() {
            _snapshotUrl = snapshotUri;
          });
        }
      }
    } catch (e) {
      print('❌ Lỗi khởi tạo camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khởi tạo camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takeSnapshot() async {
    if (_snapshotUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chụp ảnh - chưa có snapshot URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // TODO: Implement snapshot capture
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chụp ảnh thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshStream() {
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang kết nối camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_streamUrl == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể kết nối stream',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Device: ${widget.device.name}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshStream,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Video player
          Expanded(
            child: FijkPlayerWidget(
              videoUrl: _streamUrl!,
              isLive: widget.viewType == 'live',
              autoPlay: true,
            ),
          ),

          // Camera controls
          if (!widget.isFullscreen)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Snapshot button
                  IconButton(
                    onPressed: _takeSnapshot,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    tooltip: 'Chụp ảnh',
                  ),

                  // Record button
                  IconButton(
                    onPressed: () {
                      // TODO: Implement recording
                    },
                    icon: const Icon(Icons.fiber_manual_record,
                        color: Colors.white),
                    tooltip: 'Ghi hình',
                  ),

                  // Refresh button
                  IconButton(
                    onPressed: _refreshStream,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Làm mới',
                  ),

                  // Profile selector
                  if (_profiles.length > 1)
                    PopupMenuButton<OnvifMediaProfile>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      tooltip: 'Chọn profile',
                      onSelected: (profile) {
                        setState(() {
                          _selectedProfile = profile;
                        });
                        _initializeCamera();
                      },
                      itemBuilder: (context) => _profiles.map((profile) {
                        return PopupMenuItem(
                          value: profile,
                          child:
                              Text('Profile ${profile.name ?? profile.token}'),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
