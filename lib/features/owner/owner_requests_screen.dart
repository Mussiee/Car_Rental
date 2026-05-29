import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../cars/booking_details_screen.dart';
import '../messages/messages_screen.dart';

class OwnerRequestsScreen extends StatelessWidget {
  const OwnerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final firestore = context.read<FirestoreService>();

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: StreamBuilder<List<Booking>>(
        stream: firestore.getOwnerBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings = snapshot.data ?? [];

          bookings.sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (a.status != 'pending' && b.status == 'pending') return 1;
            return b.startDate.compareTo(a.startDate);
          });

          if (bookings.isEmpty) {
            return const Center(child: Text('No booking requests yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Trip: ${booking.tripType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(children: [
                            _buildStatusBadge(booking.status),
                            const SizedBox(width: 8),
                            _buildChatButton(context, booking),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Booking ID: ${booking.id.substring(0, 8)}'),
                      Text('Total Price: \$${booking.totalPrice}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)));
                            },
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('View Details'),
                          ),
                          if (booking.status == 'pending')
                            Row(children: [
                              OutlinedButton(
                                onPressed: () => _updateStatus(context, booking.id, 'rejected'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => _updateStatus(context, booking.id, 'approved'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                child: const Text('Approve'),
                              ),
                            ]),
                          if (booking.status == 'approved')
                            FilledButton.icon(
                              onPressed: () => _updateStatus(context, booking.id, 'completed'),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Mark as Completed'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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
          final renterData = await firestore.getUser(booking.userId);
          final myName = myData?['displayName'] ?? user.displayName ?? 'Owner';
          final renterName = renterData?['displayName'] ?? booking.userName;
          final renterEmail = renterData?['email'] ?? '';
          final chatId = await firestore.startChat(
            myId: booking.userId,
            myName: renterName,
            myEmail: renterEmail,
            ownerId: user.uid,
            ownerName: myName,
            ownerEmail: user.email ?? '',
          );
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(chatId: chatId, otherUserName: renterName, otherUserEmail: renterEmail, otherUserId: booking.userId),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _updateStatus(BuildContext context, String bookingId, String status) async {
    try {
      await context.read<FirestoreService>().updateBookingStatus(bookingId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
