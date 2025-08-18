import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../graph_renderer.dart';

/// Simple flowchart renderer using graphview
class FlowchartRenderer extends GraphRenderer {
  @override
  String get type => 'flowchart';
  
  @override
  String get displayName => 'Simple Flowcharts';
  
  @override
  List<String> get supportedSyntaxes => [
    'flowchart',
    'flow',
    'diagram',
  ];
  
  @override
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    final flowData = _parseFlowContent(content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: options?.height ?? 400,
      width: options?.width ?? double.infinity,
      padding: const EdgeInsets.all(16),
      child: _buildGraphView(flowData, isDark),
    );
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    final flowData = _parseFlowContent(content);
    return GraphMetadata(
      title: flowData.title,
      attributes: {
        'nodes': flowData.nodes.length.toString(),
        'edges': flowData.edges.length.toString(),
      },
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    try {
      final flowData = _parseFlowContent(content);
      final errors = <String>[];
      
      if (flowData.nodes.isEmpty) {
        errors.add('Flowchart must contain at least one node');
      }
      
      // Validate edge references
      final nodeIds = flowData.nodes.map((n) => n.id).toSet();
      for (final edge in flowData.edges) {
        if (!nodeIds.contains(edge.from)) {
          errors.add('Edge references undefined node: ${edge.from}');
        }
        if (!nodeIds.contains(edge.to)) {
          errors.add('Edge references undefined node: ${edge.to}');
        }
      }
      
      return errors.isNotEmpty 
          ? GraphValidationResult.invalid(errors)
          : GraphValidationResult.valid();
          
    } catch (e) {
      return GraphValidationResult.invalid(['Failed to parse flowchart: $e']);
    }
  }
  
  FlowchartData _parseFlowContent(String content) {
    final lines = content.trim().split('\n');
    
    String? title;
    final nodes = <FlowNode>[];
    final edges = <FlowEdge>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      
      // Parse title
      if (trimmed.startsWith('title:')) {
        title = trimmed.substring(6).trim();
        continue;
      }
      
      // Parse node: [id] label
      final nodeMatch = RegExp(r'^\[(\w+)\]\s+(.+)$').firstMatch(trimmed);
      if (nodeMatch != null) {
        final id = nodeMatch.group(1)!;
        final label = nodeMatch.group(2)!;
        nodes.add(FlowNode(
          id: id,
          label: label,
          type: FlowNodeType.process,
        ));
        continue;
      }
      
      // Parse decision: {id} label
      final decisionMatch = RegExp(r'^\{(\w+)\}\s+(.+)$').firstMatch(trimmed);
      if (decisionMatch != null) {
        final id = decisionMatch.group(1)!;
        final label = decisionMatch.group(2)!;
        nodes.add(FlowNode(
          id: id,
          label: label,
          type: FlowNodeType.decision,
        ));
        continue;
      }
      
      // Parse start/end: (id) label
      final terminalMatch = RegExp(r'^\((\w+)\)\s+(.+)$').firstMatch(trimmed);
      if (terminalMatch != null) {
        final id = terminalMatch.group(1)!;
        final label = terminalMatch.group(2)!;
        final type = label.toLowerCase().contains('end') 
            ? FlowNodeType.end
            : FlowNodeType.start;
        nodes.add(FlowNode(
          id: id,
          label: label,
          type: type,
        ));
        continue;
      }
      
      // Parse edge: from -> to [label]
      final edgeMatch = RegExp(r'^(\w+)\s*->\s*(\w+)(?:\s+(.+))?$').firstMatch(trimmed);
      if (edgeMatch != null) {
        final from = edgeMatch.group(1)!;
        final to = edgeMatch.group(2)!;
        final label = edgeMatch.group(3);
        edges.add(FlowEdge(
          from: from,
          to: to,
          label: label,
        ));
      }
    }
    
    return FlowchartData(
      title: title,
      nodes: nodes,
      edges: edges,
    );
  }
  
  Widget _buildGraphView(FlowchartData flowData, bool isDark) {
    final graph = Graph()..isTree = true;
    
    // Add nodes
    for (final node in flowData.nodes) {
      graph.addNode(Node.Id(node.id));
    }
    
    // Add edges
    for (final edge in flowData.edges) {
      graph.addEdge(Node.Id(edge.from), Node.Id(edge.to));
    }
    
    return InteractiveViewer(
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(
          SugiyamaConfiguration()
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
            ..levelSeparation = 50
            ..nodeSeparation = 50,
        ),
        paint: Paint()
          ..color = isDark ? Colors.white : Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final flowNode = flowData.nodes.firstWhere((n) => n.id == node.key?.value);
          return _buildNodeWidget(flowNode, isDark);
        },
      ),
    );
  }
  
  Widget _buildNodeWidget(FlowNode node, bool isDark) {
    final backgroundColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = _getNodeColor(node.type);
    
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: _getNodeBorderRadius(node.type),
      ),
      child: Text(
        node.label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
    
    // Wrap decision nodes in diamond shape
    if (node.type == FlowNodeType.decision) {
      content = Transform.rotate(
        angle: 0, // Keep text horizontal
        child: Container(
          padding: const EdgeInsets.all(4),
          child: content,
        ),
      );
    }
    
    return content;
  }
  
  Color _getNodeColor(FlowNodeType type) {
    switch (type) {
      case FlowNodeType.start:
        return const Color(0xff10b981); // Green
      case FlowNodeType.end:
        return const Color(0xffef4444); // Red
      case FlowNodeType.decision:
        return const Color(0xfff59e0b); // Amber
      case FlowNodeType.process:
        return const Color(0xff6366f1); // Indigo
    }
  }
  
  BorderRadius _getNodeBorderRadius(FlowNodeType type) {
    switch (type) {
      case FlowNodeType.start:
      case FlowNodeType.end:
        return BorderRadius.circular(20); // Oval
      case FlowNodeType.decision:
        return BorderRadius.circular(4); // Diamond-ish
      case FlowNodeType.process:
        return BorderRadius.circular(8); // Rectangle
    }
  }
}

class FlowchartData {
  final String? title;
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  
  FlowchartData({
    this.title,
    required this.nodes,
    required this.edges,
  });
}

class FlowNode {
  final String id;
  final String label;
  final FlowNodeType type;
  
  FlowNode({
    required this.id,
    required this.label,
    required this.type,
  });
}

class FlowEdge {
  final String from;
  final String to;
  final String? label;
  
  FlowEdge({
    required this.from,
    required this.to,
    this.label,
  });
}

enum FlowNodeType {
  start,
  end,
  process,
  decision,
}