import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/review.dart';

class OwnerRatingDetailsScreen extends StatelessWidget {
  final String ownerId;
  final String ownerName;

  const OwnerRatingDetailsScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: Text('$ownerName\'s Ratings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<Map<String, dynamic>>(
              stream: firestore.getOwnerRatingInfo(ownerId),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {'average': 0.0, 'count': 0};
                final avg = data['average'] as double;
                final count = data['count'] as int;
                return Card(
                  elevation: 0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Icon(Icons.star, color: i < avg.round() ? Colors.amber : Colors.grey[300], size: 24))),
                      const SizedBox(height: 8),
                      Text('$count Reviews', style: TextStyle(color: Colors.grey[600])),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<List<Review>>(
              stream: firestore.getOwnerReviews(ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No reviews yet')));
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Row(children: [
                      CircleAvatar(radius: 16, backgroundColor: Colors.blue[100], child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: Colors.blue))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMM d, y').format(review.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ])),
                      Row(children: List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < review.rating ? Colors.amber : Colors.grey[300]))),
                    ]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
