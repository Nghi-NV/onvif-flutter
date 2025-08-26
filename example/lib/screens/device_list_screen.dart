import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../widgets/device_card.dart';
import '../widgets/add_device_dialog.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatefulWidget {
  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<DeviceModel> devices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    setState(() {
      isLoading = true;
    });

    // Simulate loading devices
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        devices = [
          DeviceModel(
            id: '1',
            name: 'Dahua Camera',
            host: 'fb000033.ddns.net',
            port: 8080,
            username: 'admin',
            password: 'FB000033',
            manufacturer: 'Dahua',
            model: 'DH-SD49425GB-HNR',
            isOnline: true,
            lastSeen: DateTime.now(),
          ),
        ];
        isLoading = false;
      });
    });
  }

  void _addDevice() async {
    final result = await showDialog<DeviceModel>(
      context: context,
      builder: (context) => AddDeviceDialog(),
    );

    if (result != null) {
      setState(() {
        devices.add(result);
      });
    }
  }

  void _deleteDevice(String deviceId) {
    setState(() {
      devices.removeWhere((device) => device.id == deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ONVIF Camera Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách thiết bị...'),
                ],
              ),
            )
          : devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có thiết bị nào',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nhấn + để thêm thiết bị mới',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: DeviceCard(
                        device: device,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceDetailScreen(device: device),
                            ),
                          );
                        },
                        onDelete: () => _deleteDevice(device.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDevice,
        child: Icon(Icons.add),
        tooltip: 'Thêm thiết bị',
      ),
    );
  }
}
