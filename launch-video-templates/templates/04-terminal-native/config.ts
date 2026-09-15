export type SceneKind = 'hook' | 'context' | 'build' | 'interact' | 'fix' | 'evidence' | 'outcome' | 'end';

export type Scene = {
  kind: SceneKind;
  start: number;
  seconds: number;
  label: string;
  command: string;
  headline: string[];
  lines: string[];
};

export const config = {
  title: 'devin / native',
  font: '"SFMono-Regular", Menlo, Consolas, monospace',
  commandStartFrame: 5,
  commandEndFrame: 27,
  revealFrame: 30,
  revealDuration: 22,
  logStartFrame: 50,
  logStepFrames: 20,
  evidenceSourceStartSeconds: 14,
  evidenceExpandStartFrame: 105,
  evidenceExpandEndFrame: 149,
  scenes: [
    {
      kind: 'hook', start: 0, seconds: 4.5, label: 'HELLO, NATIVE',
      command: "printf 'Hello, native.\\n'",
      headline: ['Devin goes', 'native.'],
      lines: ['Your coding agent.', 'Now on macOS + iOS.'],
    },
    {
      kind: 'context', start: 4.5, seconds: 3.5, label: 'THE OLD LOOP',
      command: 'cat workflow.before',
      headline: ['QA meant', 'waiting.'],
      lines: ['Manual checks.', 'Or 20+ minutes for CI feedback.'],
    },
    {
      kind: 'build', start: 8, seconds: 6, label: '01 / BUILD + RUN',
      command: 'xcodebuild -scheme MyApp build',
      headline: ['Build it.', 'Run it.'],
      lines: ['A managed Mac VM.', 'Xcode builds your app.', 'Run it in Simulator.'],
    },
    {
      kind: 'interact', start: 14, seconds: 6, label: '02 / INTERACT',
      command: 'open -a Simulator',
      headline: ['Tap. Type.', 'Scroll.'],
      lines: ['Devin interacts with your app.', 'In iOS Simulator.'],
    },
    {
      kind: 'fix', start: 20, seconds: 6, label: '03 / REPRODUCE + FIX + RETEST',
      command: 'git diff',
      headline: ['Reproduce.', 'Fix. Retest.'],
      lines: ['Find the failure.', 'Update the code.', 'Run the checks again.'],
    },
    {
      kind: 'evidence', start: 26, seconds: 7.5, label: '04 / REVIEW EVIDENCE',
      command: 'open evidence/',
      headline: ['Review the', 'recording.'],
      lines: ['See what happened.', 'Inspect the evidence.'],
    },
    {
      kind: 'outcome', start: 33.5, seconds: 5, label: 'THE NEW LOOP',
      command: "printf 'Ready to inspect.\\n'",
      headline: ['A working app.', 'In your session.'],
      lines: ['A live iPhone Simulator.', 'Same price as Linux VMs.'],
    },
    {
      kind: 'end', start: 38.5, seconds: 3.5, label: 'MACOS + IOS',
      command: "printf 'Build. Run. See it.\\n'",
      headline: ['Build. Run. See it.'],
      lines: [],
    },
  ] satisfies Scene[],
} as const;
