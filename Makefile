FLUTTER ?= flutter

.PHONY: help clean get upgrade doctor fix analyze test format \
	uat-run local-run prod-run \
	uat-run-profile local-run-profile prod-run-profile \
	uat-run-release local-run-release prod-run-release \
	uat-apk-debug local-apk-debug prod-apk-debug \
	uat-apk-profile local-apk-profile prod-apk-profile \
	uat-apk-release local-apk-release prod-apk-release \
	uat-appbundle local-appbundle prod-appbundle \
	uat-ios-debug local-ios-debug prod-ios-debug \
	uat-ios-profile local-ios-profile prod-ios-profile \
	uat-ios-release local-ios-release prod-ios-release \
	uat-ipa local-ipa prod-ipa

# -----------------------------------------------------------------------------
# HELP
# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "Flutter Makefile Commands"
	@echo "========================="
	@echo ""
	@echo "General:"
	@echo "  make clean"
	@echo "  make get"
	@echo "  make upgrade"
	@echo "  make doctor"
	@echo "  make fix"
	@echo "  make analyze"
	@echo "  make test"
	@echo "  make format"
	@echo ""
	@echo "Run:"
	@echo "  make uat-run"
	@echo "  make local-run"
	@echo "  make prod-run"
	@echo ""
	@echo "Run Profile:"
	@echo "  make uat-run-profile"
	@echo "  make local-run-profile"
	@echo "  make prod-run-profile"
	@echo ""
	@echo "Run Release:"
	@echo "  make uat-run-release"
	@echo "  make local-run-release"
	@echo "  make prod-run-release"
	@echo ""
	@echo "APK Debug:"
	@echo "  make uat-apk-debug"
	@echo "  make local-apk-debug"
	@echo "  make prod-apk-debug"
	@echo ""
	@echo "APK Profile:"
	@echo "  make uat-apk-profile"
	@echo "  make local-apk-profile"
	@echo "  make prod-apk-profile"
	@echo ""
	@echo "APK Release:"
	@echo "  make uat-apk-release"
	@echo "  make local-apk-release"
	@echo "  make prod-apk-release"
	@echo ""
	@echo "Android AppBundle:"
	@echo "  make uat-appbundle"
	@echo "  make local-appbundle"
	@echo "  make prod-appbundle"
	@echo ""
	@echo "iOS Debug:"
	@echo "  make uat-ios-debug"
	@echo "  make local-ios-debug"
	@echo "  make prod-ios-debug"
	@echo ""
	@echo "iOS Profile:"
	@echo "  make uat-ios-profile"
	@echo "  make local-ios-profile"
	@echo "  make prod-ios-profile"
	@echo ""
	@echo "iOS Release:"
	@echo "  make uat-ios-release"
	@echo "  make local-ios-release"
	@echo "  make prod-ios-release"
	@echo ""
	@echo "IPA:"
	@echo "  make uat-ipa"
	@echo "  make local-ipa"
	@echo "  make prod-ipa"
	@echo ""

# -----------------------------------------------------------------------------
# GENERAL COMMANDS
# -----------------------------------------------------------------------------

clean:
	$(FLUTTER) clean

get:
	$(FLUTTER) pub get

upgrade:
	$(FLUTTER) pub upgrade

doctor:
	$(FLUTTER) doctor -v

fix:
	dart fix --apply

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

format:
	dart format .

# -----------------------------------------------------------------------------
# RUN COMMANDS
# -----------------------------------------------------------------------------

uat-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=UAT

local-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=LOCAL

prod-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# RUN PROFILE
# -----------------------------------------------------------------------------

uat-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=UAT

local-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=LOCAL

prod-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# RUN RELEASE
# -----------------------------------------------------------------------------

uat-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=UAT

local-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=LOCAL

prod-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK DEBUG
# -----------------------------------------------------------------------------

uat-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=UAT

local-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=LOCAL

prod-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK PROFILE
# -----------------------------------------------------------------------------

uat-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=UAT

local-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=LOCAL

prod-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK RELEASE
# -----------------------------------------------------------------------------

uat-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=UAT

local-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=LOCAL

prod-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APP BUNDLE
# -----------------------------------------------------------------------------

uat-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=UAT

local-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=LOCAL

prod-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS DEBUG
# -----------------------------------------------------------------------------

uat-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=UAT

local-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=LOCAL

prod-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS PROFILE
# -----------------------------------------------------------------------------

uat-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=UAT

local-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=LOCAL

prod-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS RELEASE
# -----------------------------------------------------------------------------

uat-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=UAT

local-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=LOCAL

prod-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IPA BUILD
# -----------------------------------------------------------------------------

uat-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=UAT

local-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=LOCAL

prod-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=PROD