import 'package:dharma_police/core/api_service.dart';

/// AP Police hierarchy data from the backend (DB-backed, seeded from JSON).
class HierarchyApi {
  static final _dio = ApiService.dio;

  static Future<List<dynamic>> getDistricts() async {
    final r = await _dio.get('/police-hierarchy/districts');
    return r.data;
  }

  static Future<List<dynamic>> getSDPOs({String? district}) async {
    final params = <String, dynamic>{};
    if (district != null) params['district'] = district;
    final r = await _dio.get('/police-hierarchy/sdpos', queryParameters: params);
    return r.data;
  }

  static Future<List<dynamic>> getCircles({String? sdpo}) async {
    final params = <String, dynamic>{};
    if (sdpo != null) params['sdpo'] = sdpo;
    final r = await _dio.get('/police-hierarchy/circles', queryParameters: params);
    return r.data;
  }

  static Future<List<dynamic>> getStations({String? circle}) async {
    final params = <String, dynamic>{};
    if (circle != null) params['circle'] = circle;
    final r = await _dio.get('/police-hierarchy/stations', queryParameters: params);
    return r.data;
  }

  static Future<List<dynamic>> getPincodes({String? district}) async {
    final params = <String, dynamic>{};
    if (district != null) params['district'] = district;
    final r = await _dio.get('/police-hierarchy/pincodes', queryParameters: params);
    return r.data;
  }
}
