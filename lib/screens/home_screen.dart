import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math'; // Dodaj import biblioteki dart:math

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  List<CelestialObject> _celestialObjects = []; // Inicjalizacja pustej listy

  List<vm.Vector3> _accelerometerReadings = [];
  List<vm.Vector3> _magnetometerReadings = [];

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _fetchIssData();
    _listenToSensors();
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

  void _listenToSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerReadings.add(vm.Vector3(event.x, event.y, event.z));
      if (_accelerometerReadings.length > 10) {
        _accelerometerReadings.removeAt(0);
      }
      _processSensorData();
    });

    magnetometerEvents.listen((MagnetometerEvent event) {
      _magnetometerReadings.add(vm.Vector3(event.x, event.y, event.z));
      if (_magnetometerReadings.length > 10) {
        _magnetometerReadings.removeAt(0);
      }
      _processSensorData();
    });
  }

  void _processSensorData() {
    if (_accelerometerReadings.isNotEmpty && _magnetometerReadings.isNotEmpty) {
      final accelerometerVector = _averageVector(_accelerometerReadings);
      final magnetometerVector = _averageVector(_magnetometerReadings);

      final rotationMatrix =
          _calculateRotationMatrix(accelerometerVector, magnetometerVector);
      final eulerAngles = _getEulerAngles(rotationMatrix);

      // Oblicz pozycję ISS na ekranie na podstawie kątów Eulera
      final issPosition = vm.Vector3(
        eulerAngles.y * 100,
        eulerAngles.x * 100,
        -10,
      );

      setState(() {
        _celestialObjects = [
          CelestialObject(
            name: 'ISS',
            position: issPosition,
          ),
        ];
      });
    }
  }

  vm.Matrix3 _calculateRotationMatrix(
      vm.Vector3 accelerometer, vm.Vector3 magnetometer) {
    final R = vm.Matrix3.zero();

    final H = accelerometer.cross(magnetometer);
    final normH = H.normalized();

    final N = accelerometer.cross(normH);
    final normN = N.normalized();

    final normAccelerometer = accelerometer.normalized();

    R.setColumn(0, normN);
    R.setColumn(1, normH);
    R.setColumn(2, normAccelerometer);

    return R;
  }

  vm.Vector3 _getEulerAngles(vm.Matrix3 rotationMatrix) {
    final pitch = asin(-rotationMatrix.entry(2, 0));
    final roll = atan2(rotationMatrix.entry(2, 1), rotationMatrix.entry(2, 2));
    final yaw = atan2(rotationMatrix.entry(1, 0), rotationMatrix.entry(0, 0));

    return vm.Vector3(pitch, roll, yaw);
  }

  vm.Vector3 _averageVector(List<vm.Vector3> vectors) {
    if (vectors.isEmpty) {
      return vm.Vector3.zero();
    }

    final sum = vm.Vector3.zero();
    for (final vector in vectors) {
      sum.add(vector);
    }

    return sum / vectors.length.toDouble();
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