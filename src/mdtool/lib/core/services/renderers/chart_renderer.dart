import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../graph_renderer.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Chart renderer for statistical charts using fl_chart
class ChartRenderer extends GraphRenderer {
  @override
  String get type => 'chart';
  
  @override
  String get displayName => 'Statistical Charts';
  
  @override
  List<String> get supportedSyntaxes => [
    'chart',
    'barchart',
    'linechart',
    'piechart',
    'scatterchart',
    'areachart',
  ];
  
  @override
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    final chartData = _parseChartContent(content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (chartData.type) {
      case ChartType.bar:
        return _buildBarChart(chartData, isDark, options);
      case ChartType.line:
        return _buildLineChart(chartData, isDark, options);
      case ChartType.pie:
        return _buildPieChart(chartData, isDark, options);
      case ChartType.scatter:
        return _buildScatterChart(chartData, isDark, options);
      case ChartType.area:
        return _buildAreaChart(chartData, isDark, options);
      default:
        throw Exception('Unsupported chart type: ${chartData.type}');
    }
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    final chartData = _parseChartContent(content);
    return GraphMetadata(
      title: chartData.title,
      description: chartData.description,
      attributes: {
        'type': chartData.type.toString(),
        'data_points': chartData.data.length.toString(),
      },
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    try {
      final chartData = _parseChartContent(content);
      final errors = <String>[];
      
      if (chartData.data.isEmpty) {
        errors.add('Chart data cannot be empty');
      }
      
      if (chartData.type == ChartType.pie) {
        for (final point in chartData.data) {
          if (point.y <= 0) {
            errors.add('Pie chart values must be positive');
            break;
          }
        }
      }
      
      return errors.isNotEmpty 
          ? GraphValidationResult.invalid(errors)
          : GraphValidationResult.valid();
          
    } catch (e) {
      return GraphValidationResult.invalid(['Failed to parse chart data: $e']);
    }
  }
  
  ChartData _parseChartContent(String content) {
    final lines = content.trim().split('\n');
    
    String? title;
    String? description;
    String? typeStr;
    List<String>? labels;
    final data = <ChartDataPoint>[];
    
    ChartType chartType = ChartType.bar;
    bool inDataSection = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      // Parse metadata
      if (trimmed.startsWith('title:')) {
        title = trimmed.substring(6).trim();
        continue;
      }
      
      if (trimmed.startsWith('description:')) {
        description = trimmed.substring(12).trim();
        continue;
      }
      
      if (trimmed.startsWith('type:')) {
        typeStr = trimmed.substring(5).trim().toLowerCase();
        chartType = _parseChartType(typeStr);
        continue;
      }
      
      if (trimmed.startsWith('labels:')) {
        final labelStr = trimmed.substring(7).trim();
        labels = labelStr.split(',').map((l) => l.trim()).toList();
        continue;
      }
      
      if (trimmed == 'data:') {
        inDataSection = true;
        continue;
      }
      
      // Parse data points
      if (inDataSection) {
        if (trimmed.startsWith('-') || trimmed.contains(':') || trimmed.contains(',')) {
          final point = _parseDataPoint(trimmed, labels);
          if (point != null) {
            data.add(point);
          }
        }
      }
      
      // Try to parse simple format: x,y or label:value
      if (!inDataSection && (trimmed.contains(',') || trimmed.contains(':'))) {
        final point = _parseDataPoint(trimmed, labels);
        if (point != null) {
          data.add(point);
        }
      }
    }
    
    return ChartData(
      type: chartType,
      title: title,
      description: description,
      data: data,
      labels: labels,
    );
  }
  
  ChartType _parseChartType(String typeStr) {
    switch (typeStr) {
      case 'bar':
      case 'barchart':
        return ChartType.bar;
      case 'line':
      case 'linechart':
        return ChartType.line;
      case 'pie':
      case 'piechart':
        return ChartType.pie;
      case 'scatter':
      case 'scatterchart':
        return ChartType.scatter;
      case 'area':
      case 'areachart':
        return ChartType.area;
      default:
        return ChartType.bar;
    }
  }
  
