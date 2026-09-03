import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/widgets.dart';

/// Every shared widget in every state, on one scrolling page.
///
/// Scaffolding, not a screen in the app: it is where a component gets
/// eyeballed against the Components page on a real device, and where a token
/// change is checked before it lands in a module. The copy here is sample
/// copy for the gallery, not app copy.
class WidgetGalleryPage extends StatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  State<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends State<WidgetGalleryPage> {
  int? _tab = 0;
  int _segment = 0;
  bool _toggle = true;
  int _radio = 0;
  bool _check = true;
  Set<String> _chips = <String>{'All'};
  Set<String> _tags = <String>{'Allergy'};
  String? _classroom;

  static const _tabs = <AppTabItem>[
    AppTabItem(icon: AppIcons.dashboard, label: AppStrings.dashboard),
    AppTabItem(icon: AppIcons.attendance, label: AppStrings.attendance),
    AppTabItem(icon: AppIcons.classrooms, label: AppStrings.classrooms),
    AppTabItem(icon: AppIcons.activities, label: AppStrings.activities),
    AppTabItem(
      icon: AppIcons.messages,
      label: AppStrings.messages,
      badgeCount: 7,
    ),
  ];

  static const _tagOptions = <SelectOption<String>>[
    SelectOption(value: 'Allergy', label: 'Allergy', subtitle: 'Medical'),
    SelectOption(value: 'Nap', label: 'Naps after lunch'),
    SelectOption(value: 'Pickup', label: 'Late pickup'),
    SelectOption(value: 'Photo', label: 'No photos', subtitle: 'Consent'),
  ];

