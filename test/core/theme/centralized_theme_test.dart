import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_themes.dart';

/// Guards the invariant that makes `lib/core/theme/app_theme_config.dart` the
/// single control point for the app's colours and fonts: no other file in
/// `lib/` may name a colour or a font family of its own.
///
/// If one of these fails, the fix is to add (or reuse) a token in the config
/// file and reference it, not to relax the test.
void main() {
  /// Every `.dart` file under `lib/`, paired with its source, with the theme
  /// definitions themselves excluded — those are where the values live.
  final List<({String path, String source})> sources =
      <({String path, String source})>[
        for (final FileSystemEntity e in Directory(
          'lib',
        ).listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart'))
            if (!e.path.startsWith('lib/core/theme/'))
              (path: e.path, source: e.readAsStringSync()),
      ];

  /// Blanks out `//`, `///` and `/* */` comments, preserving line numbers, so
  /// the scans below only look at code. Prose is free to mention `Colors.red`.
  String stripComments(String text) {
    final List<String> out = text.split('');
    int i = 0;
    String? quote;
    while (i < text.length) {
      final String ch = text[i];
      if (quote != null) {
        if (ch == r'\') {
          i += 2;
          continue;
        }
        if (ch == quote) quote = null;
        i++;
        continue;
      }
      if (ch == "'" || ch == '"') {
        quote = ch;
        i++;
        continue;
      }
      if (ch == '/' && i + 1 < text.length && text[i + 1] == '/') {
        int j = text.indexOf('\n', i);
        if (j == -1) j = text.length;
        for (int k = i; k < j; k++) {
          out[k] = ' ';
        }
        i = j;
        continue;
      }
      if (ch == '/' && i + 1 < text.length && text[i + 1] == '*') {
        int j = text.indexOf('*/', i);
        j = j == -1 ? text.length : j + 2;
        for (int k = i; k < j; k++) {
          if (out[k] != '\n') out[k] = ' ';
        }
        i = j;
        continue;
      }
      i++;
    }
    return out.join();
  }

  /// `path:line` for every line of code matching [pattern].
  List<String> offenders(RegExp pattern) => <String>[
    for (final ({String path, String source}) f in sources)
      ...() {
        final List<String> lines = stripComments(f.source).split('\n');
        return <String>[
          for (int i = 0; i < lines.length; i++)
            if (pattern.hasMatch(lines[i])) '${f.path}:${i + 1}',
        ];
      }(),
  ];

  group('fonts are centralised', () {
    test('no file names a font family directly', () {
      // The families registered in pubspec.yaml. Product code must reach them
      // through AppFonts (a role) or AppFontFamilies (a specific family).
      final List<String> found = offenders(
        RegExp(
          "['\"](Manrope|Poppins|Inter|Imperial_Script|MervaleScript"
          "|monospace)['\"]",
        ),
      );
      expect(
        found,
        isEmpty,
        reason:
            'Font families belong to AppFonts / AppFontFamilies in '
            'lib/core/theme/app_theme_config.dart. Use AppFonts.body, '
            '.display, .script or .mono instead of a bare string at:\n'
            '${found.join('\n')}',
      );
    });

    test('the active skin picks a family that pubspec actually bundles', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String family in <String>[
        AppFonts.body,
        AppFonts.display,
        AppFonts.numeric,
        AppFonts.script,
        AppFonts.scriptAlt,
      ]) {
        expect(
          pubspec,
          contains('- family: $family'),
          reason:
              '$family is not registered in pubspec.yaml, so Flutter '
              'would silently fall back to the platform font.',
        );
      }
    });

    test('ThemeData and AppTextStyles both follow the switch', () {
      expect(lightTheme.textTheme.titleLarge?.fontFamily, AppFonts.body);
      expect(darkTheme.textTheme.titleLarge?.fontFamily, AppFonts.body);
      expect(AppTextStyles.title.fontFamily, AppFonts.body);
      expect(AppTextStyles.body.fontFamily, AppFonts.body);
    });
  });

  group('colours are centralised', () {
    test("no file reaches into Flutter's Colors palette", () {
      // Colors.transparent is exempt: it is the absence of a colour, so it
      // means the same thing under every skin and no token can improve on it.
      final List<String> found = offenders(
        RegExp(r'(?<![A-Za-z0-9_.])Colors\.(?!transparent)'),
      );
      expect(
        found,
        isEmpty,
        reason:
            "Flutter's Colors.* swatches tie the app's look to Material "
            'defaults, and its shades are not const. Use a role from '
            'AppPalette, a token from AppColors, or — to keep an exact '
            'Material shade — MaterialHues, at:\n${found.join('\n')}',
      );
    });

    test('AppColors semantic tokens resolve to AppPalette roles', () {
      expect(AppColors.themeColor, AppPalette.brand);
      expect(AppColors.primaryColor, AppPalette.textPrimary);
      expect(AppColors.secondaryColor, AppPalette.brandSecondary);
      expect(AppColors.cardColor, AppPalette.surfaceCard);
      expect(AppColors.pageBackgroundColor, AppPalette.surfacePage);
      expect(AppColors.errorColor, AppPalette.statusError);
      expect(AppColors.warningColor, AppPalette.statusWarning);
      expect(AppColors.successColor, AppPalette.statusSuccess);
      expect(AppColors.accentColor, AppPalette.actionHighlight);
      expect(AppColors.dividerColor, AppPalette.divider);
      expect(AppColors.fieldBackgroundColor, AppPalette.surfaceField);
      expect(AppColors.primaryGradientColors, AppPalette.gradientPrimary);
      expect(AppColors.secondaryGradientColors, AppPalette.gradientSecondary);
      expect(AppColors.scaffoldGradientColors, AppPalette.gradientPage);
      expect(AppColors.pinkGradientColors, AppPalette.gradientPink);
    });

    test('generated themes are driven by the palette', () {
      expect(lightTheme.primaryColor, AppPalette.brand);
      expect(darkTheme.primaryColor, AppPalette.brand);
      expect(lightTheme.textTheme.bodyMedium?.color, AppPalette.textPrimary);
    });

    test(
      'MaterialHues values match the Material swatches they stand in for',
      () {
        // These constants exist only to hold an exact Material value in a const
        // context. If Flutter ever changes a swatch, this catches the drift.
        //
        // Compared by ARGB rather than by identity: a bare swatch such as
        // `Colors.grey` is a MaterialColor, so `equals` would fail on the type
        // even when the rendered value is the same.
        void sameValue(Color token, Color swatch) =>
            expect(token.toARGB32(), swatch.toARGB32());

        sameValue(MaterialHues.grey50, Colors.grey.shade50);
        sameValue(MaterialHues.grey100, Colors.grey.shade100);
        sameValue(MaterialHues.grey200, Colors.grey.shade200);
        sameValue(MaterialHues.grey300, Colors.grey.shade300);
        sameValue(MaterialHues.grey400, Colors.grey.shade400);
        sameValue(MaterialHues.grey500, Colors.grey);
        sameValue(MaterialHues.grey600, Colors.grey.shade600);
        sameValue(MaterialHues.grey700, Colors.grey.shade700);
        sameValue(MaterialHues.grey800, Colors.grey.shade800);
        sameValue(MaterialHues.black87, Colors.black87);
        sameValue(MaterialHues.black54, Colors.black54);
        sameValue(MaterialHues.black26, Colors.black26);
        sameValue(MaterialHues.black12, Colors.black12);
        sameValue(MaterialHues.white70, Colors.white70);
        sameValue(MaterialHues.white38, Colors.white38);
        sameValue(MaterialHues.white24, Colors.white24);
        sameValue(MaterialHues.red, Colors.red);
        sameValue(MaterialHues.red50, Colors.red.shade50);
        sameValue(MaterialHues.red100, Colors.red.shade100);
        sameValue(MaterialHues.red200, Colors.red.shade200);
        sameValue(MaterialHues.red600, Colors.red.shade600);
        sameValue(MaterialHues.red700, Colors.red.shade700);
        sameValue(MaterialHues.redAccent, Colors.redAccent);
        sameValue(MaterialHues.redAccent100, Colors.redAccent.shade100);
        sameValue(MaterialHues.green, Colors.green);
        sameValue(MaterialHues.greenAccent100, Colors.greenAccent.shade100);
        sameValue(MaterialHues.lightGreen, Colors.lightGreen);
        sameValue(MaterialHues.orange, Colors.orange);
        sameValue(MaterialHues.orange50, Colors.orange.shade50);
        sameValue(MaterialHues.orange100, Colors.orange.shade100);
        sameValue(MaterialHues.orange800, Colors.orange.shade800);
        sameValue(MaterialHues.deepOrange, Colors.deepOrange);
        sameValue(MaterialHues.blue, Colors.blue);
        sameValue(MaterialHues.blue50, Colors.blue.shade50);
        sameValue(MaterialHues.blue400, Colors.blue.shade400);
        sameValue(MaterialHues.lightBlue, Colors.lightBlue);
        sameValue(MaterialHues.blueGrey, Colors.blueGrey);
        sameValue(MaterialHues.blueGrey700, Colors.blueGrey.shade700);
        sameValue(MaterialHues.indigo, Colors.indigo);
        sameValue(MaterialHues.purple, Colors.purple);
        sameValue(MaterialHues.deepPurple, Colors.deepPurple);
        sameValue(MaterialHues.pink, Colors.pink);
        sameValue(MaterialHues.teal, Colors.teal);
        sameValue(MaterialHues.cyan, Colors.cyan);
        sameValue(MaterialHues.amber, Colors.amber);
        sameValue(MaterialHues.yellow, Colors.yellow);
        sameValue(MaterialHues.brown, Colors.brown);
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // The flat skeuomorphic re-skin — see docs/redesign-flat-skeu-plan.md
  // ═════════════════════════════════════════════════════════════════════════

  /// Every `.dart` file under `lib/`, the theme *definitions* included. Used
  /// by the colour-literal scan, which allows literals only in
  /// `app_theme_config.dart` itself.
  final List<({String path, String source})> allSources =
      <({String path, String source})>[
        for (final FileSystemEntity e in Directory(
          'lib',
        ).listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart'))
            if (e.path != 'lib/core/theme/app_theme_config.dart')
              (path: e.path, source: e.readAsStringSync()),
      ];

  /// `path` for every file with a line of code matching [pattern].
  Set<String> filesMatching(
    RegExp pattern,
    List<({String path, String source})> from,
  ) => <String>{
    for (final ({String path, String source}) f in from)
      if (stripComments(f.source).split('\n').any(pattern.hasMatch)) f.path,
  };

  /// Reports an allowlist that is out of date in either direction: files that
  /// still offend but are not listed (a regression), and files that no longer
  /// offend but are still listed (a module finished — delete its entries).
  void expectAllowlist({
    required Set<String> offending,
    required Set<String> allowed,
    required String rule,
    required String fix,
  }) {
    final List<String> unlisted = (offending.difference(allowed)).toList()
      ..sort();
    final List<String> stale = (allowed.difference(offending)).toList()..sort();
    expect(
      unlisted,
      isEmpty,
      reason: '$rule\n$fix\nNot on the allowlist:\n${unlisted.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'These files are clean now. Delete them from the allowlist so it '
          'keeps ratcheting:\n${stale.join('\n')}',
    );
  }

  group('the app is flat: no gradients', () {
    /// The 97 files outside `lib/core/theme/` that still draw a gradient,
    /// either directly or through one of the `AppColors.build*Gradient()`
    /// helpers.
    ///
    /// **This list only ever shrinks.** A module is not done while any of its
    /// files are still on it; the last module to land deletes the helpers in
    /// `app_colors.dart` and this list with them.
    const Set<String> knownGradientFiles = <String>{
      'lib/presentation/features/activities/view/view_activity_screens/show_full_screen_media.dart',
      'lib/presentation/features/activities/widgets/avtivity_media_preview.dart',
      'lib/presentation/features/activities/widgets/school_cloud_image_uploader_dialog.dart',
      'lib/presentation/features/activities/widgets/upload_photo_video.dart',
      'lib/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart',
      'lib/presentation/features/attendance/view/staff_attendance_tabbed_view.dart',
      'lib/presentation/features/attendance/widgets/attendance_popup.dart',
      'lib/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart',
      'lib/presentation/features/auth/view/change_password_screen.dart',
      'lib/presentation/features/auth/view/forgot_password_screen.dart',
      'lib/presentation/features/auth/view/org_selection_screen.dart',
      'lib/presentation/features/auth/view/school_selection_screen.dart',
      'lib/presentation/features/auth/view/sign_in_screen.dart',
      'lib/presentation/features/billing/view/auto_pay_payment_methods_screen.dart',
      'lib/presentation/features/billing/view/create_invoice_screen.dart',
      'lib/presentation/features/billing/view/parent_billing_screen.dart',
      'lib/presentation/features/billing/view/pay_now_amount_screen.dart',
      'lib/presentation/features/billing/view/pay_now_authorize_screen.dart',
      'lib/presentation/features/billing/view/select_students_screen.dart',
      'lib/presentation/features/billing/view/selected_students_receipt_screen.dart',
      'lib/presentation/features/billing/view/transactions/add_credit_screen.dart',
      'lib/presentation/features/billing/view/transactions/receive_payment_issue_refund_screen.dart',
      'lib/presentation/features/billing/view/transactions/send_invoice_screen.dart',
      'lib/presentation/features/billing/view/transactions/view_invoice_screen.dart',
      'lib/presentation/features/billing/widgets/analytics/analytics_section.dart',
      'lib/presentation/features/billing/widgets/auto_pay_token_webview.dart',
      'lib/presentation/features/billing/widgets/billing_settings/discount_card.dart',
      'lib/presentation/features/billing/widgets/billing_settings/discounts_section.dart',
      'lib/presentation/features/billing/widgets/billing_student_card.dart',
      'lib/presentation/features/billing/widgets/billing_student_vertical_popup.dart',
      'lib/presentation/features/billing/widgets/general_ledger/ledger_card.dart',
      'lib/presentation/features/billing/widgets/staff_style_card.dart',
      'lib/presentation/features/billing/widgets/transactions/billing_transaction_card.dart',
      'lib/presentation/features/classroom/view/classroom_tab_cards/classroom_staff_tab_card.dart',
      'lib/presentation/features/classroom/view/classroom_tab_cards/classroom_students_tab_card.dart',
      'lib/presentation/features/communication/bulk_messaging/view/message_composition_bulk_messaging.dart',
      'lib/presentation/features/communication/bulk_messaging/view/staff_or_student_selection_bulk_messaging.dart',
      'lib/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart',
      'lib/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart',
      'lib/presentation/features/communication/presentation/messaging/widgets/communication_launcher_button.dart',
      'lib/presentation/features/communication/presentation/messaging/widgets/messaging_input_area.dart',
      'lib/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart',
      'lib/presentation/features/communication/shared/widgets/chat_input_bar_input_row.dart',
      'lib/presentation/features/communication/shared/widgets/message_bubble_widget.dart',
      'lib/presentation/features/communication/shared/widgets/new_messages_indicator.dart',
      'lib/presentation/features/dashboard/view/qr_code_scanner.dart',
      'lib/presentation/features/dashboard/widgets/billing_card.dart',
      'lib/presentation/features/dashboard/widgets/dashboard_card_toggle.dart',
      'lib/presentation/features/dashboard/widgets/my_childs_day_card.dart',
      'lib/presentation/features/dashboard/widgets/my_day_card.dart',
      'lib/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart',
      'lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart',
      'lib/presentation/features/kiosk/widgets/kiosk_pin_pad_widget.dart',
      'lib/presentation/features/newsletter/widgets/newsletter_color_theme.dart',
      'lib/presentation/features/newsletter/widgets/newsletter_media_preview_overlay.dart',
      'lib/presentation/features/newsletter/widgets/newsletter_recipient_badge.dart',
      'lib/presentation/features/notifications/view/notification_center_screen.dart',
      'lib/presentation/features/reports/view/generated_reports_screen.dart',
      'lib/presentation/features/reports/widgets/generated_report_card.dart',
      'lib/presentation/features/reports/widgets/report_card.dart',
      'lib/presentation/features/reports/widgets/report_form_layout.dart',
      'lib/presentation/features/scheduling/view/add_shift_screen.dart',
      'lib/presentation/features/scheduling/view/edit_shift_screen.dart',
      'lib/presentation/features/scheduling/view/staff_scheduling_screen.dart',
      'lib/presentation/features/staff/view/add_staff_screen.dart',
      'lib/presentation/features/staff/view/edit_profile_details_screen.dart',
      'lib/presentation/features/staff/view/edit_schedule_screen.dart',
      'lib/presentation/features/staff/view/staff_profile_screen.dart',
      'lib/presentation/features/staff/widgets/staff_action_panel.dart',
      'lib/presentation/features/staff/widgets/staff_card.dart',
      'lib/presentation/features/staff/widgets/staff_dates_tab.dart',
      'lib/presentation/features/staff/widgets/staff_documents_tab.dart',
      'lib/presentation/features/staff/widgets/staff_form_layout.dart',
      'lib/presentation/features/staff/widgets/staff_profile_tab.dart',
      'lib/presentation/features/students/view/add_physician_screen.dart',
      'lib/presentation/features/students/view/add_pickup_screen.dart',
      'lib/presentation/features/students/view/add_student_step1_screen.dart',
      'lib/presentation/features/students/view/add_student_step2_screen.dart',
      'lib/presentation/features/students/view/add_student_step3_screen.dart',
      'lib/presentation/features/students/view/edit_student_profile_details_screen.dart',
      'lib/presentation/features/students/view/student_health_tab_cards/student_dates_tab_card.dart',
      'lib/presentation/features/students/view/student_health_tab_cards/student_health_tab_card.dart',
      'lib/presentation/features/students/view/student_profile_screen.dart',
      'lib/presentation/features/students/view/student_profile_screen_tabs/student_documents_tab.dart',
      'lib/presentation/features/students/view/student_profile_screen_tabs/student_health_tab.dart',
      'lib/presentation/features/students/view/student_profile_screen_tabs/student_important_dates_tab.dart',
      'lib/presentation/features/students/widgets/same_last_name_siblings_dialog.dart',
      'lib/presentation/features/students/widgets/student_action_panel.dart',
      'lib/presentation/features/students/widgets/student_card.dart',
      'lib/presentation/features/user_profile/view/edit_user_profile_screen.dart',
      'lib/presentation/features/user_profile/view/notification_settings_screen.dart',
      'lib/presentation/features/user_profile/view/user_profile_screen.dart',
      'lib/shared/common/view/coming_soon_screen.dart',
      'lib/shared/common/view/document_viewer_screen.dart',
      'lib/shared/common/widgets/custom_chip.dart',
      'lib/shared/common/widgets/gradient_background.dart',
    };

    test('no file outside the allowlist draws a gradient', () {
      expectAllowlist(
        offending: filesMatching(
          RegExp(
            r'(?<![A-Za-z0-9_])(LinearGradient|RadialGradient|SweepGradient'
            r'|ShaderMask|build(Scaffold|Primary|Secondary|Pink|Staff)Gradient'
            r'|[a-zA-Z]*GradientColors)(?![A-Za-z0-9_])',
          ),
          sources,
        ),
        allowed: knownGradientFiles,
        rule:
            'Rule 3 of the design language: no gradients anywhere. Depth '
            'comes from the bevel, the well, the rim and the ambient '
            'shadow.',
        fix:
            'Swap the decoration for an AppSurfaces builder — card(), '
            'well(), key(), impact() — rather than adding a file here.',
      );
    });

    test('the gradient roles themselves are two identical stops', () {
      for (final MapEntry<String, List<Color>> role in <String, List<Color>>{
        'gradientPage': AppPalette.gradientPage,
        'gradientPrimary': AppPalette.gradientPrimary,
        'gradientSecondary': AppPalette.gradientSecondary,
        'gradientPink': AppPalette.gradientPink,
      }.entries) {
        expect(
          role.value.toSet(),
          hasLength(1),
          reason:
              'AppPalette.${role.key} has more than one distinct stop, so '
              'every call site that draws it renders a gradient.',
        );
      }
    });
  });

  group('colour literals live in app_theme_config.dart', () {
    /// The 44 files that still declare a raw colour. Mostly the per-module
    /// decorative palettes `docs/theming.md` lists as a follow-up, plus
    /// `app_colors.dart`'s own feature-scoped one-offs.
    ///
    /// **This list only ever shrinks.**
    const Set<String> knownColourLiteralFiles = <String>{
      'lib/core/theme/app_colors.dart',
      'lib/core/utils/core_utils.dart',
      'lib/presentation/features/dashboard/widgets/availability_card.dart',
      'lib/presentation/features/dashboard/widgets/classroom_shifts_card.dart',
      'lib/presentation/features/dashboard/widgets/enrollment_card.dart',
      'lib/presentation/features/dashboard/widgets/my_attendance_card.dart',
      'lib/presentation/features/dashboard/widgets/my_shifts_card.dart',
      'lib/presentation/features/dashboard/widgets/ratio_monitoring_card.dart',
      'lib/presentation/features/dashboard/widgets/student_attendance_summary_card.dart',
      'lib/presentation/features/dashboard/widgets/student_billing_card.dart',
      'lib/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart',
      'lib/presentation/features/newsletter/widgets/newsletter_color_theme.dart',
      'lib/presentation/features/notifications/widgets/notification_card.dart',
      'lib/presentation/features/notifications/widgets/notification_category_style.dart',
      'lib/presentation/features/scheduling/model/scheduling_staff_shift_style.dart',
      'lib/presentation/features/scheduling/utils/scheduling_block_status_style.dart',
      'lib/presentation/features/scheduling/view/scheduling_screen.dart',
      'lib/presentation/features/scheduling/view/staff_scheduling_screen.dart',
      'lib/presentation/features/scheduling/view/view_shift_screen.dart',
      'lib/presentation/features/scheduling/widgets/day_classroom_section.dart',
      'lib/presentation/features/scheduling/widgets/day_gantt_table.dart',
      'lib/presentation/features/scheduling/widgets/scheduling_filter_bar.dart',
      'lib/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart',
      'lib/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart',
      'lib/presentation/features/scheduling/widgets/staff_schedule_tile.dart',
      'lib/presentation/features/staff/view/staff_screen.dart',
      'lib/presentation/features/staff/widgets/staff_action_panel.dart',
      'lib/presentation/features/staff/widgets/staff_action_panel_options.dart',
      'lib/presentation/features/staff/widgets/staff_dates_tab.dart',
      'lib/presentation/features/staff/widgets/staff_profile_tab.dart',
      'lib/shared/common/widgets/calendar_dialog.dart',
      'lib/shared/common/widgets/custom_multi_select_dropdown.dart',
      'lib/shared/common/widgets/custom_repeat_on_days_selector.dart',
      'lib/shared/common/widgets/custom_shimmer_loader.dart',
      'lib/shared/common/widgets/delete_confirmation_bottom_sheet.dart',
      'lib/shared/common/widgets/duplicate_student_bottom_sheet.dart',
      'lib/shared/common/widgets/hls_web_player.dart',
      'lib/shared/common/widgets/multi_selection_widget.dart',
      'lib/shared/common/widgets/photo_upload_progress_overlay.dart',
      'lib/shared/common/widgets/schedule_picker.dart',
      'lib/shared/common/widgets/select_dropdown_card.dart',
      'lib/shared/common/widgets/select_step_layout.dart',
      'lib/shared/common/widgets/upcoming_move_widget.dart',
    };

    test('no new file declares a colour of its own', () {
      expectAllowlist(
        offending: filesMatching(
          RegExp(r'Color\(0x|Color\.fromRGBO|Color\.fromARGB'),
          allSources,
        ),
        allowed: knownColourLiteralFiles,
        rule:
            'Colours are defined once, in '
            'lib/core/theme/app_theme_config.dart.',
        fix:
            'Add a role to AppPalette (or a feature token to AppColors that '
            'points at one) and reference it.',
      );
    });
  });

  group('the brand skin is the flat skeuomorphic one', () {
    test('the page ground is the warm tray, not white', () {
      expect(AppPalette.surfacePage, BrandRamps.tray);
      expect(AppPalette.surfacePage, isNot(BrandRamps.white));
    });

    test('the brand role is pink; teal is domain colour, not chrome', () {
      expect(AppPalette.brand, BrandRamps.pink600);
      expect(AppPalette.brand, AppPalette.actionRecommended);
      expect(AppPalette.actionSecondary, BrandRamps.teal600);
    });

    test('the card face is cool and every input is a well', () {
      expect(AppPalette.surfaceCard, BrandRamps.card);
      expect(AppPalette.surfaceField, BrandRamps.well);
      expect(AppPalette.surfaceSunken, BrandRamps.sub);
    });

    test('pure white is retired: ink on a dark face is warm white', () {
      expect(AppPalette.textOnDark, BrandRamps.warmWhite);
      expect(AppPalette.onBrand, BrandRamps.warmWhite);
    });
  });
}
