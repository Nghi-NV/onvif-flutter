import 'package:flutter/material.dart';
import '../models/device_model.dart';

class UserManagementPanel extends StatefulWidget {
  final DeviceModel device;

  const UserManagementPanel({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  _UserManagementPanelState createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  List<Map<String, dynamic>> users = [
    {
      'username': 'admin',
      'level': 'Administrator',
      'groups': ['Admin'],
      'enabled': true,
    },
    {
      'username': 'Farmbot',
      'level': 'Administrator',
      'groups': ['Admin'],
      'enabled': true,
    },
    {
      'username': 'nghinv',
      'level': 'User',
      'groups': ['User'],
      'enabled': true,
    },
  ];

  List<Map<String, dynamic>> groups = [
    {
      'name': 'Admin',
      'description': 'Administrator group',
      'permissions': ['Full Access'],
    },
    {
      'name': 'User',
      'description': 'Regular user group',
      'permissions': ['View Only'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.group), text: 'Groups'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersTab(),
                _buildGroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Add User Button
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addUser,
                  icon: Icon(Icons.person_add),
                  label: Text('Thêm User'),
                ),
              ),
            ],
          ),
        ),
        
        // Users List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['enabled'] ? Colors.green : Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user['username']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level: ${user['level']}'),
                      Text('Groups: ${user['groups'].join(', ')}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editUser(user);
                      } else if (value == 'delete') {
                        _deleteUser(user['username']);
                      } else if (value == 'toggle') {
                        _toggleUser(user['username']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              user['enabled'] ? Icons.block : Icons.check_circle,
                              color: user['enabled'] ? Colors.red : Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(user['enabled'] ? 'Vô hiệu hóa' : 'Kích hoạt'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        // Add Group Button
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addGroup,
                  icon: Icon(Icons.group_add),
                  label: Text('Thêm Group'),
                ),
              ),
            ],
          ),
        ),
        
        // Groups List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(group['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['description']),
                      Text('Permissions: ${group['permissions'].join(', ')}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editGroup(group);
                      } else if (value == 'delete') {
                        _deleteGroup(group['name']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(),
              ),
              items: ['Administrator', 'User'].map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm user')),
              );
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sửa user: ${user['username']}')),
    );
  }

  void _deleteUser(String username) {
    setState(() {
      users.removeWhere((user) => user['username'] == username);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa user: $username')),
    );
  }

  void _toggleUser(String username) {
    setState(() {
      final user = users.firstWhere((user) => user['username'] == username);
      user['enabled'] = !user['enabled'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thay đổi trạng thái user: $username')),
    );
  }

  void _addGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm group')),
              );
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _editGroup(Map<String, dynamic> group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sửa group: ${group['name']}')),
    );
  }

  void _deleteGroup(String name) {
    setState(() {
      groups.removeWhere((group) => group['name'] == name);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa group: $name')),
    );
  }
}
