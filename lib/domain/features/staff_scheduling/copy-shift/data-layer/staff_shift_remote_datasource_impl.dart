import '../../../../../core/network/api_client.dart';
import '../../../../../core/util/api_paths.dart';

import '../domain/copy_shift_params.dart';
import '../domain/copy_shift_response.dart';
import 'staff_shift_remote_datasource.dart';

class StaffShiftRemoteDataSourceImpl implements StaffShiftRemoteDataSource {
  final ApiClient apiClient;

  StaffShiftRemoteDataSourceImpl(this.apiClient);

  @override
  Future<CopyShiftResponse> copyShift(CopyShiftParams params) async {
    final response = await apiClient.client.post(
      ApiPaths.url(ApiPaths.copyShift),
      data: params.toJson(),
    );
    print(response);
    return CopyShiftResponse.fromJson(response.data['data']);
  }
}
