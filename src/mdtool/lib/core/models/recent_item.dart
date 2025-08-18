import 'package:equatable/equatable.dart';

enum RecentItemType { file, folder }

class RecentItem extends Equatable {
  final String path;
  final String name;
  final RecentItemType type;
  final DateTime lastAccessed;

  const RecentItem({
    required this.path,
    required this.name,
    required this.type,
    required this.lastAccessed,
  });

  factory RecentItem.file(String path) {
    if (path.trim().isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }
    
    // Extract the filename from the path, handling edge cases
    final pathParts = path.replaceAll(RegExp(r'/+$'), '').split('/');
    final meaningfulParts = pathParts.where((part) => part.isNotEmpty);
    final name = meaningfulParts.isNotEmpty ? meaningfulParts.last : 'Unknown File';
    
    return RecentItem(
      path: path, // Keep original path unchanged
      name: name,
      type: RecentItemType.file,
      lastAccessed: DateTime.now(),
    );
  }

  factory RecentItem.folder(String path) {
    if (path.trim().isEmpty) {
      throw ArgumentError('Folder path cannot be empty');
    }
    
    // Extract the folder name from the path, handling edge cases
    final pathParts = path.replaceAll(RegExp(r'/+$'), '').split('/');
    final meaningfulParts = pathParts.where((part) => part.isNotEmpty);
    final name = meaningfulParts.isNotEmpty ? meaningfulParts.last : 'Unknown Folder';
    
    return RecentItem(
      path: path, // Keep original path unchanged - needed for opening folders
      name: name,
      type: RecentItemType.folder,
      lastAccessed: DateTime.now(),
    );
  }

  RecentItem copyWith({
    String? path,
    String? name,
    RecentItemType? type,
    DateTime? lastAccessed,
  }) {
    return RecentItem(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type.name,
      'lastAccessed': lastAccessed.millisecondsSinceEpoch,
    };
  }

  factory RecentItem.fromJson(Map<String, dynamic> json) {
    return RecentItem(
      path: json['path'] as String,
      name: json['name'] as String,
      type: RecentItemType.values.byName(json['type'] as String),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(json['lastAccessed'] as int),
    );
  }

  @override
  List<Object?> get props => [path, name, type, lastAccessed];
}