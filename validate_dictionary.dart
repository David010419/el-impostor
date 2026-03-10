import 'dart:io';

void main() {
  File file = File('lib/datos.dart');
  String content = file.readAsStringSync();
  
  // A simple regex to find all map entries
  RegExp regExp = RegExp(r"\{'palabra':\s*'[^']*',\s*'pista':\s*'[^']*'(?:,\s*'palabra_en':\s*'[^']*',\s*'pista_en':\s*'[^']*')?\}");
  
  Iterable<Match> matches = regExp.allMatches(content);
  print('Found ${matches.length} items using strict definition.');

  // Let's just find anything inside '{...}'
  RegExp genericExp = RegExp(r"\{[^\}]+\}");
  Iterable<Match> genericMatches = genericExp.allMatches(content);
  print('Found ${genericMatches.length} generic items.');
  
  for (var m in genericMatches) {
    String str = m.group(0)!;
    if (!str.contains("'palabra'")) print("Missing palabra: $str");
    if (!str.contains("'pista'")) print("Missing pista: $str");
    if (!str.contains("'palabra_en'")) print("Missing palabra_en: $str");
    if (!str.contains("'pista_en'")) print("Missing pista_en: $str");
  }
}
