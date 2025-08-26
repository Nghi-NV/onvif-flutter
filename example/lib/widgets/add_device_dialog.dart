import 'package:flutter/material.dart';
import '../models/device_model.dart';

class AddDeviceDialog extends StatefulWidget {
  @override
  _AddDeviceDialogState createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate connection test
      await Future.delayed(Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kết nối thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kết nối thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addDevice() {
    if (!_formKey.currentState!.validate()) return;

    final device = DeviceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text,
      password: _passwordController.text,
      manufacturer: 'Unknown',
      model: 'Unknown',
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    Navigator.of(context).pop(device);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thêm thiết bị mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên thiết bị',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên thiết bị';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: 'Host/IP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập host';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.router),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập port';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Port phải là số';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.wifi),
                    label: Text('Test'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _addDevice,
          child: Text('Thêm'),
        ),
      ],
    );
  }
}
