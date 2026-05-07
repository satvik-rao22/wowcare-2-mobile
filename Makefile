FLUTTER ?= flutter

.PHONY: help uat-run local-run uat-build local-build uat-appbundle local-appbundle uat-ios local-ios uat-ipa local-ipa

help:
	@echo "Available targets:"
	@echo "  make uat-run"
	@echo "  make local-run"
	@echo "  make uat-build"
	@echo "  make local-build"
	@echo "  make uat-appbundle"
	@echo "  make local-appbundle"
	@echo "  make uat-ios"
	@echo "  make local-ios"
	@echo "  make uat-ipa"
	@echo "  make local-ipa"

uat-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=UAT

local-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=LOCAL

uat-build:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=UAT

local-build:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=LOCAL

uat-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=UAT

local-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=LOCAL

uat-ios:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=UAT

local-ios:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=LOCAL

uat-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=UAT

local-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=LOCAL
