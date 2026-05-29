import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/booking.dart';
import '../messages/rate_trip_screen.dart';
import '../messages/messages_screen.dart';

class UserBookingsScreen extends StatelessWidget {
  const UserBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final user = context.read<AuthService>().currentUser;

    if (user == null) return const Center(child: Text('Please login'));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: firestore.getUserBookings(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = snapshot.data ?? [];

            // Auto-complete approved bookings whose end date has passed
            final now = DateTime.now();
            for (final b in bookings) {
              if (b.status == 'approved' && b.endDate.isBefore(now)) {
                firestore.updateBookingStatus(b.id, 'completed');
              }
            }

            final activeBookings = bookings
                .where((b) => b.status == 'pending' || (b.status == 'approved' && !b.endDate.isBefore(now)))
                .toList();

            final pastBookings = bookings
                .where((b) => b.status == 'completed' || b.status == 'rejected' || (b.status == 'approved' && b.endDate.isBefore(now)))
                .toList();

            return TabBarView(
              children: [
                _buildBookingList(context, activeBookings, 'No active rentals'),
                _buildBookingList(context, pastBookings, 'No past rentals'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Booking> bookings,
    String emptyMsg,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: booking.carImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[100]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.car_rental),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.carName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MMM d').format(booking.startDate)} - ${DateFormat('MMM d').format(booking.endDate)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(booking.status),
                    const SizedBox(width: 8),
                    _buildChatButton(context, booking),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '\$${booking.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (booking.status == 'completed' && !booking.isReviewed)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => RateTripScreen(bookingId: booking.id, ownerId: booking.ownerId, carId: booking.carId),
                          ));
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('Rate Your Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatButton(BuildContext context, Booking booking) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: () async {
          final firestore = context.read<FirestoreService>();
          final user = context.read<AuthService>().currentUser;
          if (user == null) return;
          final myData = await firestore.getUser(user.uid);
          final ownerData = await firestore.getUser(booking.ownerId);
          final myName = myData?['displayName'] ?? user.displayName ?? 'User';
          final ownerName = ownerData?['displayName'] ?? 'Owner';
          final ownerEmail = ownerData?['email'] ?? '';
          final chatId = await firestore.startChat(
            myId: user.uid,
            myName: myName,
            myEmail: user.email ?? '',
            ownerId: booking.ownerId,
            ownerName: ownerName,
            ownerEmail: ownerEmail,
          );
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(chatId: chatId, otherUserName: ownerName, otherUserEmail: ownerEmail, otherUserId: booking.ownerId),
            ));
          }
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.blue;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
