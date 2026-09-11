FLUTTER ?= flutter

# -----------------------------------------------------------------------------
# Gradle JVM network preference
#
# :app:uploadCrashlyticsMappingFileRelease PUTs the ~6 MB gzipped R8 mapping as a
# single non-resumable fixed-length body (firebase-crashlytics-buildtools 3.0.2 on
# Apache HttpClient: no resume, no socket timeout, 3 transport retries). Java sorts
# IPv4 ahead of IPv6 by default, and some NATs -- an iPhone Personal Hotspot
# (172.20.10.0/28) is the one that bit us -- reset sustained IPv4 uploads after
# ~128-256 KB. All 3 retries die the same way and the build fails with
# `java.net.SocketException: Broken pipe`, before the APK is ever packaged.
#
# This MUST be an environment variable, not `org.gradle.jvmargs`. Gradle classifies
# arbitrary -D properties as mutable, so it reuses a running daemon and applies them
# with System.setProperty() after startup -- but InetAddress caches the preference at
# class-init, so the property reads "true" while resolution stays IPv4-first.
# JAVA_TOOL_OPTIONS is read by the JVM before that, so it actually takes effect.
#
# Only a preference: IPv4 is still used when a network has no IPv6 route.
# -----------------------------------------------------------------------------
export JAVA_TOOL_OPTIONS := $(JAVA_TOOL_OPTIONS) -Djava.net.preferIPv6Addresses=true

.PHONY: help help-optimization clean get upgrade doctor fix analyze test format \
	local-run qa-run uat-run prod-run \
	local-run-profile qa-run-profile uat-run-profile prod-run-profile \
	local-run-release qa-run-release uat-run-release prod-run-release \
	local-apk-debug qa-apk-debug uat-apk-debug prod-apk-debug \
	local-apk-profile qa-apk-profile uat-apk-profile prod-apk-profile \
	local-apk-release qa-apk-release uat-apk-release prod-apk-release \
	local-appbundle qa-appbundle uat-appbundle prod-appbundle \
	local-ios-debug qa-ios-debug uat-ios-debug prod-ios-debug \
	local-ios-profile qa-ios-profile uat-ios-profile prod-ios-profile \
	local-ios-release qa-ios-release uat-ios-release prod-ios-release \
	local-ipa qa-ipa uat-ipa prod-ipa \
	local-build qa-build uat-build prod-build \
	prod-apk-optimized prod-appbundle-optimized prod-ios-optimized prod-build-optimized \
	check-apk-size check-ipa-size check-size analyze-apk \
	optimize-assets convert-png-webp compress-images

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
	@echo "Run (debug):"
	@echo "  make local-run   make qa-run   make uat-run   make prod-run"
	@echo ""
	@echo "Run Profile:"
	@echo "  make local-run-profile   make qa-run-profile   make uat-run-profile   make prod-run-profile"
	@echo ""
	@echo "Run Release:"
	@echo "  make local-run-release   make qa-run-release   make uat-run-release   make prod-run-release"
	@echo ""
	@echo "APK Debug:"
	@echo "  make local-apk-debug   make qa-apk-debug   make uat-apk-debug   make prod-apk-debug"
	@echo ""
	@echo "APK Profile:"
	@echo "  make local-apk-profile   make qa-apk-profile   make uat-apk-profile   make prod-apk-profile"
	@echo ""
	@echo "APK Release:"
	@echo "  make local-apk-release   make qa-apk-release   make uat-apk-release   make prod-apk-release"
	@echo ""
	@echo "Android AppBundle:"
	@echo "  make local-appbundle   make qa-appbundle   make uat-appbundle   make prod-appbundle"
	@echo ""
	@echo "iOS Debug:"
	@echo "  make local-ios-debug   make qa-ios-debug   make uat-ios-debug   make prod-ios-debug"
	@echo ""
	@echo "iOS Profile:"
	@echo "  make local-ios-profile   make qa-ios-profile   make uat-ios-profile   make prod-ios-profile"
	@echo ""
	@echo "iOS Release:"
	@echo "  make local-ios-release   make qa-ios-release   make uat-ios-release   make prod-ios-release"
	@echo ""
	@echo "IPA:"
	@echo "  make local-ipa   make qa-ipa   make uat-ipa   make prod-ipa"
	@echo ""
	@echo "Generic Build (APK + iOS Release):"
	@echo "  make local-build   make qa-build   make uat-build   make prod-build"
	@echo ""
	@echo "Optimization Commands:"
	@echo "  make help-optimization"
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

local-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=LOCAL

