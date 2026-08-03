import 'package:flutter/material.dart';
import 'dart:convert';

class JsonTreeViewer extends StatelessWidget {
  final dynamic data;
  final bool isDark;

  const JsonTreeViewer({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (data is! Map && data is! List) {
      return _JsonNodeRenderer(keyName: 'data', data: data, isDark: isDark, isRoot: true);
    }
    
    // For root level Maps or Lists, we just render their children directly
    // so we don't have a useless 'root' expandable box taking up space.
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (data as Map).entries.map((e) => _JsonNodeRenderer(
          keyName: e.key.toString(), 
          data: e.value, 
          isDark: isDark,
          isRoot: true, // First level items start expanded if they are objects
        )).toList(),
      );
    }
    
    if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (data as List).asMap().entries.map((e) => _JsonNodeRenderer(
          keyName: '[${e.key}]', 
          data: e.value, 
          isDark: isDark,
          isRoot: true,
        )).toList(),
      );
    }

    return const SizedBox();
  }
}

class _JsonNodeRenderer extends StatefulWidget {
  final String keyName;
  final dynamic data;
  final bool isDark;
  final bool isRoot;

  const _JsonNodeRenderer({
    required this.keyName,
    required this.data,
    required this.isDark,
    this.isRoot = false,
  });

  @override
  State<_JsonNodeRenderer> createState() => _JsonNodeRendererState();
}

class _JsonNodeRendererState extends State<_JsonNodeRenderer> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isRoot;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data is Map || widget.data is List) {
      final isMap = widget.data is Map;
      final int count = isMap ? (widget.data as Map).length : (widget.data as List).length;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, 
                      size: 16,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.keyName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMap ? '{$count}' : '[$count]',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: isMap
                      ? (widget.data as Map).entries.map((e) => _JsonNodeRenderer(keyName: e.key.toString(), data: e.value, isDark: widget.isDark)).toList()
                      : (widget.data as List).asMap().entries.map((e) => _JsonNodeRenderer(keyName: '[${e.key}]', data: e.value, isDark: widget.isDark)).toList(),
                ),
              ),
          ],
        ),
      );
    } else {
      // Primitive node
      bool isLongString = false;
      if (widget.data is String) {
        final str = widget.data as String;
        if (str.contains('\n') || str.length > 50) isLongString = true;
      }

      if (isLongString) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.keyName}:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.orange[300] : Colors.orange[800],
                ),
              ),
              const SizedBox(height: 4),
              _buildPrimitive(widget.data),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.keyName}: ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.orange[300] : Colors.orange[800],
                ),
              ),
              Expanded(child: _buildPrimitive(widget.data)),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPrimitive(dynamic data) {
    if (data == null) {
      return Text('null', style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.grey[500] : Colors.grey[600]));
    }
    if (data is bool) {
      return Text(data.toString(), style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.purple[300] : Colors.purple[700]));
    }
    if (data is num) {
      return Text(data.toString(), style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.green[300] : Colors.green[800]));
    }
    if (data is String) {
      final str = data;
      if (str.contains('\n') || str.length > 50) {
        String displayStr = str;
        try {
          int startObj = str.indexOf('{');
          int endObj = str.lastIndexOf('}');
          if (startObj >= 0 && endObj > startObj) {
            final jsonSub = str.substring(startObj, endObj + 1);
            final parsed = jsonDecode(jsonSub);
            final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
            displayStr = str.substring(0, startObj) + pretty + str.substring(endObj + 1);
          }
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.isDark ? Colors.white24 : Colors.black12),
          ),
          child: Text(
            displayStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
              color: widget.isDark ? Colors.greenAccent[100] : Colors.indigo,
            ),
          ),
        );
      } else {
        return Text('"$str"', style: TextStyle(fontFamily: 'monospace', color: widget.isDark ? Colors.greenAccent[100] : Colors.indigo));
      }
    }
    return Text(data.toString(), style: const TextStyle(fontFamily: 'monospace'));
  }
}
