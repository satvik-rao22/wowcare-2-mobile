# better_player_plus — vendored fork

## What this is

A copy of the pub.dev package `better_player_plus`, vendored so its **iOS Swift**
can be patched. `pubspec.yaml` depends on it by path
(`better_player_plus: {path: third_party/better_player}`) instead of by version.

| | |
|---|---|
| Upstream package | `better_player_plus` |
| Forked from version | **1.2.1** |
| Upstream sha256 | `133e212e68ce830d0fa72da02efe597571a9915b526927fa3b427c70dea64613` |
| Previously declared as | `better_player_plus: ^1.1.5` (which resolved to 1.2.1) |
| Forked on | 2026-09-08 |
| Upstream source | <https://pub.dev/packages/better_player_plus/versions/1.2.1> |

At the time of vendoring this tree was a **byte-for-byte copy** of the resolved
package (`diff -r` against `~/.pub-cache/hosted/pub.dev/better_player_plus-1.2.1/`
was clean). Everything under this directory that differs from that is listed
under [Local changes](#local-changes) below.

> Note: `ios/better_player_plus.podspec` declares `s.version = '1.1.2'` upstream —
> the podspec version string lags the package version. That is upstream's, not
> ours; expect `ios/Podfile.lock` to keep saying `1.1.2`.

## Why we forked

The activity/chat video viewer (`lib/shared/common/widgets/hls_web_player.dart`)
needs iOS Picture-in-Picture to behave the way it already does on Android. Two
things in the plugin's iOS implementation stand in the way, and neither can be
worked around from app code because both live inside
`ios/Classes/BetterPlayer.swift`, which the app cannot reach:

1. **No PiP failure delegate.** `AVPictureInPictureControllerDelegate`'s
   `pictureInPictureController(_:failedToStartPictureInPictureWithError:)` is not
   implemented, so a refused PiP request emits no event at all. Meanwhile
   `BetterPlayerController.enablePictureInPicture()` has already called
   `setControlsEnabled(false)` and only restores it on a `pipStop` that never
   arrives — leaving the user a video they can no longer pause. The app currently
   works around this with a timeout (`_confirmPipStarted`), which is a guess
   where an event should be.

2. **No PiP auto-start.** `AVPictureInPictureController` is never given
   `canStartPictureInPictureAutomaticallyFromInline` (iOS 14.2+), which is the
   only supported way to reproduce Android's "leave the app and the video keeps
   floating" behaviour. AVKit refuses a manual `startPictureInPicture()` once the
   process is backgrounded, so the app currently has to fire the request early,
   at `AppLifecycleState.inactive` — which also fires for Control Centre and
   Notification Centre, briefly opening PiP when the user never left the app.

A third, smaller defect is in the same file and worth fixing while we are here:
`disablePictureInPicture()` calls `setPictureInPicture(true)` where it means
`false` (`ios/Classes/BetterPlayer.swift:539`), so stopping PiP issues a stray
start request against a layer that has just been detached.

## Local changes

Every edit to this tree gets an entry here — what changed, in which file, and
why. Keep it in order; this list is the re-apply instructions for the next
upstream bump.

<!-- Append entries below. Format:

### <short title>
- **Files:** `ios/Classes/BetterPlayer.swift`
- **Why:** …
- **What:** …
-->

_None yet — this tree is still identical to upstream 1.2.1._

## Taking a newer upstream version

1. Fetch the new version into the pub cache (`flutter pub get` in a scratch
   project, or download from pub.dev).
2. Diff it against this tree to see what upstream changed under our edits.
3. Re-copy the package over this directory, then re-apply each entry in
   [Local changes](#local-changes).
4. Update the version, sha256 and date in the table above.
5. `flutter pub get`, `flutter analyze`, `flutter test`, then build and smoke-test
   video playback and PiP on a **physical** iPhone and an Android device — the
   iOS Simulator does not run PiP correctly.
