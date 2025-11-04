import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../graph_renderer.dart';
import 'dart:math' as math;

/// GitGraph renderer for visualizing Git branching and merging
class GitGraphRenderer extends GraphRenderer {
  @override
  String get type => 'gitgraph';
  
  @override
  String get displayName => 'Git Flow Diagrams';
  
  @override
  List<String> get supportedSyntaxes => [
    'gitgraph',
    'git',
    'gitflow',
  ];
  
  @override
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    final gitData = _parseGitContent(content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gitData.title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              gitData.title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
        Container(
          height: options?.height ?? 400,
          width: options?.width ?? double.infinity,
          padding: const EdgeInsets.all(16),
          child: CustomPaint(
            painter: GitGraphPainter(gitData, isDark),
            child: Container(),
          ),
        ),
      ],
    );
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    final gitData = _parseGitContent(content);
    return GraphMetadata(
      title: gitData.title,
      attributes: {
        'branches': gitData.branches.length.toString(),
        'commits': gitData.commits.length.toString(),
      },
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    try {
      final gitData = _parseGitContent(content);
      final errors = <String>[];
      
      if (gitData.commits.isEmpty) {
        errors.add('Git graph must contain at least one commit');
      }
      
      // Validate branch references
      final branchNames = gitData.branches.map((b) => b.name).toSet();
      for (final commit in gitData.commits) {
        if (!branchNames.contains(commit.branch)) {
          errors.add('Commit references undefined branch: ${commit.branch}');
        }
      }
      
      return errors.isNotEmpty 
          ? GraphValidationResult.invalid(errors)
          : GraphValidationResult.valid();
          
    } catch (e) {
      return GraphValidationResult.invalid(['Failed to parse git graph: $e']);
    }
  }
  
  GitGraphData _parseGitContent(String content) {
    final lines = content.trim().split('\n');
    
    String? title;
    final branches = <GitBranch>[];
    final commits = <GitCommit>[];
    
    String currentBranch = 'main';
    GitBranch? activeBranch;
    
    // Add default main branch
    branches.add(GitBranch(name: 'main', color: const Color(0xff6366f1)));
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      
      // Parse title
      if (trimmed.startsWith('title:')) {
        title = trimmed.substring(6).trim();
        continue;
      }
      
      // Parse branch creation
      if (trimmed.startsWith('branch ')) {
        final branchName = trimmed.substring(7).trim();
        if (!branches.any((b) => b.name == branchName)) {
          branches.add(GitBranch(
            name: branchName,
            color: _getBranchColor(branches.length),
          ));
        }
        continue;
      }
      
      // Parse checkout
      if (trimmed.startsWith('checkout ')) {
        currentBranch = trimmed.substring(9).trim();
        activeBranch = branches.firstWhere((b) => b.name == currentBranch, orElse: () {
          // If branch doesn't exist, create it
          final newBranch = GitBranch(
            name: currentBranch,
            color: _getBranchColor(branches.length),
          );
          branches.add(newBranch);
          return newBranch;
        });
        continue;
      }
      
      // Parse commit
      if (trimmed.startsWith('commit ')) {
        final message = trimmed.substring(7).trim();
        commits.add(GitCommit(
          id: 'c${commits.length + 1}',
          message: message,
          branch: currentBranch,
          x: commits.length.toDouble(),
          y: branches.indexWhere((b) => b.name == currentBranch).toDouble(),
        ));
        continue;
      }
      
      // Parse merge
      if (trimmed.startsWith('merge ')) {
        final sourceBranch = trimmed.substring(6).trim();
        final targetBranchIndex = branches.indexWhere((b) => b.name == currentBranch);
        final sourceBranchIndex = branches.indexWhere((b) => b.name == sourceBranch);
        
        if (sourceBranchIndex >= 0) {
          commits.add(GitCommit(
            id: 'm${commits.length + 1}',
            message: 'Merge $sourceBranch',
            branch: currentBranch,
            x: commits.length.toDouble(),
            y: targetBranchIndex.toDouble(),
            mergeFrom: sourceBranchIndex.toDouble(),
          ));
        }
        continue;
      }
      
      // Parse simple commit syntax (just message)
      if (trimmed.isNotEmpty && 
          !trimmed.contains(':') && 
          !trimmed.startsWith('branch') && 
          !trimmed.startsWith('checkout') &&
          !trimmed.startsWith('merge')) {
        commits.add(GitCommit(
          id: 'c${commits.length + 1}',
          message: trimmed,
          branch: currentBranch,
          x: commits.length.toDouble(),
          y: branches.indexWhere((b) => b.name == currentBranch).toDouble(),
        ));
      }
    }
    
    return GitGraphData(
      title: title,
      branches: branches,
      commits: commits,
    );
  }
  
  Color _getBranchColor(int index) {
    final colors = [
      const Color(0xff6366f1), // Indigo - main
      const Color(0xff10b981), // Emerald - feature
      const Color(0xfff59e0b), // Amber - develop
      const Color(0xffef4444), // Red - hotfix
      const Color(0xff8b5cf6), // Violet - release
      const Color(0xff06b6d4), // Cyan - experimental
    ];
    
    return colors[index % colors.length];
  }
}

