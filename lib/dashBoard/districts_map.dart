import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class DistrictsMapPage extends StatefulWidget {
  const DistrictsMapPage({super.key});

  @override
  State<DistrictsMapPage> createState() => _DistrictsMapPageState();
}

class _DistrictsMapPageState extends State<DistrictsMapPage> {
  bool _isLoading = true;
  List<dynamic> _mapData = [];

  @override
  void initState() {
    super.initState();
    _fetchMapData();
  }

  Future<void> _fetchMapData() async {
    try {
      final response = await ApiService.getDistrictsMapData();
      if (response.statusCode == 200) {
        setState(() {
          _mapData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching map data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Partner Districts Map", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        iconTheme: const IconThemeData(color: kBrandBrown, size: 20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
          : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-13.2543, 34.3015),
                initialZoom: 7.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ageafrica.scholar_management_system',
                ),
                MarkerLayer(
                  markers: _mapData.map((d) {
                    final double lat = (d['latitude'] as num).toDouble();
                    final double lng = (d['longitude'] as num).toDouble();
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showDistrictInfo(d),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kBrandBrown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d['scholarCount'].toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.location_on, color: kBrandOrange, size: 40),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  void _showDistrictInfo(dynamic d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.place_rounded, color: kBrandOrange),
            const SizedBox(width: 10),
            Text(d['district'], style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Program Impact Summary:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Total Scholars: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text(d['scholarCount'].toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            const Text("Active partnerships verified via GPS coordinates.", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
          ),
        ],
      ),
    );
  }
}
