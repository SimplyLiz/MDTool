import 'package:equatable/equatable.dart';

enum FavoriteItemType { file, folder }

class FavoriteItem extends Equatable {
  final String path;
  final String name;
  final FavoriteItemType type;
  final DateTime dateAdded;

  const FavoriteItem({
    required this.path,
    required this.name,
    required this.type,
    required this.dateAdded,
  });

  factory FavoriteItem.file(String path) {
    return FavoriteItem(
      path: path,
      name: path.split('/').last,
      type: FavoriteItemType.file,
      dateAdded: DateTime.now(),
    );
  }

  factory FavoriteItem.folder(String path) {
    return FavoriteItem(
      path: path,
      name: path.split('/').last,
      type: FavoriteItemType.folder,
      dateAdded: DateTime.now(),
    );
  }

  FavoriteItem copyWith({
    String? path,
    String? name,
    FavoriteItemType? type,
    DateTime? dateAdded,
  }) {
    return FavoriteItem(
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type.name,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      path: json['path'] as String,
      name: json['name'] as String,
      type: FavoriteItemType.values.byName(json['type'] as String),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(json['dateAdded'] as int),
    );
  }

  @override
  List<Object?> get props => [path, name, type, dateAdded];
}