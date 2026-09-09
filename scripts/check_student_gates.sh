#!/usr/bin/env bash
#
# Student-module engineering-gate checker (Step 16).
#
# A standalone, opt-in regression guard for the gates the Student remediation
# actually cleaned to zero. It is NOT wired into CI or analysis_options.yaml and
# makes no claim of repository-wide enforcement — run it locally or wire it into
# a pipeline yourself:  bash scripts/check_student_gates.sh
#
# Exits non-zero if any ENFORCED gate regresses. The nuanced gates that have
# documented justified exceptions (imperative cross-module navigation,
# presentation infra access pending an MVVM pass, cross-feature formatter
# duplicates, justified handwritten serialization, justified UI Map<String,dynamic>,
# pre-existing >400-line files) are printed for visibility but not failed here.
#
# POSIX/BSD-and-GNU-portable: uses only `grep -E` (no `-P`).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/lib/presentation/features/students"
DOM="$ROOT/lib/domain/features/student"
NOCOMMENT="^[[:space:]]*//"   # drop whole-line comments
fail=0

# live <path> <ERE>  -> count of non-(whole-line-)comment matches.
# No `-n`: a line-number prefix would defeat the leading-comment anchor and
# count doc-comment ("/// ... Map<String,dynamic> ...") references as matches.
live() {
  grep -rhE "$2" "$1" --include='*.dart' 2>/dev/null | grep -vE "$NOCOMMENT" | wc -l | tr -d ' '
}

check() { # <name> <count>  — fails when count != 0
  if [ "${2:-0}" -eq 0 ]; then
    printf "  PASS  %-46s %s\n" "$1" "$2"
  else
    printf "  FAIL  %-46s %s\n" "$1" "$2"
    fail=1
  fi
}

echo "== Student engineering gates (enforced) =="
check "Gate 3  relative cross-folder imports" "$(grep -rhcE "import '(\.\./)" "$DIR" --include='*.dart' 2>/dev/null | paste -sd+ - | bc)"
check "Gate 4a Color(0x..) literals"          "$(live "$DIR" 'Color\(0x')"
check "Gate 4b Color.fromRGBO/ARGB literals"  "$(live "$DIR" 'Color\.from(RGBO|ARGB)')"
check "Gate 4c hardcoded fontFamily"          "$(live "$DIR" "fontFamily:[[:space:]]*['\"]")"
check "Gate 7  raw screen-width breakpoints"  "$(live "$DIR" 'MediaQuery\.(of\(context\)\.size|sizeOf).*(width|height)[[:space:]]*[<>]')"
check "Gate 9  Map<String,dynamic> in DOMAIN" "$(live "$DOM" 'Map<String,[[:space:]]?dynamic>')"

echo ""
echo "== Informational (documented justified exceptions — not failed here) =="
printf "  info  Gate 1  imperative Navigator/MaterialPageRoute : %s\n" "$(live "$DIR" 'Navigator\.push\(|MaterialPageRoute\(')"
printf "  info  Gate 5  serviceLocator in view/widget files    : %s\n" "$(grep -rhoE 'serviceLocator<[A-Za-z]+>' "$DIR/view" "$DIR/widgets" --include='*.dart' 2>/dev/null | wc -l | tr -d ' ')"
printf "  info  Gate 9  Map<String,dynamic> in presentation    : %s\n" "$(live "$DIR" 'Map<String,[[:space:]]?dynamic>')"
printf "  info  Gate 11 student lib files > 400 lines          : %s\n" "$(find "$DIR" -name '*.dart' -exec wc -l {} \; 2>/dev/null | awk '$1>400' | wc -l | tr -d ' ')"

echo ""
if [ "$fail" -eq 0 ]; then
  echo "Student enforced gates: OK"
else
  echo "Student enforced gates: REGRESSION DETECTED"
fi
exit "$fail"
