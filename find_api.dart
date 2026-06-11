import 'dart:io';
import 'dart:convert';
void main() {
  final lines = File(r'C:\Users\ACER NITRO\.gemini\antigravity\brain\35514500-2a2b-4391-a123-8219695fd9e9\.system_generated\logs\transcript.jsonl').readAsLinesSync();
  for (var line in lines) {
    final data = jsonDecode(line);
    if (data['type'] == 'USER_INPUT' && data['content'].toString().contains('PelangganServis')) {
      print('=== FOUND USER INPUT ===');
      print(data['content'].toString());
    }
  }
}
