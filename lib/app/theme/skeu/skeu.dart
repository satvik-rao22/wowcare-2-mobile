/// The ChildcareWow skeuomorphic design system, ported from the
/// "WowCare Mobile Redesign" design document and its `childcarewow-design-
/// system` token set.
///
/// Three materials, and only three:
///
/// * **Raised panels** ([SkeuPanel], [SkeuSectionCard]) — a shallow vertical
///   gradient with a lit top bevel and a navy-tinted drop shadow. Everything
///   that holds content.
/// * **Recessed wells** ([SkeuWell], [SkeuTextField], [SkeuSearchField]) —
///   inset shadows. Everything you type into, scroll inside, or read a value
///   out of.
/// * **Rimmed keys** ([SkeuButton], [SkeuIconButton], [SkeuFoldKey]) — a solid
///   coloured face on a darker rim that sinks 3px when pressed. Everything you
///   press.
///
/// Light always comes from directly above, every shadow is navy-tinted rather
/// than black, and pink is reserved for THE recommended action — it never
/// doubles as a warning.
///
/// Import this barrel rather than the parts.
library;

export 'skeu_button.dart';
export 'skeu_chrome.dart';
export 'skeu_display.dart';
export 'skeu_fab.dart';
export 'skeu_field.dart';
export 'skeu_inner_shadow.dart';
export 'skeu_press.dart';
export 'skeu_surface.dart';
export 'skeu_theme.dart';
export 'skeu_tokens.dart';
