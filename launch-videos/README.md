# Launch video templates

Twenty reusable 16:9 product-launch video templates for Devin, each exploring a
different visual direction while sharing the same footage, copy, and brand tokens so
they can be compared directly. Templates are Remotion projects; the test render for all
of them is the "Devin on Mac" launch.

```
launch-videos/
  assets/        real product footage, screenshots, logos (shared, read-only)
  brief/
    brand.md            Devin design tokens (from the Devin Figma file)
    launch-mac-vm.md    the test launch: canonical copy, approved claims, footage map
    assets.md           what every screenshot / recording shows
    templates.md        the 20 template directions
    template-contract.md  the technical contract every template follows
  templates/
    01-swiss-grid/ ... 20-pure-product-demo/   one Remotion project each
```

Run a template:

```sh
cd launch-videos/templates/01-swiss-grid
npm install
npm run dev      # Remotion Studio
npm run render   # out/launch.mp4
```

Swap the launch: edit `defaultProps` in `src/Root.tsx` or pass
`npx remotion render Launch out/x.mp4 --props=./my-launch.json`.
