# M01 Authentication and Kiosk — design to code

Eleven phone screens: the sign-in lane `1a`–`1f`, and the kiosk `2a`–`2e`.
Sources are on `develop`, under `lib/presentation/features/`.

## The sign-in lane

| ID | Design title | Screen here | Cubit | Existing source | Role gate |
|---|---|---|---|---|---|
| 1a | Sign in, four live states | `presentation/pages/sign_in_page.dart` | `SignInCubit` | `auth/view/sign_in_screen.dart`, `auth/widget/sign_in_form.dart`, `LoginUseCase` | none |
| 1b | Organization scope | `presentation/pages/choose_organization_page.dart` | `SignInCubit` | `auth/view/org_selection_screen.dart`, `AuthCubit.loadOrganizationNames` | none |
| 1c | School scope, locked row | `presentation/pages/choose_school_page.dart` | `SignInCubit` | `auth/view/school_selection_screen.dart`, `AuthCubit.loadSchoolsForOrg` | none |
| 1d | Forgot password | `presentation/pages/forgot_password_page.dart` | `ForgotPasswordCubit` | `auth/view/forgot_password_screen.dart`, `ForgotPasswordUseCase` | none |
| 1e | Check your email | `presentation/pages/check_email_page.dart` | `ForgotPasswordCubit` | same screen's success state | none |
| 1f | Set new password | `presentation/pages/reset_password_page.dart` | `ResetPasswordCubit` | `auth/view/change_password_screen.dart` | none |

## The kiosk

| ID | Design title | Screen here | Cubit | Existing source | Role gate |
|---|---|---|---|---|---|
| 2a | QR scanner | `presentation/pages/kiosk_scanner_page.dart` | `KioskScannerCubit` | `dashboard/view/QR_Code_scanner.dart`, `cubit/qr_validation_cubit.dart` | signed in |
| 2b | The door screen | `presentation/pages/kiosk_door_page.dart` | `KioskCubit` | `kiosk/view/kiosk_dashboard_screen.dart`, `widgets/kiosk_qr_section_widget.dart`, `kiosk_pin_pad_widget.dart`, `GetActiveKioskQrUseCase`, `VerifyKioskPinUseCase` | kiosk lockdown |
| 2c | Mixed siblings, multi-select | `presentation/pages/kiosk_family_page.dart` | `KioskFamilyCubit` | `kiosk/widgets/kiosk_sign_in_and_sign_out.dart`, `kiosk_attendance_cubit_v2.dart` | kiosk lockdown |
| 2d | Mixed siblings ask first | `presentation/pages/kiosk_choice_page.dart` | none, it is a fork | same widget's two-key state | kiosk lockdown |
| 2e | The QR's four states | the panel inside 2b, `presentation/widgets/kiosk_qr_panel.dart` | `KioskCubit` | `kiosk_dashboard_cubit.dart`'s QR states | kiosk lockdown |

## Out of scope

`_split/modules.json` marks these `costly`, so they are not built:

- A remaining-attempts or lockout message on 1a. Login returns a generic
  failure and nothing else, which is why `SignInResult` has three cases.
- Student and staff counts on the school picker, and a school count per
  organization. `getSchoolNamesByOrg` returns a code and a name.

Reading the kiosk QR from a signed-in phone is on the `costly` list but was
approved directly in Aug 2026, so 2a is built.

## Added, because the fixtures have no inbox

1e carries one link the frame does not draw, "Already have the link? Set new
password", so the reviewer can reach 1f without a real email. It is the only
copy in this module that is not the design's own.