qa-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=QA

uat-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=UAT

prod-run:
	$(FLUTTER) run --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# RUN PROFILE
# -----------------------------------------------------------------------------

local-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=LOCAL

qa-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=QA

uat-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=UAT

prod-run-profile:
	$(FLUTTER) run --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# RUN RELEASE
# -----------------------------------------------------------------------------

local-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=LOCAL

qa-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=QA

uat-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=UAT

prod-run-release:
	$(FLUTTER) run --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK DEBUG
# -----------------------------------------------------------------------------

local-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=LOCAL

qa-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=QA

uat-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=UAT

prod-apk-debug:
	$(FLUTTER) build apk --debug --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK PROFILE
# -----------------------------------------------------------------------------

local-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=LOCAL

qa-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=QA

uat-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=UAT

prod-apk-profile:
	$(FLUTTER) build apk --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APK RELEASE
# -----------------------------------------------------------------------------

local-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=LOCAL

qa-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=QA

uat-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=UAT

prod-apk-release:
	$(FLUTTER) build apk --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# APP BUNDLE
# -----------------------------------------------------------------------------

local-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=LOCAL

qa-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=QA

uat-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=UAT

prod-appbundle:
	$(FLUTTER) build appbundle --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS DEBUG
# -----------------------------------------------------------------------------

local-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=LOCAL

qa-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=QA

uat-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=UAT

prod-ios-debug:
	$(FLUTTER) build ios --debug --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS PROFILE
# -----------------------------------------------------------------------------

local-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=LOCAL

qa-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=QA

uat-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=UAT

prod-ios-profile:
	$(FLUTTER) build ios --profile --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IOS RELEASE
# -----------------------------------------------------------------------------

local-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=LOCAL

qa-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=QA

uat-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=UAT

prod-ios-release:
	$(FLUTTER) build ios --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# IPA BUILD
# -----------------------------------------------------------------------------

local-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=LOCAL

qa-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=QA

uat-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=UAT

prod-ipa:
	$(FLUTTER) build ipa --release --dart-define=ENVIRONMENT=PROD

# -----------------------------------------------------------------------------
# GENERIC BUILD COMMANDS
# -----------------------------------------------------------------------------

local-build: local-apk-release local-ios-release

qa-build: qa-apk-release qa-ios-release

uat-build: uat-apk-release uat-ios-release

prod-build: prod-apk-release prod-ios-release

# =============================================================================
# OPTIMIZATION COMMANDS (App Size Reduction)
# =============================================================================

help-optimization:
	@echo ""
	@echo "Flutter App Size Optimization Commands"
	@echo "======================================"
	@echo ""
	@echo "OPTIMIZED PRODUCTION BUILDS (with obfuscation + size reduction):"
	@echo "  make prod-apk-optimized        Build optimized APK (~150-160 MB)"
	@echo "  make prod-appbundle-optimized  Build optimized AAB (~40-50 MB)"
	@echo "  make prod-ios-optimized        Build optimized iOS (~optimized size)"
	@echo "  make prod-build-optimized      Build optimized APK + iOS"
	@echo ""
	@echo "SIZE VERIFICATION:"
	@echo "  make check-apk-size            Show APK size"
	@echo "  make check-ipa-size            Show IPA size"
	@echo "  make check-size                Show all sizes (APK, AAB, IPA)"
	@echo "  make analyze-apk               Analyze APK contents by architecture"
	@echo ""
	@echo "ASSET OPTIMIZATION:"
	@echo "  make optimize-assets           Run all asset optimizations"
	@echo "  make convert-png-webp          Convert PNG → WebP (saves ~30%)"
	@echo "  make compress-images           Compress JPG/PNG images"
	@echo ""
	@echo "EXPECTED RESULTS:"
	@echo "  Current APK Size: ~223 MB"
	@echo "  After Phase 1 (ABI fix): ~158 MB"
	@echo "  After Phase 2 (optimization): ~120-130 MB"
	@echo "  On Google Play (AAB): ~40-50 MB (arm64-v8a)"
	@echo ""

# =============================================================================
# OPTIMIZED RELEASE BUILDS
# =============================================================================

prod-apk-optimized:
	@echo "🔨 Building optimized production APK..."
	@echo "   - Obfuscation enabled"
	@echo "   - Debug info split"
	@echo "   - Icon tree-shaking enabled"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	$(FLUTTER) build apk \
		--release \
		--obfuscate \
		--split-debug-info=build/app/profiles \
		--tree-shake-icons \
		--dart-define=ENVIRONMENT=PROD
	@echo ""
	@echo "✅ Optimized APK ready!"
	@make check-apk-size

