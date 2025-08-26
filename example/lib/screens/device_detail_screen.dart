import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/onvif_service.dart';
import '../widgets/camera_view.dart';
import '../widgets/ptz_control.dart';
import '../widgets/device_info_panel.dart';
import '../widgets/user_management_panel.dart';
import 'device_settings_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailScreen({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  _DeviceDetailScreenState createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFullscreen = false;
  String _currentView = 'live'; // 'live', 'playback'
  late OnvifService _onvifService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _onvifService = OnvifService();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isConnected = false;
    });

    final success = await _onvifService.connectToDevice(widget.device);

    if (mounted) {
      setState(() {
        _isConnected = success;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối với thiết bị'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _onvifService.disconnect();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _switchView(String view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Fullscreen camera view
            CameraView(
              device: widget.device,
              viewType: _currentView,
              isFullscreen: true,
              onvifService: _onvifService,
            ),

            // Fullscreen controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View toggle buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _switchView('live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentView == 'live'
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor:
                                _currentView == 'live' ? Colors.white : null,
                          ),
                          child: const Text('Live'),
                        ),
                        ElevatedButton(
                          onPressed: () => _switchView('playback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentView == 'playback'
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: _currentView == 'playback'
                                ? Colors.white
                                : null,
                          ),
                          child: const Text('Playback'),
                        ),
                      ],
                    ),
                  ),

                  // Exit fullscreen button
                  IconButton(
                    onPressed: _toggleFullscreen,
                    icon:
                        const Icon(Icons.fullscreen_exit, color: Colors.white),
                  ),
                ],
              ),
            ),

            // PTZ controls
            Positioned(
              bottom: 16,
              right: 16,
              child: PTZControl(
                device: widget.device,
                onvifService: _onvifService,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          // Connection status
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isConnected ? 'Online' : 'Offline',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          // Fullscreen button
          IconButton(
            onPressed: _toggleFullscreen,
            icon: const Icon(Icons.fullscreen),
          ),

          // Settings button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DeviceSettingsScreen(device: widget.device),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Camera'),
            Tab(icon: Icon(Icons.info), text: 'Thông tin'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.settings), text: 'Cài đặt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCameraTab(),
          DeviceInfoPanel(device: widget.device),
          UserManagementPanel(device: widget.device),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    return Column(
      children: [
        // View toggle buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _switchView('live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentView == 'live'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor: _currentView == 'live' ? Colors.white : null,
                ),
                child: const Text('Live'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _switchView('playback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentView == 'playback'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor:
                      _currentView == 'playback' ? Colors.white : null,
                ),
                child: const Text('Playback'),
              ),
            ],
          ),
        ),

        // Camera view
        Expanded(
          child: CameraView(
            device: widget.device,
            viewType: _currentView,
            onvifService: _onvifService,
          ),
        ),

        // Camera controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  // Take snapshot
                },
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Chụp ảnh',
              ),
              IconButton(
                onPressed: () {
                  // Record
                },
                icon: const Icon(Icons.fiber_manual_record),
                tooltip: 'Ghi hình',
              ),
              IconButton(
                onPressed: () {
                  // Refresh
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
            ],
          ),
        ),

        // PTZ controls
        Container(
          padding: const EdgeInsets.all(16),
          child: PTZControl(
            device: widget.device,
            onvifService: _onvifService,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text('Cài đặt thiết bị'),
    );
  }
}
