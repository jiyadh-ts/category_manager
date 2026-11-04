import 'package:equatable/equatable.dart';

class GeoLocation extends Equatable {
  const GeoLocation({
    required this.lat,
    required this.lng,
  });

  final String lat;
  final String lng;

  @override
  List<Object?> get props => [lat, lng];
}
