import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: device.isOnline ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 16),
              
              // Device icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.videocam,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: 16),
              
              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${device.manufacturer} ${device.model}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${device.host}:${device.port}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: device.isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa thiết bị'),
                      ],
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
