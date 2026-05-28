import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/car.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/car_card.dart';
import '../cars/car_details_screen.dart';
import './user_bookings_screen.dart';
import '../messages/messages_screen.dart';
import './user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Sedan', 'SUV', 'Compact', 'Luxury'];

  String _selectedFuelType = 'All';
  final List<String> _fuelTypes = ['All', 'Gas', 'Electric', 'Hybrid'];

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) return _wrapWithNav(const UserBookingsScreen());
    if (_currentIndex == 2)
      return _wrapWithNav(const MessagesScreen(isOwnerMode: false));
    if (_currentIndex == 3) return _wrapWithNav(const UserProfileScreen());

    final firestore = context.read<FirestoreService>();

    return _wrapWithNav(
      Scaffold(
        appBar: AppBar(
          title: const Text('Wub Drive'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search cars...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(category),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
                      side: BorderSide(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Fuel Type Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Fuel:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  ..._fuelTypes.map((fuel) {
                    final isSelected = _selectedFuelType == fuel;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(fuel),
                        onSelected: (selected) {
                          setState(() => _selectedFuelType = fuel);
                        },
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                        selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Car List
            Expanded(
              child: StreamBuilder<List<Car>>(
                stream: firestore.getCars(category: _selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cars = snapshot.data ?? [];

                  final filteredCars = cars.where((car) {
                    final matchesSearch =
                        car.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        car.location.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );

                    final matchesFuel = _selectedFuelType == 'All' ||
                        car.fuelType == _selectedFuelType;

                    return matchesSearch && matchesFuel;
                  }).toList();

                  if (filteredCars.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.car_rental,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedCategory == 'All' ? '' : _selectedCategory} cars found',
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return CarCard(
                        car: filteredCars[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarDetailsScreen(
                                carId: filteredCars[index].id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isHome: true,
    );
  }

  Widget _wrapWithNav(Widget child, {bool isHome = false}) {
    // If it's a Scaffold, we want to inject the BottomNav into it.
    // If it's already a Scaffold, we probably want to replace its bottomNavItem.
    // However, the cleanest way is to have one Scaffold for the main layout or wrap the body.
    // But since the child screens (Bookings, etc) are currently Scaffolds, we can wrap them in a Column or just use bottomNavigationBar property if we could pass it.
    // Actually, let's just wrap the body content in a generic Scaffold here OR modify the children to not be Scaffolds.
    // For simplicity given the current structure, I will stick to returning the child if it's not home, but assume we want the nav bar on all of them.

    // Better approach: Use IndexedStack for state preservation, OR just conditional rendering but we need the BottomNav visible.

    if (child is Scaffold) {
      // Allow the child scaffold to define body/appbar, but override bottomNavigationBar
      return Scaffold(
        appBar: child.appBar,
        body: child.body,
        floatingActionButton: child.floatingActionButton,
        bottomNavigationBar: BottomNav(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
