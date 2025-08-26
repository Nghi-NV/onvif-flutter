import 'dart:io';

/// Test All Scripts - Chạy tất cả các scripts chính để kiểm tra
void main() async {
  print('🧪 ONVIF Flutter Library - Test All Scripts');
  print('=' * 60);
  
  final scripts = [
    'simple_ui_example.dart',
    'test_get_tracks_response_item.dart',
    'test_tracks_parsing.dart',
    'test_recording_segments.dart',
    'debug_get_recordings.dart',
    'debug_user_management.dart',
  ];
  
  int successCount = 0;
  int totalCount = scripts.length;
  
  for (final script in scripts) {
    print('\n🔍 Testing: $script');
    print('-' * 40);
    
    try {
      final result = await Process.run('dart', [script]);
      
      if (result.exitCode == 0) {
        print('✅ SUCCESS: $script');
        successCount++;
      } else {
        print('❌ FAILED: $script');
        print('Error: ${result.stderr}');
      }
    } catch (e) {
      print('❌ ERROR: $script - $e');
    }
  }
  
  print('\n' + '=' * 60);
  print('📊 Test Results Summary:');
  print('✅ Success: $successCount/$totalCount');
  print('❌ Failed: ${totalCount - successCount}/$totalCount');
  
  if (successCount == totalCount) {
    print('🎉 ALL TESTS PASSED! ONVIF Flutter Library is working perfectly!');
  } else {
    print('⚠️  Some tests failed. Check the output above for details.');
  }
}