class GitGraphData {
  final String? title;
  final List<GitBranch> branches;
  final List<GitCommit> commits;
  
  GitGraphData({
    this.title,
    required this.branches,
    required this.commits,
  });
}

class GitBranch {
  final String name;
  final Color color;
  
  GitBranch({
    required this.name,
    required this.color,
  });
}

class GitCommit {
  final String id;
  final String message;
  final String branch;
  final double x;
  final double y;
  final double? mergeFrom;
  
  GitCommit({
    required this.id,
    required this.message,
    required this.branch,
    required this.x,
    required this.y,
    this.mergeFrom,
  });
}

class GitGraphPainter extends CustomPainter {
  final GitGraphData data;
  final bool isDark;
  
  GitGraphPainter(this.data, this.isDark);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final commitPaint = Paint()
      ..style = PaintingStyle.fill;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    if (data.commits.isEmpty) return;
    
    // Calculate dimensions
    final maxX = data.commits.map((c) => c.x).reduce(math.max);
    final maxY = data.branches.length - 1.0;
    
    final stepX = (size.width - 100) / (maxX + 1);
    final stepY = (size.height - 60) / (maxY + 1);
    final startX = 50.0;
    final startY = 30.0;
    
    // Draw branch lines
    for (int i = 0; i < data.branches.length; i++) {
      final branch = data.branches[i];
      final y = startY + (i * stepY);
      
      paint.color = branch.color.withOpacity(0.3);
      canvas.drawLine(
        Offset(startX, y),
        Offset(size.width - 20, y),
        paint,
      );
      
      // Branch name
      textPainter.text = TextSpan(
        text: branch.name,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
    
    // Draw commits and connections
    for (int i = 0; i < data.commits.length; i++) {
      final commit = data.commits[i];
      final x = startX + (commit.x * stepX);
      final y = startY + (commit.y * stepY);
      
      final branchColor = data.branches
          .firstWhere((b) => b.name == commit.branch)
          .color;
      
      // Draw connection to previous commit on same branch
      if (i > 0) {
        final prevCommit = data.commits
            .where((c) => c.branch == commit.branch && c.x < commit.x)
            .fold<GitCommit?>(null, (prev, curr) =>
                prev == null || curr.x > prev.x ? curr : prev);
        
        if (prevCommit != null) {
          final prevX = startX + (prevCommit.x * stepX);
          final prevY = startY + (prevCommit.y * stepY);
          
          paint.color = branchColor;
          canvas.drawLine(Offset(prevX, prevY), Offset(x, y), paint);
        }
      }
      
      // Draw merge line
      if (commit.mergeFrom != null) {
        final mergeY = startY + (commit.mergeFrom! * stepY);
        paint.color = branchColor.withOpacity(0.7);
        canvas.drawLine(
          Offset(x - stepX * 0.3, mergeY),
          Offset(x, y),
          paint,
        );
      }
      
      // Draw commit dot
      commitPaint.color = branchColor;
      canvas.drawCircle(Offset(x, y), 6, commitPaint);
      
      // Draw commit border
      paint.color = isDark ? Colors.white : Colors.black;
      paint.strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), 6, paint);
      paint.strokeWidth = 2.0;
      
      // Draw commit message
      if (commit.message.isNotEmpty) {
        textPainter.text = TextSpan(
          text: commit.message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 10,
          ),
        );
        textPainter.layout(maxWidth: 150);
        
        final textX = x + 15;
        final textY = y - textPainter.height / 2;
        
        // Draw background for text
        final bgRect = Rect.fromLTWH(
          textX - 2,
          textY - 2,
          textPainter.width + 4,
          textPainter.height + 4,
        );
        
        final bgPaint = Paint()
          ..color = (isDark ? Colors.black : Colors.white).withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
    
    // Draw title if present
    if (data.title != null) {
      textPainter.text = TextSpan(
        text: data.title!,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        (size.width - textPainter.width) / 2,
        5,
      ));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}