import 'package:equatable/equatable.dart';

class ActivityAssetPresign extends Equatable {
  const ActivityAssetPresign({
    required this.assetCode,
    required this.presignedPutUrl,
    required this.requiredHeaders,
  });

  final String assetCode;
  final String presignedPutUrl;
  final Map<String, String> requiredHeaders;

  @override
  List<Object?> get props => [assetCode, presignedPutUrl, requiredHeaders];
}

