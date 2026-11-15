import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

typedef LocationResult = ({
  double latitude,
  double longitude,
  String? kecamatan,
  String? kota,
});

class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;
}

const _indigo = Color(0xFF1A237E);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(MyApp(textTheme: GoogleFonts.poppinsTextTheme(ThemeData().textTheme)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.loadLocation = _readLocation, this.textTheme});

  final Future<LocationResult> Function() loadLocation;
  final TextTheme? textTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokasi Saya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _indigo, textTheme: textTheme),
      home: LocationScreen(loadLocation: loadLocation),
    );
  }
}

Future<LocationResult> _readLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationFailure(
      'Layanan lokasi tidak aktif. Aktifkan GPS, lalu coba lagi.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationFailure(
      'Izin lokasi ditolak permanen. Ubah izin di pengaturan aplikasi.',
    );
  }
  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    throw const LocationFailure('Izin lokasi ditolak. Izinkan akses lokasi.');
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  ).timeout(const Duration(seconds: 15));
  if (placemarks.isEmpty) {
    throw const LocationFailure('Informasi alamat tidak ditemukan.');
  }

  final address = placemarks.first;
  return (
    latitude: position.latitude,
    longitude: position.longitude,
    kecamatan: address.subLocality,
    kota: address.subAdministrativeArea,
  );
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.loadLocation});

  final Future<LocationResult> Function() loadLocation;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;
  String? _kecamatan;
  String? _kota;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _kecamatan = null;
      _kota = null;
      _latitude = null;
      _longitude = null;
    });

    LocationResult? result;
    String? error;
    try {
      result = await widget.loadLocation();
    } on LocationFailure catch (failure) {
      error = failure.message;
    } on TimeoutException {
      error = 'Pengambilan lokasi terlalu lama. Coba lagi.';
    } on Exception {
      error = 'Lokasi atau alamat gagal diperoleh. Coba lagi.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _kecamatan = result?.kecamatan;
          _kota = result?.kota;
          _latitude = result?.latitude;
          _longitude = result?.longitude;
          _errorMessage = error;
        });
      }
    }
  }

  String _addressLabel(String? value) {
    final label = value?.trim();
    return label == null || label.isEmpty ? 'Tidak tersedia' : label;
  }

  Widget _buildStatus() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(semanticsLabel: 'Sedang mengambil lokasi'),
          SizedBox(height: 16),
          Text('Sedang mengambil lokasi…'),
        ],
      );
    }
    if (_errorMessage case final message?) {
      return Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (_latitude == null) {
      return const Text(
        'Tekan tombol untuk menampilkan lokasi.',
        textAlign: TextAlign.center,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kelurahan/Kecamatan: ${_addressLabel(_kecamatan)}'),
        const SizedBox(height: 8),
        Text('Kota: ${_addressLabel(_kota)}'),
        const Divider(height: 24),
        Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
        Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Saya'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Semantics(
                            liveRegion: true,
                            child: _buildStatus(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _getLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0DFF0),
                          disabledForegroundColor: const Color(0xFF46536B),
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Tampilkan lokasi saat ini',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
