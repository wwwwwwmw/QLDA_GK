// Hàm helper để parse double một cách an toàn
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null; // Trả về null nếu không thể parse
}

// Hàm helper để parse int một cách an toàn
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt(); // Chuyển double thành int nếu cần
  if (value is String) return int.tryParse(value);
  return null; // Trả về null nếu không thể parse
}
