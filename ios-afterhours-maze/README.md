# Afterhours Maze

A native, offline iPhone maze chase. A hungry comet collects warm pearl lights through two sapphire circuits while four rival spirits hunt, ambush, flank, and retreat. Built with SwiftUI Canvas and a deterministic, separately tested Swift simulation. Original code, vector artwork, synthesized chimes, and icon; no external assets or services.

## Build and run

Requires macOS, Xcode 16+ with an iOS Simulator runtime, Swift 6, and XcodeGen 2.46.

```sh
brew install xcodegen
cd ios-afterhours-maze
xcodegen generate
xcodebuild -project AfterhoursMaze.xcodeproj -scheme AfterhoursMaze \
  -sdk iphonesimulator -configuration Debug -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Open the generated project in Xcode, select an iPhone Simulator, and Run. Alternatively, after booting a Simulator:

```sh
xcrun simctl install booted DerivedData/Build/Products/Debug-iphonesimulator/AfterhoursMaze.app
xcrun simctl launch booted studio.afterhours.maze
```

The project is generated from `project.yml`; generated metadata and build products are ignored. The app supports portrait iPhone layouts on iOS 17+. Device installation requires your own signing configuration; Simulator play needs no credentials.

## Play

The title screen runs a live attract-mode demo (an autopilot comet playing a real game); tap it to jump straight in. Select Blue Hour or Velvet Circuit, then **Enter the maze**. Swipe anywhere on the board or tap a wedge of the steering dial below it (the dial's comet points along the queued direction). Turns queue until the next legal corner; the opposite direction reverses immediately. Your comet moves automatically, stopping at walls. Side tunnels wrap to the opposite edge.

- Pearl: **10** points. Power orb: **50**.
- Power lasts 10 seconds initially, with a gentle reduction on later circuits. Frightened rivals turn mint and slow down; their final two seconds flash.
- Catch rivals during one power window for **200 / 400 / 800 / 1,600**.
- Clear every light for **1,000** and an extra life (maximum five), then continue into the other maze.
- Three lives per fresh run. Each lost life resets actors with a protected spawn and staggered rival release.
- Rivals alternate 7 seconds of scatter with 20 seconds of chase: direct pursuit, ambush ahead, vector flank, and a shy rival that retreats when close.
- Pause freezes the simulation; backgrounding also pauses and requires an explicit resume.
- Best score and sound preference persist locally using UserDefaults. There is no global leaderboard.
- Sound respects the system silent switch. Haptics run on supported iPhones; the Simulator may not reproduce them.

## Checks

```sh
bash Scripts/check.sh
```

This runs Swift's formatter as a strict scoped lint, `swift test` (maze connectivity, tunnels, combo scoring, collisions, pause, progression, deterministic wall safety), then a real iOS Simulator compilation.

To regenerate the original icon:

```sh
swift Scripts/GenerateIcon.swift Sources/AfterhoursApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## Scope

Two original mazes repeat with modest speed increases. This is a focused V1 inspired by classic maze chase rules, without commercial character art, level parity, ads, purchases, account requirements, or network access. Reduced Motion disables pellet pulsing and nonessential flashing. Gameplay is visual and real-time; VoiceOver labels describe controls and status but do not turn the game into a nonvisual experience.
