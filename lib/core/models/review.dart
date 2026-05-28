import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String carId;
  final String ownerId;
  final String userId;
  final String userName;
  final double rating;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.carId,
    required this.ownerId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      bookingId: data['bookingId'] ?? '',
      carId: data['carId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? data['ownerRating'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'carId': carId,
      'ownerId': ownerId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
