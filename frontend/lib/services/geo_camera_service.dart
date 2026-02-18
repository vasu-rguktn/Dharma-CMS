import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

/// Service for handling geolocation and permission management
class GeoCameraService {
  static final GeoCameraService _instance = GeoCameraService._internal();
  factory GeoCameraService() => _instance;
  GeoCameraService._internal();

  Position? _cachedPosition;
  String? _cachedAddress;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      // print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current GPS location with high accuracy
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Check if we have a recent cached position
      if (!forceRefresh &&
          _cachedPosition != null && 
          _cacheTime != null && 
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedPosition;
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        // print('Location services are disabled');
        return null;
      }

      // Check permission
      if (kIsWeb) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission();
          if (requested == LocationPermission.denied || 
              requested == LocationPermission.deniedForever) {
            // print('Location permission denied on web');
            return null;
          }
        }
      } else {
        final hasPermission = await hasLocationPermission();
        if (!hasPermission) {
          // print('Location permission not granted');
          return null;
        }
      }

      // Get current position with best accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      // Cache the position
      _cachedPosition = position;
      _cacheTime = DateTime.now();

      return position;
    } catch (e) {
      // print('Error getting location: $e');
      return null;
    }
  }

  /// Get address from coordinates using reverse geocoding
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // Intentionally removed simple caching here because we can't easily verify
      // if the cached address matches the Requested lat/lon without storing more state.
      // Relying on fresh fetch guarantees accuracy.

      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).toList();
        
        _cachedAddress = addressParts.join(', ');
        return _cachedAddress;
      }
      return null;
    } catch (e) {
      // print('Error getting address: $e');
      return null;
    }
  }

  /// Format location data into watermark text
  String formatLocationWatermark(Position position, String? address) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final timestamp = dateFormat.format(DateTime.now());
    
    final lat = position.latitude.toStringAsFixed(4);
    final lon = position.longitude.toStringAsFixed(4);
    
    final latDir = position.latitude >= 0 ? 'N' : 'S';
    final lonDir = position.longitude >= 0 ? 'E' : 'W';
    
    String watermark = '📍 $lat°$latDir, $lon°$lonDir\n📅 $timestamp';
    
    if (address != null && address.isNotEmpty) {
      watermark += '\n📌 $address';
    }
    
    return watermark;
  }

  /// Clear cached location data
  void clearCache() {
    _cachedPosition = null;
    _cachedAddress = null;
    _cacheTime = null;
  }
}
