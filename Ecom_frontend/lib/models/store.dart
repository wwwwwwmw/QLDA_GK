class Store {
  final String id;
  final String ownerId;
  final String name;
  final String status;

  Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.status,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'].toString(),
      ownerId: json['owner_id'],
      name: json['name'],
      status: json['status'],
    );
  }
}