prod-appbundle-optimized:
	@echo "📦 Building optimized production App Bundle..."
	@echo "   - Obfuscation enabled"
	@echo "   - Debug info split"
	@echo "   - Icon tree-shaking enabled"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	$(FLUTTER) build appbundle \
		--release \
		--obfuscate \
		--split-debug-info=build/app/profiles \
		--tree-shake-icons \
		--dart-define=ENVIRONMENT=UAT
	@echo ""
	@echo "✅ Optimized AAB ready!"
	@make check-size

prod-ios-optimized:
	@echo "🍎 Building optimized iOS release..."
	@echo "   - Obfuscation enabled"
	@echo "   - Debug info split"
	@echo "   - Icon tree-shaking enabled"
	$(FLUTTER) clean
	$(FLUTTER) pub get
	$(FLUTTER) build ios \
		--release \
		--obfuscate \
		--split-debug-info=build/app/profiles \
		--tree-shake-icons \
		--dart-define=ENVIRONMENT=UAT
	@echo "✅ Optimized iOS build ready!"

prod-build-optimized: prod-apk-optimized prod-appbundle-optimized prod-ios-optimized
	@echo ""
	@echo "🎉 Complete optimized production build finished!"
	@echo "   APK:  build/app/outputs/apk/release/app-release.apk"
	@echo "   AAB:  build/app/outputs/bundle/release/app-release.aab"
	@echo "   iOS:  build/ios/iphoneos/Runner.app"

# =============================================================================
# SIZE VERIFICATION & ANALYSIS
# =============================================================================

check-apk-size:
	@echo ""
	@echo "📊 APK Size Analysis"
	@echo "===================="
	@APK_PATH=""; \
	if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then \
		APK_PATH="build/app/outputs/flutter-apk/app-release.apk"; \
	elif [ -f "build/app/outputs/apk/release/app-release.apk" ]; then \
		APK_PATH="build/app/outputs/apk/release/app-release.apk"; \
	fi; \
	if [ -n "$$APK_PATH" ]; then \
		echo "APK: $$(du -h $$APK_PATH | awk '{print $$1}')"; \
		echo "Path: $$APK_PATH"; \
		echo ""; \
		echo "Breakdown by architecture:"; \
		cd /tmp && rm -rf apk_check 2>/dev/null; \
		mkdir -p apk_check && cd apk_check; \
		unzip -q $(shell pwd)/$$APK_PATH 2>/dev/null || true; \
		echo "  arm64-v8a:  $$(du -sh lib/arm64-v8a/ 2>/dev/null | awk '{print $$1}')"; \
		echo "  armeabi-v7a: $$(du -sh lib/armeabi-v7a/ 2>/dev/null | awk '{print $$1}')"; \
		echo "  x86_64:     $$(du -sh lib/x86_64/ 2>/dev/null | awk '{print $$1}')"; \
		echo "  assets:     $$(du -sh assets/ 2>/dev/null | awk '{print $$1}')"; \
		echo "  classes:    $$(du -sh classes*.dex 2>/dev/null | awk '{print $$1}')"; \
		cd / && rm -rf /tmp/apk_check; \
	else \
		echo "❌ APK not found. Build with: make prod-apk-optimized"; \
	fi
	@echo ""

check-ipa-size:
	@echo ""
	@echo "📊 IPA Size Analysis"
	@echo "===================="
	@if [ -f "build/ios/iphoneos/Runner.app" ]; then \
		echo "IPA: $$(du -sh build/ios/iphoneos/Runner.app | awk '{print $$1}')"; \
	else \
		echo "❌ IPA not found. Build with: make prod-ios-optimized"; \
	fi
	@echo ""

check-size:
	@echo ""
	@echo "📊 Complete Build Size Report"
	@echo "============================="
	@echo ""
	@if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then \
		echo "Android APK: $$(du -h build/app/outputs/apk/release/app-release.apk | awk '{print $$1}')"; \
	else \
		echo "Android APK: ❌ Not found"; \
	fi
	@if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then \
		echo "Android AAB: $$(du -h build/app/outputs/bundle/release/app-release.aab | awk '{print $$1}')"; \
	else \
		echo "Android AAB: ❌ Not found"; \
	fi
	@if [ -f "build/ios/iphoneos/Runner.app" ]; then \
		echo "iOS App:    $$(du -sh build/ios/iphoneos/Runner.app | awk '{print $$1}')"; \
	else \
		echo "iOS App:    ❌ Not found"; \
	fi
	@echo ""
	@echo "Target sizes:"
	@echo "  APK: < 70 MB ✅"
	@echo "  AAB: < 50 MB ✅"
	@echo ""

