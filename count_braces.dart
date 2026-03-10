import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var lines = file.readAsLinesSync();
  int braceCount = 0;
  int parenCount = 0;
  int bracketCount = 0;

  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    
    // Check if it looks like a method declaration in the state class
    if (i > 100 && (line.trim().startsWith('Widget ') || line.trim().startsWith('void '))) {
       print('L${(i+1).toString().padLeft(4)} | B:$braceCount P:$parenCount | ${line.trim()}');
    }

    for (int j = 0; j < line.length; j++) {
      var char = line[j];
      if (char == '{') braceCount++;
      if (char == '}') braceCount--;
      if (char == '(') parenCount++;
      if (char == ')') parenCount--;
      if (char == '[') bracketCount++;
      if (char == ']') bracketCount--;
    }
  }
}
