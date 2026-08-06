import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TripSearchPage extends StatefulWidget {
  const TripSearchPage({super.key});

  @override
  State<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends State<TripSearchPage> {
  bool _loading = true;
  bool _searching = false;
  bool _loadingFromStops = false;
  bool _loadingToStops = false;
  List<dynamic> _trips = [];
  List<dynamic> _cities = [];
  List<dynamic> _fromStops = [];
  List<dynamic> _toStops = [];
  int? _fromCityId;
  int? _toCityId;
  int? _fromStopId;
  int? _toStopId;
  String? _fromCityName;
  String? _toCityName;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String> _ensureAuthToken() async {
    final token = await DioClient.getStoredToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again to load cities.');
    }

    await DioClient.setAuthToken(token);
    return token;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _trips = [];
    });

    try {
      await _ensureAuthToken();
      final citiesResponse = await DioClient.dio.get('/cities');
      setState(() {
        _cities = _extractListFromResponse(citiesResponse.data);
      });
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Unable to load city data. Please refresh.';
      setState(() {
        _loadError = message.toString();
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStopsForCity({required bool isFrom, required int cityId}) async {
    setState(() {
      if (isFrom) {
        _loadingFromStops = true;
        _fromStopId = null;
      } else {
        _loadingToStops = true;
        _toStopId = null;
      }
    });

    try {
      final response = await DioClient.dio.get('/cities/$cityId/stops');
      final stops = _extractListFromResponse(response.data);
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromStops = stops;
          _fromCityId = cityId;
        } else {
          _toStops = stops;
          _toCityId = cityId;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromStops = [];
          _fromCityId = cityId;
        } else {
          _toStops = [];
          _toCityId = cityId;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to load stops for that city.')));
    } finally {
      if (mounted) {
        setState(() {
          if (isFrom) {
            _loadingFromStops = false;
          } else {
            _loadingToStops = false;
          }
        });
      }
    }
  }

  List<dynamic> _extractListFromResponse(dynamic responseData) {
    if (responseData is List) {
      return List<dynamic>.from(responseData);
    }
    if (responseData is Map && responseData.containsKey('data')) {
      final data = responseData['data'];
      if (data is List) {
        return List<dynamic>.from(data);
      }
    }
    return [];
  }

  Future<void> _searchTrips() async {
    if (_fromStopId == null || _toStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose both your origin and destination.')));
      return;
    }

    setState(() {
      _searching = true;
      _trips = [];
    });
    try {
      final response = await DioClient.dio.get('/passenger-trips', queryParameters: {
        'from_stop_id': _fromStopId,
        'to_stop_id': _toStopId,
      });
      setState(() => _trips = response.data['data'] ?? []);
    } catch (_) {
      setState(() => _trips = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _fromStopId != null && _toStopId != null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_loadError!, style: AppTextStyles.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.route_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Plan your route', style: AppTextStyles.title),
                                      const SizedBox(height: 4),
                                      Text('Search available trips between your stops', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'From',
                              isFromCity: true,
                              cityValue: _fromCityId,
                              cityName: _fromCityName,
                              stopValue: _fromStopId,
                              stops: _fromStops,
                              loadingStops: _loadingFromStops,
                              onStopChanged: (stopId) => setState(() => _fromStopId = stopId),
                              cities: _cities,
                            ),
                            const SizedBox(height: 18),
                            _buildSection(
                              title: 'To',
                              isFromCity: false,
                              cityValue: _toCityId,
                              cityName: _toCityName,
                              stopValue: _toStopId,
                              stops: _toStops,
                              loadingStops: _loadingToStops,
                              onStopChanged: (stopId) => setState(() => _toStopId = stopId),
                              cities: _cities,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: canSearch && !_searching ? _searchTrips : null,
                                icon: _searching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
                                label: Text(_searching ? 'Searching...' : 'Search rides'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_trips.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_bus_outlined, size: 42, color: AppColors.primary),
                              const SizedBox(height: 16),
                              Text(canSearch ? 'No trips found yet' : 'Choose your route', style: AppTextStyles.title, textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              Text(canSearch ? 'We couldn’t find any active drivers for this route yet.' : 'Select departure and destination to see live trip options.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      else
                        ..._trips.map((trip) {
                          final currentLocation = trip['current_location'];
                          final nextStop = trip['next_stop'];
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary.withOpacity(0.16),
                                      child: const Icon(Icons.person, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${trip['driver_name']} • ${trip['vehicle_name']}', style: AppTextStyles.title),
                                          const SizedBox(height: 6),
                                          Text('${trip['from_city_name'] ?? ''} → ${trip['to_city_name'] ?? ''}', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text('Live', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _TripInfoChip(label: 'Next', value: nextStop?['display_name'] ?? 'Waiting'),
                                    _TripInfoChip(label: 'ETA', value: '${trip['eta_to_next_stop']} min'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text('Current', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(currentLocation?['display_name'] ?? 'Starting soon', style: AppTextStyles.body),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSection({
    required String title,
    required bool isFromCity,
    required int? cityValue,
    required String? cityName,
    required int? stopValue,
    required List<dynamic> stops,
    required bool loadingStops,
    required Function(int?) onStopChanged,
    required List<dynamic> cities,
  }) {
    final stopItems = stops.map<DropdownMenuItem<int?>>((stop) {
      final stopId = stop['id'];
      final stopLabel = stop['display_name']?.toString() ?? stop['address']?.toString() ?? 'Stop';
      final parsedId = stopId is int ? stopId : int.tryParse(stopId.toString());
      return DropdownMenuItem<int?>(
        value: parsedId,
        child: Text(stopLabel),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _buildCityAutocomplete(
          isFrom: isFromCity,
          cityName: cityName,
          cities: cities,
        ),
        const SizedBox(height: 10),
        if (cityValue == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text('Select a city to load stops'),
          )
        else
          DropdownButtonFormField<int?>(
            value: stopValue,
            decoration: const InputDecoration(
              labelText: 'Stop',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place_outlined),
            ),
            items: stopItems,
            onChanged: loadingStops ? null : onStopChanged,
            hint: Text(loadingStops ? 'Loading stops...' : 'Choose stop'),
            isExpanded: true,
          ),
      ],
    );
  }

  Widget _buildCityAutocomplete({
    required bool isFrom,
    required String? cityName,
    required List<dynamic> cities,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final typedCities = cities.cast<Map<String, dynamic>>();
        if (textEditingValue.text.isEmpty) {
          return typedCities;
        }

        final query = textEditingValue.text.toLowerCase();
        return typedCities.where((city) {
          final name = city['name']?.toString().toLowerCase() ?? '';
          return name.contains(query);
        });
      },
      displayStringForOption: (city) => city['name']?.toString() ?? '',
      fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
        final currentName = cityName ?? '';
        if (fieldTextEditingController.text != currentName) {
          fieldTextEditingController.text = currentName;
          fieldTextEditingController.selection = TextSelection.collapsed(offset: currentName.length);
        }

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'City',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_city),
            suffixIcon: fieldTextEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      fieldTextEditingController.clear();
                      setState(() {
                        if (isFrom) {
                          _fromCityId = null;
                          _fromCityName = null;
                          _fromStops = [];
                          _fromStopId = null;
                        } else {
                          _toCityId = null;
                          _toCityName = null;
                          _toStops = [];
                          _toStopId = null;
                        }
                      });
                    },
                  )
                : null,
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      onSelected: (city) {
        final cityId = city['id'] is int ? city['id'] as int : int.tryParse(city['id']?.toString() ?? '');
        if (cityId == null) return;

        setState(() {
          if (isFrom) {
            _fromCityId = cityId;
            _fromCityName = city['name']?.toString();
          } else {
            _toCityId = cityId;
            _toCityName = city['name']?.toString();
          }
        });

        _loadStopsForCity(isFrom: isFrom, cityId: cityId);
      },
    );
  }
}

class _TripInfoChip extends StatelessWidget {
  const _TripInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
