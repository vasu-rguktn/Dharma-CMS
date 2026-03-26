/// API service for AP Police Hierarchy data (districts, SDPOs, circles, stations, pincodes).
/// All data is fetched from the backend DB — NOT static JSON.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class PoliceHierarchyApi {
  PoliceHierarchyApi._();
  static Dio get _dio => ApiService.dio;

  static Future<List<dynamic>> listDistricts() async {
    final res = await _dio.get('/police-hierarchy/districts');
    return res.data;
  }

  static Future<List<dynamic>> listSdpos({String? district}) async {
    final params = <String, dynamic>{};
    if (district != null) params['district'] = district;
    final res = await _dio.get('/police-hierarchy/sdpos', queryParameters: params);
    return res.data;
  }

  static Future<List<dynamic>> listCircles({String? sdpo}) async {
    final params = <String, dynamic>{};
    if (sdpo != null) params['sdpo'] = sdpo;
    final res = await _dio.get('/police-hierarchy/circles', queryParameters: params);
    return res.data;
  }

  static Future<List<dynamic>> listStations({String? circle, String? district}) async {
    final params = <String, dynamic>{};
    if (circle != null) params['circle'] = circle;
    if (district != null) params['district'] = district;
    final res = await _dio.get('/police-hierarchy/stations', queryParameters: params);
    return res.data;
  }

  static Future<List<dynamic>> listPincodes({String? district, String? stationName}) async {
    final params = <String, dynamic>{};
    if (district != null) params['district'] = district;
    if (stationName != null) params['station_name'] = stationName;
    final res = await _dio.get('/police-hierarchy/pincodes', queryParameters: params);
    return res.data;
  }
}
