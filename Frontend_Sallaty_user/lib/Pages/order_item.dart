enum OrderStatus { pending, confirmed, cancelled, picked }

class OrderItem {
  final String ordreId;
  final String title;
  final String merchantName;
  final String pickupLocation;
  final String? pickupTime;
  final String price;
  final String? imagePath;
  final OrderStatus status;

  const OrderItem({
    required this.ordreId,
    required this.title,
    required this.merchantName,
    required this.pickupLocation,
    this.pickupTime,
    required this.price,
    this.imagePath,
    required this.status,
  });

  OrderItem copyWith({
    String? ordreId,
    String? title,
    String? merchantName,
    String? pickupLocation,
    String? pickupTime,
    String? price,
    String? imagePath,
    OrderStatus? status,
  }) {
    return OrderItem(
      ordreId:        ordreId        ?? this.ordreId,
      title:          title          ?? this.title,
      merchantName:   merchantName   ?? this.merchantName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupTime:     pickupTime     ?? this.pickupTime,
      price:          price          ?? this.price,
      imagePath:      imagePath      ?? this.imagePath,
      status:         status         ?? this.status,
    );
  }

  
}