.PHONY: server check build project

server:
	cd server && npm ci --ignore-scripts && npm start

check:
	swift format lint --strict --recursive App Tests
	cd server && npm ci --ignore-scripts && npm run check && npm test && npm audit

project:
	xcodegen generate

build:
	xcodebuild -project HiveSovereign.xcodeproj -scheme HiveSovereign \
	  -configuration Debug -sdk iphonesimulator \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath .build build CODE_SIGNING_ALLOWED=NO
