import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const UnicornApp());
}

class UnicornApp extends StatelessWidget {
  const UnicornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unicorn Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800), // Orange Juice
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7F0), // Very light orange tint
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final data = await _supabase
          .from('vehicles')
          .select()
          .eq('status', 'available')
          .order('id');
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAvailability(String vehicleId) async {
    // Demo: Check next 3 days
    final now = DateTime.now();
    final next3Days = now.add(const Duration(days: 3));

    try {
      final response = await _supabase.functions.invoke(
        'check-availability',
        body: {
          'vehicle_id': vehicleId,
          'pickup_at': now.toIso8601String(),
          'return_at': next3Days.toIso8601String(),
        },
      );

      final data = response.data;
      if (data['available'] == true) {
        _showDialog('✅ Available!', 'Ready for NAM SOM trip!');
      } else {
        _showDialog('❌ Reserved', 'Vehicle is busy.');
      }
    } catch (e) {
      _showDialog('Error', e.toString());
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fresh Ride 🍊',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      Text(
                        'Find your perfect juice... I mean car!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            return _buildCarCard(_vehicles[index]);
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> vehicle) {
    final currency = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Stack(
        children: [
          // Card Container
          Hero(
            tag: 'car_${vehicle['id']}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                image: DecorationImage(
                  image: NetworkImage(
                    vehicle['image_url'] ?? 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),

          // Glassmorphism Overlay
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${vehicle['brand']} ${vehicle['model']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${vehicle['year']}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Text(
                            currency.format(vehicle['price_per_day']),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkAvailability(vehicle['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Check Availability'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
