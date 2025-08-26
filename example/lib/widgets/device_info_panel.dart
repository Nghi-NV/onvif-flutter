import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceInfoPanel extends StatelessWidget {
  final DeviceModel device;

  const DeviceInfoPanel({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Status Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Trạng thái thiết bị',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Trạng thái', device.isOnline ? 'Online' : 'Offline', 
                    device.isOnline ? Colors.green : Colors.red),
                  _buildInfoRow('Lần cuối kết nối', 
                    '${device.lastSeen.day}/${device.lastSeen.month}/${device.lastSeen.year} ${device.lastSeen.hour}:${device.lastSeen.minute}'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Device Information Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.device_hub, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Thông tin thiết bị',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Tên thiết bị', device.name),
                  _buildInfoRow('Nhà sản xuất', device.manufacturer),
                  _buildInfoRow('Model', device.model),
                  _buildInfoRow('Host/IP', device.host),
                  _buildInfoRow('Port', device.port.toString()),
                  _buildInfoRow('Username', device.username),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Network Information Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.network_check, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Thông tin mạng',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Địa chỉ IP', device.host),
                  _buildInfoRow('Port ONVIF', device.port.toString()),
                  _buildInfoRow('Protocol', 'HTTP/HTTPS'),
                  _buildInfoRow('Connection', 'TCP'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick Actions Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Thao tác nhanh',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang ping thiết bị...')),
                            );
                          },
                          icon: Icon(Icons.network_ping),
                          label: Text('Ping'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang kiểm tra kết nối...')),
                            );
                          },
                          icon: Icon(Icons.wifi),
                          label: Text('Test'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang khởi động lại...')),
                            );
                          },
                          icon: Icon(Icons.restart_alt),
                          label: Text('Restart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang cập nhật firmware...')),
                            );
                          },
                          icon: Icon(Icons.system_update),
                          label: Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
