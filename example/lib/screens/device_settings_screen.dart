import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceSettingsScreen({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  _DeviceSettingsScreenState createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt thiết bị'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Camera Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.videocam, color: Colors.blue),
              title: Text('Cài đặt Camera'),
              subtitle: Text('Độ phân giải, FPS, Bitrate'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('Độ phân giải', '1920x1080', Icons.aspect_ratio),
                      _buildSettingItem('FPS', '25', Icons.speed),
                      _buildSettingItem('Bitrate', '2048 Kbps', Icons.data_usage),
                      _buildSettingItem('Codec', 'H.264', Icons.code),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt camera')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Recording Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.storage, color: Colors.blue),
              title: Text('Cài đặt Recording'),
              subtitle: Text('Lịch ghi hình, chất lượng'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('Chất lượng ghi hình', 'High', Icons.high_quality),
                      _buildSettingItem('Lịch ghi hình', '24/7', Icons.schedule),
                      _buildSettingItem('Thời gian lưu trữ', '30 ngày', Icons.access_time),
                      _buildSettingItem('Định dạng file', 'MP4', Icons.video_file),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt recording')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Network Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.network_check, color: Colors.blue),
              title: Text('Cài đặt Network'),
              subtitle: Text('IP, Port, Protocol'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('IP Address', widget.device.host, Icons.computer),
                      _buildSettingItem('ONVIF Port', widget.device.port.toString(), Icons.router),
                      _buildSettingItem('RTSP Port', '554', Icons.video_call),
                      _buildSettingItem('HTTP Port', '80', Icons.http),
                      _buildSettingItem('HTTPS Port', '443', Icons.https),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt network')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Security Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.security, color: Colors.blue),
              title: Text('Bảo mật'),
              subtitle: Text('SSL, Authentication'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('SSL/TLS', 'Enabled', Icons.lock),
                      _buildSettingItem('Authentication', 'Basic', Icons.verified_user),
                      _buildSettingItem('Access Control', 'IP Whitelist', Icons.block),
                      _buildSettingItem('Session Timeout', '30 phút', Icons.timer),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt bảo mật')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // PTZ Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Cài đặt PTZ'),
              subtitle: Text('Pan, Tilt, Zoom'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('Pan Speed', '50%', Icons.rotate_left),
                      _buildSettingItem('Tilt Speed', '50%', Icons.rotate_right),
                      _buildSettingItem('Zoom Speed', '50%', Icons.zoom_in),
                      _buildSettingItem('Preset Count', '4', Icons.bookmark),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt PTZ')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // System Settings
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.settings, color: Colors.blue),
              title: Text('Cài đặt hệ thống'),
              subtitle: Text('Firmware, Time, Language'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSettingItem('Firmware Version', '3.200.15OT000.0.R', Icons.system_update),
                      _buildSettingItem('System Time', 'Auto Sync', Icons.access_time),
                      _buildSettingItem('Language', 'Tiếng Việt', Icons.language),
                      _buildSettingItem('Time Zone', 'GMT+7', Icons.location_on),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã lưu cài đặt hệ thống')),
                                );
                              },
                              child: Text('Lưu cài đặt'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
          
          // Danger Zone
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Khu vực nguy hiểm',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showRestartDialog();
                          },
                          icon: Icon(Icons.restart_alt),
                          label: Text('Khởi động lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showResetDialog();
                          },
                          icon: Icon(Icons.restore),
                          label: Text('Reset về mặc định'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Khởi động lại thiết bị'),
        content: Text('Bạn có chắc chắn muốn khởi động lại thiết bị? Thiết bị sẽ mất kết nối trong vài phút.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang khởi động lại thiết bị...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Khởi động lại'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset về mặc định'),
        content: Text('Bạn có chắc chắn muốn reset thiết bị về cài đặt mặc định? Tất cả cài đặt sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang reset thiết bị...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
}