  ChartDataPoint? _parseDataPoint(String line, List<String>? labels) {
    try {
      final trimmed = line.trim();
      
      // Remove YAML list marker
      String cleanLine = trimmed.startsWith('-') ? trimmed.substring(1).trim() : trimmed;
      
      // Parse key:value format
      if (cleanLine.contains(':')) {
        final parts = cleanLine.split(':');
        if (parts.length >= 2) {
          final label = parts[0].trim();
          final valueStr = parts[1].trim();
          final value = double.tryParse(valueStr);
          if (value != null) {
            return ChartDataPoint(x: 0, y: value, label: label);
          }
        }
      }
      
      // Parse x,y format
      if (cleanLine.contains(',')) {
        final parts = cleanLine.split(',');
        if (parts.length >= 2) {
          final xStr = parts[0].trim();
          final yStr = parts[1].trim();
          final x = double.tryParse(xStr) ?? 0;
          final y = double.tryParse(yStr);
          if (y != null) {
            String? label;
            if (parts.length > 2) {
              label = parts[2].trim();
            }
            return ChartDataPoint(x: x, y: y, label: label);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Widget _buildBarChart(ChartData chartData, bool isDark, GraphRenderOptions? options) {
    final colorScheme = _getColorScheme(isDark);
    
    return Container(
      height: options?.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue(chartData.data) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = chartData.data[group.x.toInt()];
                return BarTooltipItem(
                  '${point.label ?? 'Data'}\n${point.y}',
                  TextStyle(color: isDark ? Colors.white : Colors.black),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.data.length) {
                    final point = chartData.data[index];
                    return Text(
                      point.label ?? index.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          barGroups: chartData.data.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: point.y,
                  color: colorScheme[index % colorScheme.length],
                  width: 20,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildLineChart(ChartData chartData, bool isDark, GraphRenderOptions? options) {
    final colorScheme = _getColorScheme(isDark);
    
    return Container(
      height: options?.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = chartData.data[spot.spotIndex];
                  return LineTooltipItem(
                    '${point.label ?? 'Point'}\n(${spot.x}, ${spot.y})',
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.data.map((point) => FlSpot(point.x, point.y)).toList(),
              isCurved: true,
              color: colorScheme[0],
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPieChart(ChartData chartData, bool isDark, GraphRenderOptions? options) {
    final colorScheme = _getColorScheme(isDark);
    
    return Container(
      height: options?.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: chartData.data.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return PieChartSectionData(
              value: point.y,
              title: '${point.label ?? 'Data'}\n${point.y.toStringAsFixed(1)}',
              color: colorScheme[index % colorScheme.length],
              radius: 100,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
  
  Widget _buildScatterChart(ChartData chartData, bool isDark, GraphRenderOptions? options) {
    final colorScheme = _getColorScheme(isDark);
    
    return Container(
      height: options?.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: chartData.data.map((point) {
            return ScatterSpot(
              point.x,
              point.y,
              radius: 8,
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAreaChart(ChartData chartData, bool isDark, GraphRenderOptions? options) {
    final colorScheme = _getColorScheme(isDark);
    
    return Container(
      height: options?.height ?? 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.data.map((point) => FlSpot(point.x, point.y)).toList(),
              isCurved: true,
              color: colorScheme[0],
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme[0].withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Color> _getColorScheme(bool isDark) {
    if (isDark) {
      return [
        const Color(0xff6366f1), // Indigo
        const Color(0xff10b981), // Emerald  
        const Color(0xfff59e0b), // Amber
        const Color(0xffef4444), // Red
        const Color(0xff8b5cf6), // Violet
        const Color(0xff06b6d4), // Cyan
        const Color(0xfff97316), // Orange
        const Color(0xffec4899), // Pink
      ];
    } else {
      return [
        const Color(0xff4f46e5), // Indigo
        const Color(0xff059669), // Emerald
        const Color(0xffd97706), // Amber
        const Color(0xffdc2626), // Red
        const Color(0xff7c3aed), // Violet
        const Color(0xff0891b2), // Cyan
        const Color(0xffea580c), // Orange
        const Color(0xffdb2777), // Pink
      ];
    }
  }
  
  double _getMaxValue(List<ChartDataPoint> data) {
    return data.map((point) => point.y).reduce(math.max);
  }
}

enum ChartType {
  bar,
  line,
  pie,
  scatter,
  area,
}

class ChartData {
  final ChartType type;
  final String? title;
  final String? description;
  final List<ChartDataPoint> data;
  final List<String>? labels;
  
  ChartData({
    required this.type,
    this.title,
    this.description,
    required this.data,
    this.labels,
  });
}

class ChartDataPoint {
  final double x;
  final double y;
  final String? label;
  
  ChartDataPoint({
    required this.x,
    required this.y,
    this.label,
  });
}