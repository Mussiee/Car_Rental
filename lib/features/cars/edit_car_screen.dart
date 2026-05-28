import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/car.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';

class EditCarScreen extends StatefulWidget {
  final Car car;

  const EditCarScreen({super.key, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _locationCtrl;
  String _selectedFuelType = 'Gas';
  final List<String> _fuelTypes = ['Gas', 'Electric', 'Hybrid'];
  List<String> _selectedUsage = [];
  final List<String> _usageOptions = ['city', 'long distance', 'mountain'];
  XFile? _pickedFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.car.name);
    _typeCtrl = TextEditingController(text: widget.car.type);
    _priceCtrl = TextEditingController(text: widget.car.price.toString());
    _locationCtrl = TextEditingController(text: widget.car.location);
    _selectedUsage = List.from(widget.car.usage);
    _selectedFuelType = widget.car.fuelType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _typeCtrl.dispose(); _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _pickedFile = pickedFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Car Listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pickedFile != null
                      ? (kIsWeb ? Image.network(_pickedFile!.path, fit: BoxFit.cover) : Image.file(File(_pickedFile!.path), fit: BoxFit.cover))
                      : CachedNetworkImage(imageUrl: widget.car.image, key: ValueKey(widget.car.image), fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[100]), errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48))),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Car Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Car Type (e.g. Sedan, SUV)'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Price per Day', prefixText: '\$'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),
            const Text('Fuel Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _fuelTypes.map((fuel) {
              final isSelected = _selectedFuelType == fuel;
              return ChoiceChip(label: Text(fuel), selected: isSelected, onSelected: (_) => setState(() => _selectedFuelType = fuel));
            }).toList()),
            const Text('Best Use For (Usage)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _usageOptions.map((opt) {
              final isSelected = _selectedUsage.contains(opt);
              return FilterChip(label: Text(opt[0].toUpperCase() + opt.substring(1)), selected: isSelected, onSelected: (val) { setState(() { if (val) { _selectedUsage.add(opt); } else { _selectedUsage.remove(opt); } }); });
            }).toList()),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUsage.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one usage option'))); return; }
    setState(() => _isLoading = true);
    try {
      final firestore = context.read<FirestoreService>();
      final storage = StorageService();
      String imageUrl = widget.car.image;
      if (_pickedFile != null) {
        imageUrl = await storage.uploadImage(_pickedFile!, 'cars/${DateTime.now().millisecondsSinceEpoch}_${widget.car.ownerId}.jpg');
      }
      final updatedCar = Car(id: widget.car.id, ownerId: widget.car.ownerId, name: _nameCtrl.text.trim(), type: _typeCtrl.text.trim(), price: double.parse(_priceCtrl.text.trim()), rating: widget.car.rating, image: imageUrl, routeFitScore: widget.car.routeFitScore, fuelType: _selectedFuelType, suitable: widget.car.suitable, location: _locationCtrl.text.trim(), usage: _selectedUsage);
      await firestore.createCar(updatedCar);
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Car listing updated!'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
