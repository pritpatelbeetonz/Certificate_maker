import 'path_command.dart';

/// Parses SVG path strings into platform-independent PathCommand lists.
class SvgPathParser {
  static List<PathCommand> parse(String pathData) {
    final List<PathCommand> commands = [];
    if (pathData.isEmpty) return commands;

    // Tokenize SVG path data (separating command characters and numeric components)
    final tokenRegex = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)');
    final matches = tokenRegex.allMatches(pathData);
    final List<String> tokens = [];
    for (final match in matches) {
      if (match.group(1) != null) tokens.add(match.group(1)!);
      if (match.group(2) != null) tokens.add(match.group(2)!);
    }

    int i = 0;
    String activeCmd = '';
    double currentX = 0.0;
    double currentY = 0.0;
    double startX = 0.0;
    double startY = 0.0;
    double lastCtrlX = 0.0;
    double lastCtrlY = 0.0;

    double parseNextDouble() {
      if (i >= tokens.length) return 0.0;
      return double.tryParse(tokens[i++]) ?? 0.0;
    }

    bool parseNextBool() {
      if (i >= tokens.length) return false;
      final val = tokens[i++];
      return val == '1' || val.toLowerCase() == 'true';
    }

    while (i < tokens.length) {
      final token = tokens[i];
      // Check if token is a command letter
      if (RegExp(r'[MmLlHhVvCcSsQqTtAaZz]').hasMatch(token)) {
        activeCmd = token;
        i++;
      }

      // If activeCmd is empty and we saw a number first, fallback or break
      if (activeCmd.isEmpty) {
        i++;
        continue;
      }

      switch (activeCmd) {
        case 'M':
          final x = parseNextDouble();
          final y = parseNextDouble();
          commands.add(MoveToCommand(x, y));
          currentX = x;
          currentY = y;
          startX = x;
          startY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          activeCmd = 'L'; // Subsequent coordinates are treated as LineTo
          break;
        case 'm':
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x = currentX + dx;
          final y = currentY + dy;
          commands.add(MoveToCommand(x, y));
          currentX = x;
          currentY = y;
          startX = x;
          startY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          activeCmd = 'l'; // Subsequent coordinates are treated as relative LineTo
          break;
        case 'L':
          final x = parseNextDouble();
          final y = parseNextDouble();
          commands.add(LineToCommand(x, y));
          currentX = x;
          currentY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          break;
        case 'l':
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x = currentX + dx;
          final y = currentY + dy;
          commands.add(LineToCommand(x, y));
          currentX = x;
          currentY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          break;
        case 'H':
          final x = parseNextDouble();
          commands.add(LineToCommand(x, currentY));
          currentX = x;
          lastCtrlX = x;
          lastCtrlY = currentY;
          break;
        case 'h':
          final dx = parseNextDouble();
          final x = currentX + dx;
          commands.add(LineToCommand(x, currentY));
          currentX = x;
          lastCtrlX = x;
          lastCtrlY = currentY;
          break;
        case 'V':
          final y = parseNextDouble();
          commands.add(LineToCommand(currentX, y));
          currentY = y;
          lastCtrlX = currentX;
          lastCtrlY = y;
          break;
        case 'v':
          final dy = parseNextDouble();
          final y = currentY + dy;
          commands.add(LineToCommand(currentX, y));
          currentY = y;
          lastCtrlX = currentX;
          lastCtrlY = y;
          break;
        case 'C':
          final x1 = parseNextDouble();
          final y1 = parseNextDouble();
          final x2 = parseNextDouble();
          final y2 = parseNextDouble();
          final x = parseNextDouble();
          final y = parseNextDouble();
          commands.add(CubicToCommand(x1, y1, x2, y2, x, y));
          lastCtrlX = x2;
          lastCtrlY = y2;
          currentX = x;
          currentY = y;
          break;
        case 'c':
          final dx1 = parseNextDouble();
          final dy1 = parseNextDouble();
          final dx2 = parseNextDouble();
          final dy2 = parseNextDouble();
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x1 = currentX + dx1;
          final y1 = currentY + dy1;
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          final x = currentX + dx;
          final y = currentY + dy;
          commands.add(CubicToCommand(x1, y1, x2, y2, x, y));
          lastCtrlX = x2;
          lastCtrlY = y2;
          currentX = x;
          currentY = y;
          break;
        case 'S':
          final x2 = parseNextDouble();
          final y2 = parseNextDouble();
          final x = parseNextDouble();
          final y = parseNextDouble();
          final x1 = currentX * 2 - lastCtrlX;
          final y1 = currentY * 2 - lastCtrlY;
          commands.add(CubicToCommand(x1, y1, x2, y2, x, y));
          lastCtrlX = x2;
          lastCtrlY = y2;
          currentX = x;
          currentY = y;
          break;
        case 's':
          final dx2 = parseNextDouble();
          final dy2 = parseNextDouble();
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          final x = currentX + dx;
          final y = currentY + dy;
          final x1 = currentX * 2 - lastCtrlX;
          final y1 = currentY * 2 - lastCtrlY;
          commands.add(CubicToCommand(x1, y1, x2, y2, x, y));
          lastCtrlX = x2;
          lastCtrlY = y2;
          currentX = x;
          currentY = y;
          break;
        case 'Q':
          final x1 = parseNextDouble();
          final y1 = parseNextDouble();
          final x = parseNextDouble();
          final y = parseNextDouble();
          commands.add(QuadToCommand(x1, y1, x, y));
          lastCtrlX = x1;
          lastCtrlY = y1;
          currentX = x;
          currentY = y;
          break;
        case 'q':
          final dx1 = parseNextDouble();
          final dy1 = parseNextDouble();
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x1 = currentX + dx1;
          final y1 = currentY + dy1;
          final x = currentX + dx;
          final y = currentY + dy;
          commands.add(QuadToCommand(x1, y1, x, y));
          lastCtrlX = x1;
          lastCtrlY = y1;
          currentX = x;
          currentY = y;
          break;
        case 'T':
          final x = parseNextDouble();
          final y = parseNextDouble();
          final x1 = currentX * 2 - lastCtrlX;
          final y1 = currentY * 2 - lastCtrlY;
          commands.add(QuadToCommand(x1, y1, x, y));
          lastCtrlX = x1;
          lastCtrlY = y1;
          currentX = x;
          currentY = y;
          break;
        case 't':
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x = currentX + dx;
          final y = currentY + dy;
          final x1 = currentX * 2 - lastCtrlX;
          final y1 = currentY * 2 - lastCtrlY;
          commands.add(QuadToCommand(x1, y1, x, y));
          lastCtrlX = x1;
          lastCtrlY = y1;
          currentX = x;
          currentY = y;
          break;
        case 'A':
          final rx = parseNextDouble();
          final ry = parseNextDouble();
          final rot = parseNextDouble();
          final largeArc = parseNextBool();
          final sweep = parseNextBool();
          final x = parseNextDouble();
          final y = parseNextDouble();
          commands.add(ArcToCommand(rx, ry, rot, largeArc, sweep, x, y));
          currentX = x;
          currentY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          break;
        case 'a':
          final rx = parseNextDouble();
          final ry = parseNextDouble();
          final rot = parseNextDouble();
          final largeArc = parseNextBool();
          final sweep = parseNextBool();
          final dx = parseNextDouble();
          final dy = parseNextDouble();
          final x = currentX + dx;
          final y = currentY + dy;
          commands.add(ArcToCommand(rx, ry, rot, largeArc, sweep, x, y));
          currentX = x;
          currentY = y;
          lastCtrlX = x;
          lastCtrlY = y;
          break;
        case 'Z':
        case 'z':
          commands.add(const CloseCommand());
          currentX = startX;
          currentY = startY;
          lastCtrlX = startX;
          lastCtrlY = startY;
          break;
        default:
          i++;
      }
    }

    return commands;
  }
}