  static const _classroomOptions = <SelectOption<String>>[
    SelectOption(
      value: 'Sunflower',
      label: 'Sunflower',
      subtitle: '18 students',
    ),
    SelectOption(value: 'Bluebell', label: 'Bluebell', subtitle: '14 students'),
    SelectOption(value: 'Maple', label: 'Maple', subtitle: '22 students'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return ScreenScaffold(
      header: AppHeaderBar.dashboard(
        title: 'Widget gallery',
        subline: 'Every component, every state',
        leading: IconKey(
          icon: AppIcons.menu,
          semanticLabel: AppStrings.openMenu,
          onTap: () => showAppToast(context, 'Menu key pressed'),
        ),
        actions: <Widget>[
          IconKey(
            icon: AppIcons.scanQr,
            semanticLabel: AppStrings.scanQr,
            onTap: () => showAppToast(context, 'Scan QR pressed'),
          ),
          IconKey(
            icon: AppIcons.bell,
            badgeCount: 7,
            semanticLabel: AppStrings.notifications,
            onTap: () => showAppToast(context, 'Bell pressed'),
          ),
        ],
      ),
      scrollable: true,
      fab: AppFab(onTap: () => showAppToast(context, 'FAB pressed')),
      bottomBar: AppTabBar(
        items: _tabs,
        selectedIndex: _tab,
        onSelect: (i) => setState(() => _tab = _tab == i ? null : i),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.space5,
        children: <Widget>[
          _section(c, 'Surfaces', _surfaces(c)),
          _section(c, 'Keys', _keys(c)),
          _section(c, 'Header bars', _headers()),
          _section(c, 'Section labels', _sectionLabels(c)),
          _section(c, 'Avatars and dots', _avatars(c)),
          _section(c, 'List rows', _rows(c)),
          _section(c, 'Pills and tiles', _pillsAndTiles(c)),
          _section(c, 'Troughs', _troughs(c)),
          _section(c, 'Fields', _fields(c)),
          _section(c, 'Choices', _choices(c)),
          _section(c, 'Switches', _switches(c)),
          _section(c, 'Feedback', _feedback(c)),
          _section(c, 'Sheets and toasts', _sheets(c)),
          _section(c, 'FAB states', _fabs()),
          _section(c, 'Kiosk pad', _pad()),
        ],
      ),
    );
  }

  Widget _section(Colourway c, String label, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSizes.sectionGap,
    children: <Widget>[
      SectionEyebrow(label: label, color: c.pink),
      ...children,
    ],
  );

  Widget _caption(Colourway c, String text) =>
      Text(text, style: AppTextStyles.rowSub.copyWith(color: c.ink3));

  // --- Sections -------------------------------------------------------------

  List<Widget> _surfaces(Colourway c) => <Widget>[
    AppCard(
      child: Text(
        'Card',
        style: AppTextStyles.cardTitle.copyWith(color: c.ink),
      ),
    ),
    AppCard(
      raised: true,
      onTap: () => showAppToast(context, 'Card tapped'),
      child: Text(
        'Raised card, tappable',
        style: AppTextStyles.cardTitle.copyWith(color: c.ink),
      ),
    ),
    AppCard(
      lineColor: c.dangerLine,
      child: Text(
        'Card with a danger line',
        style: AppTextStyles.cardTitle.copyWith(color: c.ink),
      ),
    ),
    AppWell(
      child: Text(
        'Well',
        style: AppTextStyles.fieldText.copyWith(color: c.ink3),
      ),
    ),
    const ImpactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('18 of 22 signed in', style: AppTextStyles.cardTitle),
          Text('Impact card', style: AppTextStyles.subLine),
        ],
      ),
    ),
    Row(
      spacing: AppSizes.tileGap,
      children: <Widget>[
        Expanded(
          child: AltWellTile(
            child: Text(
              'Alt-well tile',
              style: AppTextStyles.rowSub.copyWith(color: c.ink2),
            ),
          ),
        ),
        Expanded(
          child: AltWellTile(
            subtle: true,
            child: Text(
              'Subtle tile',
              style: AppTextStyles.rowSub.copyWith(color: c.ink2),
            ),
          ),
        ),
      ],
    ),
  ];

  List<Widget> _keys(Colourway c) => <Widget>[
    PrimaryKey(
      label: 'Primary key',
      onTap: () => showAppToast(context, 'Primary pressed'),
    ),
    PrimaryKey(
      label: 'With a glyph',
      icon: AppIcons.scanQr,
      onTap: () => showAppToast(context, 'Primary with glyph pressed'),
    ),
    const PrimaryKey(label: 'Signing in', isLoading: true),
    const PrimaryKey(label: 'Disabled key', enabled: false),
    Row(
      spacing: AppSizes.keyGap,
      children: <Widget>[
        Expanded(
          child: SecondaryKey(
            label: 'Secondary',
            onTap: () => showAppToast(context, 'Secondary pressed'),
          ),
        ),
        Expanded(
          child: DestructiveKey(
            label: 'Destructive',
            onTap: () => showAppToast(
              context,
              'Destructive pressed',
              tone: ToastTone.error,
            ),
          ),
        ),
      ],
    ),
    Row(
      spacing: AppSizes.keyGap,
      children: <Widget>[
        const BackKey(),
        IconKey(icon: AppIcons.search, onTap: () {}),
        IconKey(icon: AppIcons.filter, onTap: () {}),
        IconKey(icon: AppIcons.bell, badgeCount: 12, onTap: () {}),
        const IconKey(icon: AppIcons.moreHorizontal),
        const Spacer(),
        TextLink(label: AppStrings.viewAll, onTap: () {}),
      ],
    ),
    _caption(c, 'Back key 34, icon keys 38, the last one inert'),
  ];

  List<Widget> _headers() => <Widget>[
    AppCard(
      padding: EdgeInsets.zero,
      child: AppHeaderBar(
        title: AppStrings.students,
        leading: const BackKey(),
        actions: <Widget>[IconKey(icon: AppIcons.filter, onTap: () {})],
      ),
    ),
    AppCard(
      padding: EdgeInsets.zero,
      child: AppHeaderBar(
        title: 'Edit student',
        isDetail: true,
        leading: const BackKey(),
        actions: <Widget>[TextLink(label: AppStrings.save, onTap: () {})],
      ),
    ),
  ];

  List<Widget> _sectionLabels(Colourway c) => <Widget>[
    SectionEyebrow(label: 'Sunflower', color: c.student, meta: '18 students'),
    SectionEyebrow(label: 'Staff on duty', color: c.staffFg, meta: '4'),
    SectionEyebrow(label: 'Needs your attention', color: c.dangerFg),
    const SectionEyebrow(label: 'Starting soon', meta: '3'),
    AppCard(
      child: SectionHeader(
        title: "Today's school status",
        onAction: () => showAppToast(context, 'View all pressed'),
      ),
    ),
  ];

  List<Widget> _avatars(Colourway c) => <Widget>[
    const AppCard(
      child: Wrap(
        spacing: AppSizes.rowGap,
        runSpacing: AppSizes.rowGap,
        children: <Widget>[
          AppAvatar(initials: 'AO', attendance: AttendanceStatus.signedIn),
          AppAvatar(initials: 'BK', attendance: AttendanceStatus.signedOut),
          AppAvatar(initials: 'CL', attendance: AttendanceStatus.absent),
          AppAvatar(initials: 'DM', attendance: AttendanceStatus.notMarked),
          AppAvatar(initials: 'DW', tone: AvatarTone.staff),
          AppAvatar(initials: 'MR', tone: AvatarTone.impact),
          AppAvatar(initials: 'NS', tone: AvatarTone.neutral),
        ],
      ),
    ),
    Row(
      spacing: AppSizes.rowGap,
      children: <Widget>[
        for (final s in AttendanceStatus.values)
          AttendanceDot(status: s, ringColor: c.page),
        Expanded(
          child: _caption(c, 'Signed In, Signed Out, Absent, Not Marked'),
        ),
      ],
    ),
  ];

  List<Widget> _rows(Colourway c) => <Widget>[
    AppCard(
      padding: EdgeInsets.zero,
      clipContent: true,
      child: Column(
        children: <Widget>[
          ListRow(
            leading: const AppAvatar(
              initials: 'AO',
              attendance: AttendanceStatus.signedIn,
            ),
            title: 'Amara Okafor',
            subtitle: 'Sunflower · Signed In 8:42',
            trailing: const StatusPill(
              label: AppStrings.signedIn,
              tone: PillTone.success,
            ),
            showDivider: true,
            onTap: () => showAppToast(context, 'Row tapped'),
          ),
          ListRow(
            leading: const AppAvatar(initials: 'DW', tone: AvatarTone.staff),
            title: 'Dana Whitfield',
            subtitle: 'Lead teacher · Sunflower',
            trailing: const StatusPill(
              label: 'Upcoming',
              tone: PillTone.staff,
              small: true,
            ),
            onTap: () => showAppToast(context, 'Row tapped'),
          ),
        ],
      ),
    ),
    AppCard(
      padding: EdgeInsets.zero,
      child: ListRow(
        leading: const AppAvatar(initials: 'NS', tone: AvatarTone.neutral),
        title: 'Bare row, no tap, no chevron',
        subtitle: 'Starts Monday',
        trailing: Text(
          '2 tags',
          style: AppTextStyles.rowSub.copyWith(color: c.ink3),
        ),
      ),
    ),
  ];

  List<Widget> _pillsAndTiles(Colourway c) => <Widget>[
    Wrap(
      spacing: AppSizes.chipGap,
      runSpacing: AppSizes.chipGap,
      children: <Widget>[
        const StatusPill(label: AppStrings.signedIn, tone: PillTone.success),
        const StatusPill(label: AppStrings.absent, tone: PillTone.danger),
        const StatusPill(label: AppStrings.notMarked),
        const StatusPill(label: 'Upcoming', tone: PillTone.staff),
        const StatusPill(label: '2 to 3 years', tone: PillTone.student),
        StatusPill(
          label: AppStrings.inRatio,
          tone: PillTone.success,
          line: c.successLine,
        ),
        StatusPill(
          label: 'Custom',
          tone: PillTone.custom,
          foreground: c.task,
          background: c.taskBg,
        ),
      ],
    ),
    const Row(
      spacing: AppSizes.tileGap,
      children: <Widget>[
        Expanded(
          child: CountingTile(
            value: '86',
            label: 'Active students',
            tone: TileTone.student,
          ),
        ),
        Expanded(
          child: CountingTile(
            value: '15',
            label: 'Staff',
            tone: TileTone.staff,
          ),
        ),
        Expanded(
          child: CountingTile(value: '3', label: 'Starting soon'),
        ),
      ],
    ),
    const Row(
      spacing: AppSizes.tileGap,
      children: <Widget>[
        Expanded(
          child: CountingTile(
            value: '2',
            label: 'Not in ratio',
            tone: TileTone.danger,
          ),
        ),
        Expanded(
          child: CountingTile(
            value: '71',
            label: AppStrings.signedIn,
            tone: TileTone.success,
          ),
        ),
      ],
    ),
  ];

  List<Widget> _troughs(Colourway c) => <Widget>[
    AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.space3,
        children: <Widget>[
          const Trough(fraction: .81),
          Trough(fraction: .45, fill: c.staff),
          Trough.segments(
            segments: <TroughSegment>[
              TroughSegment(fraction: .7, color: c.signedIn),
              TroughSegment(fraction: .1, color: c.ink),
              TroughSegment(fraction: .12, color: c.absent),
              TroughSegment(fraction: .08, color: c.notMarked),
            ],
          ),
        ],
      ),
    ),
  ];

  List<Widget> _fields(Colourway c) => <Widget>[
    const AppTextField(
      label: 'Email',
      isRequired: true,
      hintText: 'name@school.org',
      leadingIcon: AppIcons.mail,
      helpText: 'The address your school registered.',
    ),
    const AppTextField(
      label: 'Password',
      isRequired: true,
      hintText: 'Password',
      leadingIcon: AppIcons.lock,
      obscureText: true,
    ),
    const AppTextField(
      label: 'Phone',
      hintText: '+1 555 0100',
      errorText: 'Enter a phone number with a country code.',
    ),
    const AppTextField(label: 'Notes', hintText: 'Anything else', maxLines: 3),
    SearchField(onChanged: (_) {}),
    DropdownField(
      label: 'Classroom',
      isRequired: true,
      value: _classroom,
      placeholder: 'Any classroom',
      onTap: () async {
        final picked = await SingleSelectSheet.show<String>(
          context,
          title: 'Choose a classroom',
          options: _classroomOptions,
          selected: _classroom,
        );
        if (picked != null) setState(() => _classroom = picked);
      },
    ),
    DropdownField(
      label: 'Tags',
      value: _tags.isEmpty ? null : AppStrings.selectedCount(_tags.length),
      placeholder: 'Any tag',
      onTap: () async {
        final picked = await MultiSelectSheet.show<String>(
          context,
          title: 'Filter by tag',
          subtitle: 'Students with any of these',
          options: _tagOptions,
          selected: _tags,
        );
        if (picked != null) setState(() => _tags = picked);
      },
    ),
    _caption(c, 'Both dropdowns open a select sheet'),
  ];

  List<Widget> _choices(Colourway c) => <Widget>[
    for (final (i, name) in const <String>[
      'Brightpath Learning Group',
      'Meadow Lane Nursery',
    ].indexed)
      RadioCard(
        title: name,
        subtitle: 'Your role here: Admin',
        selected: _radio == i,
        onTap: () => setState(() => _radio = i),
      ),
    AppCard(
      padding: EdgeInsets.zero,
      child: CheckRow(
        label: 'Include inactive students',
        subtitle: 'Shows students who left this year',
        checked: _check,
        onChanged: (v) => setState(() => _check = v),
      ),
    ),
    Row(
      spacing: AppSizes.rowGap,
      children: <Widget>[
        const AppCheckbox(checked: false),
        const AppCheckbox(checked: true),
        const RadioRing(selected: false),
        const RadioRing(selected: true),
        _caption(c, 'Bare marks'),
      ],
    ),
  ];

  List<Widget> _switches(Colourway c) => <Widget>[
    AppCard(
      padding: EdgeInsets.zero,
      child: ListRow(
        title: 'Push notifications',
        subtitle: _toggle ? 'On' : 'Off',
        showChevron: false,
        trailing: AppToggle(
          value: _toggle,
          onChanged: (v) => setState(() => _toggle = v),
        ),
      ),
    ),
    SegmentedControl(
      segments: const <String>[AppStrings.students, AppStrings.staff],
      sublabels: const <String>['71 in', '12 in'],
      index: _segment,
      onChanged: (i) => setState(() => _segment = i),
    ),
    SegmentedControl(
      segments: const <String>['Day', 'Week', 'Month'],
      index: _segment.clamp(0, 2),
      onChanged: (i) => setState(() => _segment = i),
    ),
    ChipRow(
      padding: EdgeInsets.zero,
      children: <Widget>[
        for (final (label, count) in const <(String, String)>[
          ('All', '86'),
          ('Sunflower', '18'),
          ('Bluebell', '14'),
          ('Maple', '22'),
        ])
          AppChip(
            label: label,
            count: count,
            selected: _chips.contains(label),
            onTap: () => setState(() {
              _chips = _chips.contains(label)
                  ? (<String>{..._chips}..remove(label))
                  : <String>{..._chips, label};
            }),
          ),
        AppChip(label: 'Allergy', onRemove: () {}),
        TextLink(label: AppStrings.clearAll, onTap: () {}),
      ],
    ),
    _caption(c, 'Chips scroll past the gutter'),
  ];

  List<Widget> _feedback(Colourway c) => <Widget>[
    const OfflineBanner(),
    const InlineAlert(
      message: 'Email or password is incorrect. Check both and try again.',
    ),
    const InlineAlert(
      tone: AlertTone.info,
      message:
          'You see Sunflower, the classroom you are rostered to. Adding, '
          'editing and deactivating students is admin work.',
    ),
    AppCard(
      child: EmptyState(
        icon: AppIcons.classrooms,
        title: 'No classrooms yet',
        subtitle: 'Create the first one and add students to it.',
        actionLabel: 'Create a classroom',
        onAction: () => showAppToast(context, 'Create pressed'),
      ),
    ),
    AppCard(
      child: ErrorState(
        message: AppStrings.checkConnection,
        onRetry: () => showAppToast(context, 'Retry pressed'),
      ),
    ),
    const AppCard(child: LoadingState(label: AppStrings.loading)),
    Row(
      spacing: AppSizes.rowGap,
      children: <Widget>[
        const LoadingRing(),
        const LoadingRing(size: AppSizes.ringLarge),
        LoadingRing(color: c.student),
        _caption(c, 'Rings: 16, 24, coloured'),
      ],
    ),
  ];

  List<Widget> _sheets(Colourway c) => <Widget>[
    const AppToast(message: 'Saved. The roster is up to date.'),
    const AppToast(
      message: 'Could not save. Try again.',
      tone: ToastTone.error,
    ),
    Row(
      spacing: AppSizes.keyGap,
      children: <Widget>[
        Expanded(
          child: SecondaryKey(
            label: 'Show toast',
            onTap: () =>
                showAppToast(context, 'Saved. The roster is up to date.'),
          ),
        ),
        Expanded(
          child: SecondaryKey(
            label: 'Show sheet',
            onTap: () => showAppSheet<void>(
              context,
              builder: (context) => AppBottomSheet(
                title: 'More actions',
                subtitle: 'Amara Okafor · Sunflower',
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSizes.fieldGap,
                  children: <Widget>[
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListRow(
                        title: 'Move classroom',
                        subtitle: 'Pick a destination and a date',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListRow(
                        title: 'Mark absent',
                        subtitle: 'For today only',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                footer: <Widget>[
                  SecondaryKey(
                    label: AppStrings.cancel,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  PrimaryKey(
                    label: 'Open profile',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    _caption(c, 'The toast lands under the header bar'),
  ];

  List<Widget> _fabs() => <Widget>[
    Row(
      spacing: AppSizes.rowGap,
      children: <Widget>[
        AppFab(onTap: () => showAppToast(context, 'FAB pressed')),
        const AppFab(isDead: true),
      ],
    ),
  ];

  List<Widget> _pad() => <Widget>[
    for (final row in const <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
    ])
      Row(
        spacing: AppSizes.keyGap,
        children: <Widget>[
          for (final digit in row)
            Expanded(
              child: PinKey(
                label: digit,
                onTap: () => showAppToast(context, 'Pressed $digit'),
              ),
            ),
        ],
      ),
    Row(
      spacing: AppSizes.keyGap,
      children: <Widget>[
        const Spacer(),
        Expanded(
          child: PinKey(
            label: '0',
            onTap: () => showAppToast(context, 'Pressed 0'),
          ),
        ),
        Expanded(
          child: PinKey(
            icon: AppIcons.backspace,
            semanticLabel: AppStrings.clear,
            onTap: () => showAppToast(context, 'Backspace'),
          ),
        ),
      ],
    ),
  ];
}
