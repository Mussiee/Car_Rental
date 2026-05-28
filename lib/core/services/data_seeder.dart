import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _mockCars = [
    {
      'id': '1',
      'name': 'Toyota Camry 2023',
      'type': 'Sedan',
      'price': 2500,
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1553440569-bcc63803a83d?w=800',
      'routeFitScore': 90,
      'ownerId': 'owner1',
      'features': ['Gas'],
      'suitable': [],
      'location': 'Addis Ababa',
      'usage': ['city', 'long distance'],
    },
    {
      'id': '2',
      'name': 'Tesla Model 3',
      'type': 'Sedan',
      'price': 6000,
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0afa?w=800',
      'routeFitScore': 92,
      'ownerId': 'owner2',
      'features': ['Electric'],
      'suitable': [],
      'location': 'Addis Ababa',
      'usage': ['city'],
    },
    {
      'id': '3',
      'name': 'Toyota Land Cruiser',
      'type': 'SUV',
      'price': 5500,
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1606611013016-969c19ba27d5?w=800',
      'routeFitScore': 98,
      'ownerId': 'owner1',
      'features': ['Gas'],
      'suitable': [],
      'location': 'Bahir Dar',
      'usage': ['mountain', 'long distance'],
    },
    {
      'id': '4',
      'name': 'Hyundai Tucson Hybrid',
      'type': 'SUV',
      'price': 4000,
      'rating': 4.6,
      'image': 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
      'routeFitScore': 88,
      'ownerId': 'owner3',
      'features': ['Hybrid'],
      'suitable': [],
      'location': 'Hawassa',
      'usage': ['city', 'long distance'],
    },
    {
      'id': '5',
      'name': 'Suzuki Swift',
      'type': 'Compact',
      'price': 1500,
      'rating': 4.3,
      'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800',
      'routeFitScore': 82,
      'ownerId': 'owner2',
      'features': ['Gas'],
      'suitable': [],
      'location': 'Adama',
      'usage': ['city'],
    },
  ];

  Future<void> seedCars() async {
    final batch = _db.batch();
    for (var carData in _mockCars) {
      final docRef = _db.collection('cars').doc(carData['id'].toString());
      batch.set(docRef, carData);
    }
    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
