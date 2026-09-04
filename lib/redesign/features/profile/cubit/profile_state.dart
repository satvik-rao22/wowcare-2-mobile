part of 'profile_cubit.dart';

/// 13f's four states, in the order its pills draw them.
enum ProfileStatus {
  loading,
  ready,

  /// The record came off this phone because the network was unreachable.
  offline,

  /// Nothing to show but what sign-in already knew.
  failed,
}

/// What the hero's avatar is doing. Independent of [ProfileStatus]: a photo
/// that will not upload leaves the record itself untouched.
enum PhotoStatus { idle, uploading, failed }

@immutable
class ProfileState extends Equatable {
  const ProfileState({
    required this.userId,
    required this.persona,
    this.status = ProfileStatus.loading,
    this.record,
    this.build,
    this.cachedAtLabel,
    this.isPinVisible = false,
    this.photo = PhotoStatus.idle,
    this.photoProgress = 0,
    this.hasPhotoChanged = false,
    this.hasPhotoRemoved = false,
  });

  /// The signed-in account. Every source call is scoped to it.
  final String userId;

  /// The lens, not a colour: an Admin, a Staff member and a Guardian get the
  /// same material and differ only in what they may see and do.
  final Persona persona;

  final ProfileStatus status;
  final ProfileRecord? record;
  final AppBuildInfo? build;

  /// "9:02 AM": when the copy on this phone was saved. Offline only.
  final String? cachedAtLabel;

  final bool isPinVisible;
  final PhotoStatus photo;

  /// 0 to 1 while [photo] is uploading.
  final double photoProgress;

  /// One-shot flags the screen toasts on and then clears.
  final bool hasPhotoChanged;
  final bool hasPhotoRemoved;

  bool get isLoading => status == ProfileStatus.loading;
  bool get isFailed => status == ProfileStatus.failed;
  bool get isOffline => status == ProfileStatus.offline;

  /// Loaded or loaded from cache: either way there is a record to draw.
  bool get hasBody => record != null && !isLoading && !isFailed;

  /// A guardian gets 13c: no work schedule, no staff record, one role.
  bool get isGuardianLens => persona == Persona.guardian;

  /// Only an Admin may edit a work schedule. Staff see the locked chip, which
  /// is the frame's own refusal rather than a hidden card.
  bool get canEditSchedule => persona == Persona.admin;

  /// The guardian's children card only exists when there are children on the
  /// record.
  List<ProfileChild> get children => record?.children ?? const <ProfileChild>[];

  WorkSchedule? get workSchedule =>
      isGuardianLens ? null : record?.workSchedule;

  /// What the PIN row reads out: the digits, or the mask.
  ///
  /// A guardian's is simply shown. It is theirs to type on the kiosk and the
  /// app never asks them for it, so there is nothing to hide it from.
  String get pinLabel => isPinVisible || isGuardianLens
      ? (record?.signInPin ?? '')
      : ProfileStrings.pinMask;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileRecord? record,
    AppBuildInfo? build,
    String? cachedAtLabel,
    bool clearCachedAt = false,
    bool? isPinVisible,
    PhotoStatus? photo,
    double? photoProgress,
    bool? hasPhotoChanged,
    bool? hasPhotoRemoved,
  }) => ProfileState(
    userId: userId,
    persona: persona,
    status: status ?? this.status,
    record: record ?? this.record,
    build: build ?? this.build,
    cachedAtLabel: clearCachedAt ? null : (cachedAtLabel ?? this.cachedAtLabel),
    isPinVisible: isPinVisible ?? this.isPinVisible,
    photo: photo ?? this.photo,
    photoProgress: photoProgress ?? this.photoProgress,
    hasPhotoChanged: hasPhotoChanged ?? this.hasPhotoChanged,
    hasPhotoRemoved: hasPhotoRemoved ?? this.hasPhotoRemoved,
  );

  @override
  List<Object?> get props => <Object?>[
    userId,
    persona,
    status,
    record,
    build,
    cachedAtLabel,
    isPinVisible,
    photo,
    photoProgress,
    hasPhotoChanged,
    hasPhotoRemoved,
  ];
}
