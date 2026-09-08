import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';

/// Drives a policy through a real lifecycle sequence the way
/// `HlsWebPlayer.didChangeAppLifecycleState` does, carrying the PiP flags
/// forward between states, and returns every action it asked for.
///
/// [pipStarts] models whether the platform actually honours the PiP request:
/// false is a device that refuses it (or, on iPhone, a build missing the
/// `audio` UIBackgroundMode).
List<VideoLifecycleAction> _run(
  VideoLifecyclePolicy policy,
  List<AppLifecycleState> states, {
  required bool isPlaying,
  bool pipStarts = true,
}) {
  final actions = <VideoLifecycleAction>[];
  var playing = isPlaying;
  var pipActive = false;
  var enteringPip = false;
  var wasPlayingBeforeBackground = false;

  for (final state in states) {
    if (state != AppLifecycleState.resumed && playing && !pipActive) {
      wasPlayingBeforeBackground = true;
    }

    final action = policy.actionFor(
      state: state,
      isPlaying: playing,
      isPipActive: pipActive,
      isEnteringPip: enteringPip,
      wasPlayingBeforeBackground: wasPlayingBeforeBackground,
    );
    actions.add(action);

    switch (action) {
      case VideoLifecycleAction.enterPip:
        // The request is in flight for the rest of the trip out of the app;
        // it resolves to a floating window only if the platform allows it.
        enteringPip = true;
        pipActive = pipStarts;
        if (!pipStarts) {
          enteringPip = false;
          playing = false; // _handleBackgrounding()'s pause fallback.
        }
      case VideoLifecycleAction.exitPip:
        pipActive = false;
      case VideoLifecycleAction.pause:
        playing = false;
      case VideoLifecycleAction.resume:
        playing = true;
      case VideoLifecycleAction.none:
        break;
    }

    if (state == AppLifecycleState.resumed) {
      wasPlayingBeforeBackground = false;
    }
  }
  return actions;
}

/// What iOS emits when the user swipes home or opens the app switcher.
const _leaveApp = <AppLifecycleState>[
  AppLifecycleState.inactive,
  AppLifecycleState.paused,
];

