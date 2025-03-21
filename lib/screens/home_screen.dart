import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  List<CelestialObject> _celestialObjects = []; // Inicjalizacja pustej listy

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _fetchIssData();
  }

  Future<void> _fetchIssData() async {
    final response =
        await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final position = data['iss_position'];
      setState(() {
        _celestialObjects = [
          CelestialObject(
            name: 'ISS',
            position: vm.Vector3(
              double.parse(position['longitude']),
              double.parse(position['latitude']),
              -10,
            ),
          ),
        ];
      });
    } else {
      print('Failed to fetch ISS data');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa nieba'),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          ..._celestialObjects
              .map((object) => CelestialObjectWidget(object: object))
              .toList(),
        ],
      ),
    );
  }
}

class CelestialObject {
  final String name;
  final vm.Vector3 position;

  CelestialObject({required this.name, required this.position});
}

class CelestialObjectWidget extends StatelessWidget {
  final CelestialObject object;

  const CelestialObjectWidget({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: object.position.x + MediaQuery.of(context).size.width / 2,
      top: object.position.y + MediaQuery.of(context).size.height / 2,
      child: Text(
        object.name,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}