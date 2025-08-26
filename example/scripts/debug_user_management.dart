import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug User Management SOAP Fault
void main() async {
  print('=== Debug User Management SOAP Fault ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    // Test each user management operation individually
    print('🔍 Testing individual user management operations...\n');

    // 1. Test GetUsers
    print('1. Testing GetUsers...');
    try {
      final users = await client.getUsers();
      print('✅ GetUsers successful: Found ${users.length} users');
      for (final user in users) {
        print('   - ${user.username} (${user.userLevel.value})');
      }
    } catch (e) {
      print('❌ GetUsers failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 2. Test CreateUser
    print('2. Testing CreateUser...');
    try {
      await client.createUser(
        username: 'test_user_debug',
        password: 'test123',
        userLevel: UserLevel.user,
        accessRights: AccessRights.userRights,
        userInformation: const UserInformation(
          firstName: 'Test',
          lastName: 'Debug',
          emailAddress: 'test.debug@example.com',
        ),
      );
      print('✅ CreateUser successful');
    } catch (e) {
      print('❌ CreateUser failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 3. Test CreateGroup
    print('3. Testing CreateGroup...');
    try {
      await client.createGroup(
        groupName: 'TestDebugGroup',
        description: 'Test group for debugging',
        accessRights: AccessRights.userRights,
      );
      print('✅ CreateGroup successful');
    } catch (e) {
      print('❌ CreateGroup failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 4. Test AddUserToGroup
    print('4. Testing AddUserToGroup...');
    try {
      await client.addUserToGroup(
        username: 'test_user_debug',
        groupName: 'TestDebugGroup',
      );
      print('✅ AddUserToGroup successful');
    } catch (e) {
      print('❌ AddUserToGroup failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 5. Test GetGroups
    print('5. Testing GetGroups...');
    try {
      final groups = await client.getGroups();
      print('✅ GetGroups successful: Found ${groups.length} groups');
      for (final group in groups) {
        print('   - ${group.groupName}: ${group.members.length} members');
      }
    } catch (e) {
      print('❌ GetGroups failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 6. Test GetUserOptions
    print('6. Testing GetUserOptions...');
    try {
      final userOptions = await client.getUserOptions();
      print('✅ GetUserOptions successful');
      print('   Max Users: ${userOptions.maxUsers}');
      print('   Max Groups: ${userOptions.maxGroups}');
      print(
          '   Supported Levels: ${userOptions.supportedUserLevels.map((e) => e.value).join(', ')}');
    } catch (e) {
      print('❌ GetUserOptions failed: $e');
      if (e is OnvifSoapException) {
        print('   Fault Code: ${e.faultCode}');
        print('   Fault String: ${e.faultString}');
        print('   Detail: ${e.detail}');
      }
    }
    print('');

    // 7. Test Raw SOAP Request để debug chi tiết
    print('7. Testing Raw SOAP CreateUsers request...');

    final transport = OnvifTransport(
      baseUrl: 'http://fb000033.ddns.net:8080',
      timeout: Duration(seconds: 30),
    );

    try {
      final createUserRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
        body:
            '''<tds:CreateUsers xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
          <tds:User>
            <tds:Username>raw_test_user</tds:Username>
            <tds:Password>raw123</tds:Password>
            <tds:UserLevel>User</tds:UserLevel>
          </tds:User>
        </tds:CreateUsers>''',
        username: 'admin',
        password: 'FB000033',
        action: 'http://www.onvif.org/ver10/device/wsdl/CreateUsers',
        headers: {'tds': 'http://www.onvif.org/ver10/device/wsdl'},
      );

      final response = await transport.sendSoapRequest(
        path: '/onvif/device_service',
        soapBody: createUserRequest,
        soapAction: 'http://www.onvif.org/ver10/device/wsdl/CreateUsers',
      );

      print('✅ Raw CreateUsers successful');
      print('Response: ${response.substring(0, 200)}...');
    } catch (e) {
      print('❌ Raw CreateUsers failed: $e');
      if (e is OnvifSoapException) {
        print('   Raw Fault Code: ${e.faultCode}');
        print('   Raw Fault String: ${e.faultString}');
        print('   Raw Detail: ${e.detail}');
      }
    }
    print('');

    // 8. Test capabilities để xem device có support user management không
    print('8. Checking device capabilities for user management...');
    try {
      final capabilities = await client.getCapabilities();
      print('✅ Device capabilities:');
      print('   Device Service: ${capabilities.device?.xAddr}');

      // Check device info for supported features
      final deviceInfo = await client.getDeviceInformation();
      print('   Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
      print('   Firmware: ${deviceInfo.firmwareVersion}');
    } catch (e) {
      print('❌ Failed to get capabilities: $e');
    }

    // Cleanup - try to delete test data if created
    print('\n🧹 Cleanup...');

    try {
      await client.deleteUser('test_user_debug');
      print('✅ Deleted test_user_debug');
    } catch (e) {
      print('ℹ️  Could not delete test_user_debug: $e');
    }

    try {
      await client.deleteUser('raw_test_user');
      print('✅ Deleted raw_test_user');
    } catch (e) {
      print('ℹ️  Could not delete raw_test_user: $e');
    }

    try {
      await client.deleteGroup('TestDebugGroup');
      print('✅ Deleted TestDebugGroup');
    } catch (e) {
      print('ℹ️  Could not delete TestDebugGroup: $e');
    }

    transport.dispose();
  } catch (e) {
    print('❌ Main error: $e');
    if (e is OnvifException) {
      print('   Type: ${e.runtimeType}');
      print('   Message: ${e.message}');
      print('   Code: ${e.code}');
    }
  } finally {
    client.dispose();
    print('\n🧹 Client disposed');
  }
}