/// ...and on the way back in.
const _reopenApp = <AppLifecycleState>[
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  const ios = VideoLifecyclePolicy(TargetPlatform.iOS);
  const android = VideoLifecyclePolicy(TargetPlatform.android);

  group('leaving the app mid-playback', () {
    test(
      'floats the video into PiP on iOS exactly as it already does on Android, '
      'which is the whole point of this policy - the iPhone used to pause here',
      () {
        expect(
          _run(ios, _leaveApp, isPlaying: true),
          contains(VideoLifecycleAction.enterPip),
        );
        expect(
          _run(android, _leaveApp, isPlaying: true),
          contains(VideoLifecycleAction.enterPip),
        );
      },
    );

    test(
      'asks for PiP while the app is still on screen on iOS (inactive) but at '
      'the last moment on Android (paused) - AVPictureInPictureController '
      'refuses a request made once the process is already backgrounded, so '
      'asking at the Android moment is what made this a no-op on iPhone',
      () {
        expect(ios.pipTrigger, AppLifecycleState.inactive);
        expect(android.pipTrigger, AppLifecycleState.paused);

        expect(
          _run(ios, _leaveApp, isPlaying: true),
          <VideoLifecycleAction>[
            VideoLifecycleAction.enterPip, // inactive
            VideoLifecycleAction.none, // paused: PiP already has playback
          ],
        );
        expect(
          _run(android, _leaveApp, isPlaying: true),
          <VideoLifecycleAction>[
            VideoLifecycleAction.none, // inactive: too early on Android
            VideoLifecycleAction.enterPip, // paused
          ],
        );
      },
    );

    test(
      'never pauses a video that PiP has taken over, on either platform - a '
      'pause here would hand the user a frozen floating window',
      () {
        for (final policy in <VideoLifecyclePolicy>[ios, android]) {
          expect(
            _run(policy, _leaveApp, isPlaying: true),
            isNot(contains(VideoLifecycleAction.pause)),
          );
        }
      },
    );

    test(
      'pauses instead when the platform refuses PiP, so audio never keeps '
      'playing under a screen the user cannot see',
      () {
        expect(
          _run(ios, _leaveApp, isPlaying: true, pipStarts: false),
          <VideoLifecycleAction>[
            VideoLifecycleAction.enterPip, // asked, and was refused
            VideoLifecycleAction.none, // fallback pause already ran
          ],
        );

        // A refusal that arrives too late to be caught during `inactive`
        // still gets paused at `paused`.
        expect(
          ios.actionFor(
            state: AppLifecycleState.paused,
            isPlaying: true,
            isPipActive: false,
            isEnteringPip: false,
            wasPlayingBeforeBackground: true,
          ),
          VideoLifecycleAction.pause,
        );
      },
    );

    test('leaves an already-paused video alone on both platforms', () {
      for (final policy in <VideoLifecyclePolicy>[ios, android]) {
        expect(
          _run(policy, _leaveApp, isPlaying: false),
          everyElement(VideoLifecycleAction.none),
        );
      }
    });
  });

  group('coming back to the app', () {
    test(
      'closes the floating window on iOS but leaves Android to the system - '
      'the plugin backs Android disable with activity.moveTaskToBack(), which '
      'would push the app the user just reopened straight back out',
      () {
        expect(ios.exitsPipOnResume, isTrue);
        expect(android.exitsPipOnResume, isFalse);

        expect(
          ios.actionFor(
            state: AppLifecycleState.resumed,
            isPlaying: true,
            isPipActive: true,
            isEnteringPip: false,
            wasPlayingBeforeBackground: true,
          ),
          VideoLifecycleAction.exitPip,
        );
        expect(
          android.actionFor(
            state: AppLifecycleState.resumed,
            isPlaying: true,
            isPipActive: true,
            isEnteringPip: false,
            wasPlayingBeforeBackground: true,
          ),
          VideoLifecycleAction.none,
        );
      },
    );

    test(
      'restores playback that backgrounding paused, identically on both '
      'platforms',
      () {
        for (final policy in <VideoLifecyclePolicy>[ios, android]) {
          expect(
            _run(
              policy,
              [..._leaveApp, ..._reopenApp],
              isPlaying: true,
              pipStarts: false,
            ).last,
            VideoLifecycleAction.resume,
            reason: '${policy.platform} should resume after a refused PiP',
          );
        }
      },
    );

    test(
      'does not restart a video the user had already paused before leaving',
      () {
        for (final policy in <VideoLifecyclePolicy>[ios, android]) {
          expect(
            _run(policy, [..._leaveApp, ..._reopenApp], isPlaying: false),
            everyElement(VideoLifecycleAction.none),
          );
        }
      },
    );

    test(
      'a transient interruption that never reaches the background - Control '
      'Centre, Notification Centre - self-corrects on iOS: PiP opens and is '
      'closed again on resume rather than being left floating over the app',
      () {
        expect(
          _run(
            ios,
            const [AppLifecycleState.inactive, AppLifecycleState.resumed],
            isPlaying: true,
          ),
          <VideoLifecycleAction>[
            VideoLifecycleAction.enterPip,
            VideoLifecycleAction.exitPip,
          ],
        );
      },
    );
  });

  group('full round trip', () {
    test(
      'iOS and Android reach the same end state: video floating on the way '
      'out, back inline and playing on the way in',
      () {
        for (final policy in <VideoLifecyclePolicy>[ios, android]) {
          final actions = _run(
            policy,
            [..._leaveApp, ..._reopenApp],
            isPlaying: true,
          );
          expect(
            actions,
            contains(VideoLifecycleAction.enterPip),
            reason: '${policy.platform} should float the video',
          );
          expect(
            actions,
            isNot(contains(VideoLifecycleAction.pause)),
            reason: '${policy.platform} should never pause a floating video',
          );
        }
      },
    );
  });
}
