import 'package:wowcare/data/features/user_profile/models/guardian_profile_model.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart'
    show StaffProfileAddress;
import 'package:wowcare/domain/features/user_profile/entities/guardian_profile.dart';

GuardianProfile guardianProfileFromModel(GuardianProfileModel model) {
  final fullName = model.fullName.isNotEmpty
      ? model.fullName
      : '${model.firstName} ${model.lastName}'.trim();

  return GuardianProfile(
    code: model.code,
    firstName: model.firstName,
    lastName: model.lastName,
    fullName: fullName,
    email: model.email,
    phoneNumber: model.phoneNumber,
    address: StaffProfileAddress(
      street: model.address.street,
      line2: model.address.line2,
      city: model.address.city,
      state: model.address.state,
      zipCode: model.address.zipCode,
      country: model.address.country,
    ),
    photoAssetCode: model.photoAssetCode,
    photoUrl: model.photoUrl,
  );
}
