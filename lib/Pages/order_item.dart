// lib/order_item.dart
class OrderItem {
  final String title;
  final String merchantName;
  final String pickupLocation;
  final String? pickupTime;
  final String price;
  final OrderStatus status;
  final String? imagePath;

  const OrderItem({
    required this.title,
    required this.merchantName,
    required this.pickupLocation,
    this.pickupTime,
    required this.price,
    required this.status,
    this.imagePath,
  });
}

enum OrderStatus { pending, confirmed, cancelled, picked }