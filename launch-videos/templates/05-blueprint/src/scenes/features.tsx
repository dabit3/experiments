import React from "react";
import { Feature } from "./Feature";

/** Fig. 03 — Devin plans, builds and runs the app (web-13 → web-9). */
export const Build: React.FC = () => (
  <Feature
    shots={[
      { src: "screens/devin-web-13.png", from: 0 },
      { src: "screens/devin-web-9.png", from: 118 },
    ]}
    motion={[
      { at: 40, scale: 1.0, fx: 0.5, fy: 0.5 },
      { at: 118, scale: 1.1, fx: 0.42, fy: 0.62 },
      { at: 222, scale: 1.18, fx: 0.36, fy: 0.5 },
    ]}
    dimension="Session · macOS · Fable 5.1"
    regions={[{ x: 0.24, y: 0.685, w: 0.125, h: 0.1, at: 60, until: 118 }]}
    callouts={[
      { u: 0.24, v: 0.735, side: "left", ly: 610, label: "Executing actions", sub: "1 task created", at: 62, until: 118 },
      { u: 0.035, v: 0.48, side: "left", ly: 400, label: "Simulator run", sub: "12 passed · 3 failed", at: 140 },
      { u: 0.965, v: 0.39, side: "right", ly: 300, label: "Ready to merge", sub: "PR #161", at: 165 },
    ]}
    lines={[
      { text: "Devin builds the app in Xcode.", at: 14, until: 124 },
      { text: "Then runs it in the iOS Simulator.", at: 130 },
    ]}
  />
);

/** Fig. 04 — live iPhone Simulator tab (web-11 → web-10). */
export const Simulator: React.FC = () => (
  <Feature
    shots={[
      { src: "screens/devin-web-11.png", from: 0 },
      { src: "screens/devin-web-10.png", from: 112 },
    ]}
    motion={[
      { at: 40, scale: 1.0, fx: 0.5, fy: 0.5 },
      { at: 234, scale: 1.2, fx: 0.38, fy: 0.5 },
    ]}
    dimension="iPhone 17 Pro · iOS 26.5 · live"
    regions={[{ x: 0.232, y: 0.145, w: 0.185, h: 0.74, at: 44 }]}
    callouts={[
      { u: 0.232, v: 0.5, side: "left", ly: 470, label: "Taps · types · scrolls", sub: "you can tap too", at: 60 },
      { u: 0.98, v: 0.115, side: "right", ly: 220, label: "12 passed · 3 failed", sub: "feature checks", at: 128 },
    ]}
    cursor={{
      stops: [
        { x: 0.56, y: 0.62, at: 50 },
        { x: 0.335, y: 0.42, at: 80, click: true },
        { x: 0.33, y: 0.8, at: 104, click: true },
      ],
      hideAt: 118,
    }}
    lines={[
      { text: "A live iPhone Simulator, inside the session.", at: 14, until: 120 },
      { text: "Devin taps, types and scrolls. So can you.", at: 126 },
    ]}
  />
);

/** Fig. 05 — reproduce, fix, re-test, open a PR (web-9, push into the PR panel). */
export const Fix: React.FC = () => (
  <Feature
    shots={[{ src: "screens/devin-web-9.png", from: 0 }]}
    motion={[
      { at: 40, scale: 1.0, fx: 0.5, fy: 0.5 },
      { at: 120, scale: 1.04, fx: 0.5, fy: 0.5 },
      { at: 210, scale: 1.28, fx: 0.68, fy: 0.36 },
    ]}
    dimension="Wisp · native iOS chat client"
    callouts={[
      { u: 0.035, v: 0.25, side: "left", ly: 300, label: "Repro in simulator", sub: "12 passed · 3 failed", at: 48, until: 150 },
      { u: 0.965, v: 0.19, side: "right", ly: 240, label: "PR #161 · open", sub: "27 files · +2257", at: 132 },
      { u: 0.965, v: 0.39, side: "right", ly: 420, label: "UI tests re-run", sub: "ready to merge", at: 160 },
    ]}
    cursor={{
      stops: [
        { x: 0.3, y: 0.62, at: 46 },
        { x: 0.17, y: 0.48, at: 78, click: true },
        { x: 0.83, y: 0.034, at: 122, click: true },
        { x: 0.6, y: 0.39, at: 165 },
      ],
    }}
    lines={[
      { text: "It reproduces the bug and fixes it.", at: 14, until: 120 },
      { text: "Re-runs the UI tests. Opens the PR.", at: 126 },
    ]}
  />
);

/** Fig. 06 — device matrix: dark-mode iPhone grid (web-17) → iPad (web-19). */
export const Matrix: React.FC = () => (
  <Feature
    shots={[
      { src: "screens/devin-web-17.png", from: 0 },
      { src: "screens/devin-web-19.png", from: 124 },
    ]}
    motion={[
      { at: 40, scale: 1.08, fx: 0.4, fy: 0.42 },
      { at: 124, scale: 1.14, fx: 0.4, fy: 0.62 },
      { at: 222, scale: 1.06, fx: 0.42, fy: 0.5 },
    ]}
    dimension="iPhone 17 Pro · iPad Pro 13-inch · dark mode"
    regions={[{ x: 0.14, y: 0.37, w: 0.525, h: 0.6, at: 46, until: 124 }]}
    callouts={[
      { u: 0.035, v: 0.5, side: "left", ly: 480, label: "6 screens · dark mode", sub: "pixel-for-pixel diff", at: 60, until: 124 },
      { u: 0.965, v: 0.5, side: "right", ly: 480, label: "iPad Pro 13-inch", sub: "6 passed · 0 failed", at: 140 },
    ]}
    lines={[
      { text: "Every size. Dark mode. Every orientation.", at: 14, until: 122 },
      { text: "Screenshots compared pixel for pixel.", at: 128 },
    ]}
  />
);
