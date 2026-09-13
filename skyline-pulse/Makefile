.PHONY: build lint test server music computer-use-check computer-use-build
build:
	xcodebuild -project SkylinePulse.xcodeproj -scheme SkylinePulse -sdk iphonesimulator -configuration Debug -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
lint:
	swift format lint --strict --recursive App
	cd Server && npm run check
	$(MAKE) computer-use-check
computer-use-check:
	python3 -m py_compile Tools/computer-use/*.py
	python3 -m tabnanny Tools/computer-use
	node --check Tools/computer-use/proxy.mjs
	swiftc -typecheck Tools/computer-use/gestures.swift
	swiftc -typecheck Tools/computer-use/capture-audio.swift
	swiftc -parse-as-library -typecheck Tools/computer-use/capture-video.swift
computer-use-build:
	swiftc Tools/computer-use/gestures.swift -o Tools/computer-use/gestures
	swiftc Tools/computer-use/capture-audio.swift -o Tools/computer-use/capture-audio
	swiftc -parse-as-library Tools/computer-use/capture-video.swift -o Tools/computer-use/capture-video
test:
	cd Server && npm test && npm run test:battle
server:
	cd Server && npm start
music:
	node Tools/compose.mjs
	ffmpeg -y -i Assets/neon.wav -c:a aac -b:a 192k Assets/neon.m4a
	ffmpeg -y -i Assets/aurora.wav -c:a aac -b:a 192k Assets/aurora.m4a
	ffmpeg -y -f lavfi -i 'sine=frequency=1800:duration=0.06' -af 'afade=t=out:st=0.005:d=0.055,volume=0.4' -ar 44100 Assets/hit.wav
