# Recorded agreement scenario

Access resolved: browser-only app, no login/credentials, Vite localhost:5173 reachable.
Open questions answered: new app; reload resets in-memory state. Native UI steps and controls confirmed in src/steps/PageOne.tsx:28–69, PageTwo.tsx:26–118, SignStep.tsx:20–47; validation/navigation src/App.tsx:152–164; generation/export :179–208; review src/steps/ReviewStep.tsx:81–211; certificate src/lib/pdf.ts:240–264.

All app interactions use real computer mouse/keyboard only. Record continuously and capture 4–8 full screenshots.

1. Fill page 1 with Jordan Rivera / Rivera Design Co / (415) 555-0142 / 221 Baker Street / San Francisco / California (CA) / 94110 / 10/01/2026–03/31/2027. Leave email empty; draw JR initials with multi-point strokes. Pass: values and initials visibly retained.
2. Click Continue. Pass: stays page 1, inline “Email address is required”, toast, VALIDATION audit event. Observe shake; mark inconclusive if not objectively captured.
3. Fill jordan@riveradesign.co and click Continue. Pass: page 2 opens.
4. Click Hourly, enter 125, select Net 30; tick IP, confidentiality and optional updates; enter “Weekly status report every Friday.”; draw JR initials. Continue. Pass: all values retained and Sign opens.
5. Draw cursive Jordan Rivera in Draw mode using multi-point strokes, enter 09/09/2026, click Review agreement. Pass: signature and date retained.
6. Review. Pass: green “All required items complete”, header 18/18, exact entered values, signature and both initials previews.
7. Click Generate PDF. Pass: contractor-agreement-jordan-rivera.pdf downloaded, result shows pages/size/document ID, downloaded toast and PDF audit events.
8. Verify download using ls and pypdf; render using pymupdf. Pass: 3 pages, Jordan Rivera, 2026-09-09, October 1, 2026, Certificate of completion and audit events; signature/initials visible in rendered pages. Report actual pagination if different.
9. Scroll audit panel to show validation, initials, signature, PDF events; optionally Export as JSON. Pass: events timestamped and export downloads valid JSON.