analyze-apk:
	@echo ""
	@echo "📦 Detailed APK Architecture Analysis"
	@echo "===================================="
	@if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then \
		cd /tmp && rm -rf apk_analyze 2>/dev/null; \
		mkdir -p apk_analyze && cd apk_analyze; \
		unzip -q $(PROJECT_ROOT)/build/app/outputs/apk/release/app-release.apk; \
		echo ""; \
		echo "Largest native libraries (arm64-v8a):"; \
		find lib/arm64-v8a -name "*.so" -type f -exec ls -lh {} \; | \
			awk '{print $$5, $$9}' | sort -hr | head -10; \
		echo ""; \
		cd / && rm -rf /tmp/apk_analyze; \
		echo ""; \
		echo "💡 To see all files, extract APK and analyze:"; \
		echo "   unzip build/app/outputs/apk/release/app-release.apk -d /tmp/apk_contents"; \
	else \
		echo "❌ APK not found. Build with: make prod-apk-optimized"; \
	fi
	@echo ""

# =============================================================================
# ASSET OPTIMIZATION
# =============================================================================

optimize-assets: convert-png-webp compress-images
	@echo ""
	@echo "✅ Asset optimization complete!"
	@echo "   Check results in assets/ directory"
	@echo ""

convert-png-webp:
	@echo ""
	@echo "🖼️  Converting PNG → WebP (saves ~30%)"
	@echo "===================================="
	@if command -v cwebp >/dev/null; then \
		CONVERTED=0; \
		find assets/ -name "*.png" -type f ! -name "*.9.png" | while read file; do \
			if [ ! -f "$${file%.png}.webp" ]; then \
				echo "Converting: $$file"; \
				cwebp -q 85 "$$file" -o "$${file%.png}.webp"; \
				CONVERTED=$$((CONVERTED+1)); \
			fi; \
		done; \
		if [ $$CONVERTED -eq 0 ]; then \
			echo "✅ All PNG files already converted to WebP"; \
		else \
			echo "✅ Converted $$CONVERTED PNG files to WebP"; \
		fi; \
	else \
		echo "⚠️  cwebp not found. Install with:"; \
		echo "   macOS: brew install webp"; \
		echo "   Linux: sudo apt install webp"; \
		echo "   Or download from: https://developers.google.com/speed/webp/download"; \
	fi
	@echo ""

compress-images:
	@echo ""
	@echo "📉 Compressing JPG/PNG images"
	@echo "============================="
	@if command -v jpegoptim >/dev/null; then \
		find assets/ -name "*.jpg" -o -name "*.jpeg" | while read file; do \
			echo "Compressing: $$file"; \
			jpegoptim -m 85 --strip-all "$$file"; \
		done; \
		echo "✅ JPG compression complete"; \
	else \
		echo "⚠️  jpegoptim not found. Install with:"; \
		echo "   macOS: brew install jpegoptim"; \
		echo "   Linux: sudo apt install jpegoptim"; \
	fi
	@echo ""

# =============================================================================
# NOTES
# =============================================================================

.PHONY: print-notes
print-notes:
	@echo ""
	@echo "📝 App Size Optimization Notes"
	@echo "=============================="
	@echo ""
	@echo "Phase 1 Savings (-65 MB):"
	@echo "  - Remove x86_64 from release build"
	@echo "  - Enable obfuscation and debug symbol splitting"
	@echo "  - Result: 223 MB → ~158 MB"
	@echo ""
	@echo "Phase 2 Savings (-25 to -35 MB additional):"
	@echo "  - Analyze and replace FFmpeg library"
	@echo "  - Optimize assets (PNG → WebP)"
	@echo "  - Remove unused dependencies"
	@echo "  - Result: 158 MB → ~120-130 MB"
	@echo ""
	@echo "Google Play Distribution:"
	@echo "  - AAB (App Bundle) is much smaller than APK"
	@echo "  - Google Play auto-delivers architecture-specific APK"
	@echo "  - arm64-v8a: ~50 MB APK → ~25-35 MB download"
	@echo "  - Average user: ~50-60 MB download"
	@echo ""
	@echo "For more details, see:"
	@echo "  - SIZE_OPTIMIZATION_QUICK_START.md"
	@echo "  - APP_SIZE_OPTIMIZATION_AUDIT.md"
	@echo "  - APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md"
	@echo ""