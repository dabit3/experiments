import assert from 'node:assert/strict';
import {existsSync, readdirSync, readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import ts from 'typescript';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const folders = readdirSync(resolve(root, 'templates')).filter((name) => /^\d{2}-/.test(name)).sort();
assert.equal(folders.length, 20);
for (const id of folders) {
  const dir = resolve(root, 'templates', id);
  let videoCount = 0;
  for (const name of readdirSync(dir).filter((name) => /\.tsx?$/.test(name) && !name.endsWith('.d.ts'))) {
    const file = resolve(dir, name);
    const source = readFileSync(file, 'utf8');
    assert(!/\b(?:Math\.random|Date\.now|setTimeout|setInterval)\s*\(/.test(source), file);
    assert(!/\b(?:animation|animationName|transition)\s*:/.test(source), file);
    assert(!/(?:https?:\/\/|data:)/.test(source), `${file}: remote or embedded media`);
    const ast = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true);
    const visit = (node) => {
      if (ts.isJsxSelfClosingElement(node) || ts.isJsxOpeningElement(node)) {
        if (node.tagName.getText(ast) === 'OffthreadVideo') {
          videoCount++;
          const mute = node.attributes.properties.find((property) =>
            ts.isJsxAttribute(property) && property.name.getText(ast) === 'muted');
          assert(mute && (!mute.initializer || mute.initializer.getText(ast) === '{true}'),
            `${file}: source video must be explicitly muted`);
        }
      }
      if (ts.isStringLiteral(node) && /\.(png|mp4|wav)$/.test(node.text)) {
        const asset = node.text.startsWith('assets/') ? resolve(root, 'public', node.text)
          : node.text.startsWith('.') ? resolve(dir, node.text) : resolve(root, 'public/assets', node.text);
        assert(existsSync(asset), `${file}: missing local asset ${node.text}`);
      }
      ts.forEachChild(node, visit);
    };
    visit(ast);
  }
  assert(videoCount > 0, `${id}: missing actual video insert`);
  for (const required of ['index.tsx', 'config.ts', 'template.json', 'README.md']) {
    assert(existsSync(resolve(dir, required)), `${id}: missing ${required}`);
  }
  console.log(`${id}: local assets, source-video mute and deterministic timing checks passed`);
}
