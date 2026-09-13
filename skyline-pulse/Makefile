.PHONY: build lint test server music
build:
	xcodebuild -project SkylinePulse.xcodeproj -scheme SkylinePulse -sdk iphonesimulator -configuration Debug -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
lint:
	swift format lint --strict --recursive App
	cd Server && npm run check
test:
	cd Server && npm test && npm run test:battle
server:
	cd Server && npm start
music:
	node Tools/compose.mjs
	ffmpeg -y -i Assets/neon.wav -c:a aac -b:a 192k Assets/neon.m4a
	ffmpeg -y -i Assets/aurora.wav -c:a aac -b:a 192k Assets/aurora.m4a
	ffmpeg -y -f lavfi -i 'sine=frequency=1800:duration=0.06' -af 'afade=t=out:st=0.005:d=0.055,volume=0.4' -ar 44100 Assets/hit.wav
