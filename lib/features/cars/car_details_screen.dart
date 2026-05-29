import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/car.dart';
import '../../core/services/auth_service.dart';
import '../messages/messages_screen.dart';
import './booking_flow_screen.dart';
import '../owner/owner_rating_details_screen.dart';

class CarDetailsScreen extends StatelessWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<Car>(
      stream: firestore.getCar(carId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: Text('Car not found')));

        final car = snapshot.data!;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(
                      imageUrl: car.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey))),
                    ),
                    StreamBuilder<bool>(
                      stream: firestore.getCarAvailability(carId),
                      builder: (context, availSnap) {
                        final isAvailable = availSnap.data ?? true;
                        return Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: isAvailable ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                            child: Text(isAvailable ? 'Available Today' : 'Rented Today', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(car.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('\$${car.price.toStringAsFixed(0)}/day', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: firestore.getOwnerRatingInfo(car.ownerId),
                      builder: (context, ratingSnap) {
                        final data = ratingSnap.data ?? {'average': 0.0, 'count': 0};
                        final avg = data['average'] as double;
                        final count = data['count'] as int;
                        return Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('($count reviews)', 
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerRatingDetailsScreen(ownerId: car.ownerId, ownerName: 'Owner')));
                            },
                            child: const Text('More Details'),
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(car.location, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(car.type, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 24),
                    Text('Fuel Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(
                        car.fuelType == 'Electric' ? Icons.electric_car :
                        car.fuelType == 'Hybrid' ? Icons.eco : Icons.local_gas_station,
                        size: 18,
                      ),
                      label: Text(car.fuelType),
                      backgroundColor: Colors.grey[100],
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Text('Best Used For', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: car.usage.isEmpty
                        ? [const Text('No usage info', style: TextStyle(color: Colors.grey, fontSize: 12))]
                        : car.usage.map((u) => Chip(
                            label: Text(u[0].toUpperCase() + u.substring(1)), 
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1), 
                            side: BorderSide.none,
                            labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)
                          )).toList()),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(children: [
              IconButton(
                onPressed: () async {
                  final auth = context.read<AuthService>();
                  final user = auth.currentUser;
                  if (user == null) return;
                  if (user.uid == car.ownerId) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You can't message yourself")));
                    return;
                  }
                  final myData = await firestore.getUser(user.uid);
                  final ownerData = await firestore.getUser(car.ownerId);
                  final myName = myData?['displayName'] ?? user.displayName ?? 'User';
                  final ownerEmail = ownerData?['email'] ?? '';
                  final ownerName = ownerData?['displayName'] ?? 'Owner';
                  final chatId = await firestore.startChat(myId: user.uid, myName: myName, myEmail: user.email ?? '', ownerId: car.ownerId, ownerName: ownerName, ownerEmail: ownerEmail);
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserName: ownerName, otherUserEmail: ownerEmail, otherUserId: car.ownerId)));
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[100], padding: const EdgeInsets.all(12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final currentUser = context.read<AuthService>().currentUser;
                    final isOwner = currentUser?.uid == car.ownerId;
                    return FilledButton(
                      onPressed: isOwner ? null : () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFlowScreen(carId: car.id))); },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text('Book Now'),
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
