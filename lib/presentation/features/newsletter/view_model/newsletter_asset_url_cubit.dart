import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Resolves newsletter media asset codes to displayable URLs.
///
/// Newsletter attachments and inline images arrive from the list/detail APIs
/// carrying a `mediaCode`, not a URL. Turning one into something an
/// `Image.network` can show is a second, per-asset round trip.
///
/// Before Mandate 5 that round trip was made by three different widgets, each
/// reaching for `serviceLocator<ImageUploadService>()` and holding the result
/// in a `Future` field behind a `FutureBuilder` — three private copies of
/// state, invisible to any cubit. This cubit is that state's single owner.
///
/// **Why this is not folded into `NewsletterListCubit`.** The same three
/// widgets render under three different owning cubits: the Sent list
/// (`NewsletterListCubit`), the parent list (`StudentNewslettersCubit`, which
/// belongs to the dashboard feature) and the preview screen
/// (`PreviewNewsletterCubit`). Asset URLs are orthogonal to all three, so they
/// get their own cubit provided alongside whichever one is in scope, rather
/// than the same map being bolted onto three list cubits — one of them in
/// another module.
///
/// **Resolution stays lazy.** [resolve] is called by a tile when it mounts,
/// not eagerly for every attachment of every newsletter in the list. Eager
/// resolution would multiply the request count the moment a page loaded.
class NewsletterAssetUrlCubit extends Cubit<NewsletterAssetUrlState> {
  NewsletterAssetUrlCubit({required ImageUploadService imageUploadService})
    : _imageUploadService = imageUploadService,
      super(const NewsletterAssetUrlState.initial());

  final ImageUploadService _imageUploadService;

  /// Codes with a resolution in flight. Deliberately NOT part of the emitted
  /// state: no widget renders differently because of it (an unresolved code
  /// and an in-flight code look identical — both are "no URL yet"), and
  /// keeping it out means [resolve] never emits just to record bookkeeping.
  final Set<String> _inFlight = <String>{};

  /// Starts resolving [assetCode] if it is not already known or in flight.
  ///
  /// Safe and cheap to call repeatedly — tiles call it on mount and again
  /// whenever their code changes during list recycling.
  ///
  /// This does **not** add a network call over the previous `FutureBuilder`
  /// code. `ImageUploadService.getMediaAssetUrlByCode` already keeps a session
  /// cache, an in-flight map that shares one future between concurrent
  /// callers, and a failure cooldown. The guards here only avoid re-entering
  /// that method; the request count it makes is unchanged.
  Future<void> resolve(String assetCode) async {
    final String code = assetCode.trim();
    if (code.isEmpty) return;
    if (state.urlByCode.containsKey(code) || _inFlight.contains(code)) return;

    // Already resolved earlier this session → adopt it without a loading
    // frame, exactly as the `initialData:` seed on the old FutureBuilder did.
    final String? cached = _imageUploadService.cachedMediaAssetUrl(code);
    if (cached != null) {
      _emitUrl(code, cached);
      return;
    }

    _inFlight.add(code);
    try {
      final String url = await _imageUploadService.getMediaAssetUrlByCode(
        assetCode: code,
      );
      if (isClosed) return;
      _emitUrl(code, url);
    } catch (_) {
      // Same outcome as the `catch (_) { return ''; }` in each of the three
      // widgets this replaced: an unresolvable asset renders as the empty
      // state, never as an error. Swallowing is the pre-existing behaviour,
      // not a new decision.
      if (isClosed) return;
      _emitUrl(code, '');
    } finally {
      _inFlight.remove(code);
    }
  }

  void _emitUrl(String code, String url) {
    emit(
      NewsletterAssetUrlState(
        urlByCode: <String, String>{...state.urlByCode, code: url},
      ),
    );
  }
}

class NewsletterAssetUrlState extends Equatable {
  const NewsletterAssetUrlState({required this.urlByCode});

  const NewsletterAssetUrlState.initial() : urlByCode = const <String, String>{};

  /// Asset code → resolved URL.
  ///
  /// A **missing** key means "not resolved yet" — the tile shows its loader.
  /// A key present with an **empty** value means "resolved, and there is no
  /// URL" — the tile shows its placeholder. The two are distinct, which is
  /// what preserves the loading/empty split the `FutureBuilder`s expressed
  /// with `ConnectionState.waiting` vs. an empty `snapshot.data`.
  final Map<String, String> urlByCode;

  /// The resolved URL for [assetCode], or null while it is still unknown.
  String? urlFor(String assetCode) => urlByCode[assetCode.trim()];

  @override
  List<Object?> get props => <Object?>[urlByCode];
}
