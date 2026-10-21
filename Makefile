XCODEPROJ := CatWalk.xcodeproj
CONFIGURATION := Debug
DERIVED_DATA := tmp/DerivedData
IOS_APP := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/Cat Walk.app
IOS_BUNDLE_ID := com.bannzai.CatWalkiOS

.PHONY: build-macos build-ios build-watchos ios test clean

# CI と同じ生成物を作るため code signing は無効にする
build-macos:
	xcodebuild -project $(XCODEPROJ) -scheme CatWalk -configuration $(CONFIGURATION) -derivedDataPath $(DERIVED_DATA) -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

build-ios:
	xcodebuild -project $(XCODEPROJ) -scheme CatWalkiOS -configuration $(CONFIGURATION) -derivedDataPath $(DERIVED_DATA) -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

build-watchos:
	xcodebuild -project $(XCODEPROJ) -scheme CatWalkWatch -configuration $(CONFIGURATION) -derivedDataPath $(DERIVED_DATA) -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build

# Simulator 向けビルドを sim-boot で起動した simulator にインストールして起動する
ios: build-ios
	@set -e; \
	simulator_udid="$${SIMULATOR_UDID:-$$(SCRIPT_QUIET=1 sim-boot | sed -n 's/^DEVICE_UDID=//p' | tail -n 1)}"; \
	[ -n "$$simulator_udid" ] || { echo "Error: sim-boot でSimulatorを解決できません (sim-bootがPATHにあるか確認するか、SIMULATOR_UDID=<UDID>を指定してください)" >&2; exit 1; }; \
	xcrun simctl install "$$simulator_udid" "$(IOS_APP)"; \
	xcrun simctl launch "$$simulator_udid" $(IOS_BUNDLE_ID)

test:
	xcodebuild -project $(XCODEPROJ) -scheme CatWalk -derivedDataPath $(DERIVED_DATA) -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test

clean:
	rm -rf $(DERIVED_DATA)

# build と test は同じ DerivedData を使うため、-j 指定でも並列に起動させない
.NOTPARALLEL:

# Release ビルドを /Applications に配置して普段使いできるようにする
# Release にする理由・/Applications に置く理由・lsregister -f を打つ理由:
#   https://github.com/bannzai/PUTS/blob/main/documents/adr/0009-install-release-build-to-applications.md
# 起動は自動では行わない (ssh 越しの実行を想定)
.PHONY: macos
INSTALL_APP := /Applications/CatWalk.app
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

macos:
	xcodebuild -project 'CatWalk.xcodeproj' -scheme 'CatWalk' \
		-configuration Release \
		-destination 'platform=macOS' \
		-derivedDataPath 'tmp/DerivedData' \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		build
	rm -rf $(INSTALL_APP)
	ditto 'tmp/DerivedData/Build/Products/Release/CatWalk.app' $(INSTALL_APP)
	$(LSREGISTER) -f $(INSTALL_APP)
	@echo "起動するには: open $(INSTALL_APP)"

# Debug ビルドを Release と同じ /Applications/CatWalk.app に上書き配置する。
# Debug ビルドにしか無い操作 (開発者メニュー等) を普段使いのデータに対して行うための一時的な配置で、
# 終わったら make macos で Release に戻す
# 起動は自動では行わない (ssh 越しの実行を想定)
# project の Debug は runner 向けの ad-hoc 署名のため、普段使いのデータ (App Sandbox の container) を
# Release と同じ署名で開けるよう自動署名で上書きする
.PHONY: macos-debug

macos-debug:
	xcodebuild -project 'CatWalk.xcodeproj' -scheme 'CatWalk' \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath 'tmp/DerivedData' \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=TQPN82UBBY \
		build
	rm -rf $(INSTALL_APP)
	ditto 'tmp/DerivedData/Build/Products/Debug/CatWalk.app' $(INSTALL_APP)
	$(LSREGISTER) -f $(INSTALL_APP)
	@echo "起動するには: open $(INSTALL_APP)"
	@echo "Release に戻すには: make macos"

# 引数なしの make で macos を実行する (人が手で動作確認するための入口。検査・テストは CI が行う)
.DEFAULT_GOAL := macos
