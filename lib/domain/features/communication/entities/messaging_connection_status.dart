/// Health of the realtime (Firestore) message subscription, surfaced so the UI
/// can tell the user when live updates are degraded instead of appearing frozen.
///
///  - [connecting]   — establishing the subscription; no server snapshot yet.
///  - [connected]    — a server snapshot has been received; live and healthy.
///  - [reconnecting] — was connected, hit a transient error, retrying with
///                     backoff (or waiting for auth to recover).
///  - [offline]      — retries exhausted; live sync is down. The REST fallback
///                     may still serve messages, so this is degraded, not dead.
enum MessagingConnectionStatus { connecting, connected, reconnecting, offline }
