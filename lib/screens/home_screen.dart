import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _issLongitude;
  double? _issLatitude;

  @override
  void initState() {
    super.initState();
    _fetchIssPosition();
  }

  Future<void> _fetchIssPosition() async {
    try {
      final response = await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _issLongitude = double.parse(data['iss_position']['longitude']);
          _issLatitude = double.parse(data['iss_position']['latitude']);
        });
      } else {
        print('Failed to fetch ISS data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ISS data: $e');
    }
    // Aktualizuj pozycję co kilka sekund
    Future.delayed(const Duration(seconds: 5), _fetchIssPosition);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double issX = screenWidth / 2;
    double issY = screenHeight / 2;

    if (_issLongitude != null && _issLatitude != null) {
      // Proste przybliżone przeliczenie (do dostosowania)
      issX = (screenWidth / 2) + (_issLongitude! / 180) * (screenWidth / 2);
      issY = (screenHeight / 2) - (_issLatitude! / 90) * (screenHeight / 2);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prosta Mapa Nieba'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Opcjonalnie: Tło nieba
          // Image.asset(
          //   'assets/sky_background.jpg', // Dodaj swój obraz do assets
          //   fit: BoxFit.cover,
          // ),
          if (_issLongitude != null && _issLatitude != null)
            Positioned(
              left: issX - 10, // Dostosuj rozmiar wskaźnika
              top: issY - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('ISS', style: TextStyle(color: Colors.white, fontSize: 8))),
              ),
            ),
          if (_issLongitude == null || _issLatitude == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}