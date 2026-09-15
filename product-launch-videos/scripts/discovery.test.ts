import assert from 'node:assert/strict';
import {test} from 'node:test';
import {parseManifest} from './discovery';

const manifest = {
  schemaVersion: 1, slug: '01-swiss-grid', name: 'Example', description: 'Contract test',
  compositionId: 'SwissGrid',
};

test('manifest discovery enforces directory ownership and Remotion-safe IDs', () => {
  assert.deepEqual(parseManifest(manifest, manifest.slug), manifest);
  assert.throws(() => parseManifest(manifest, '02-industrial'));
  assert.throws(() => parseManifest({...manifest, slug: '../outside'}, '../outside'));
  assert.throws(() => parseManifest({...manifest, compositionId: 'illegal_id'}, manifest.slug));
  assert.throws(() => parseManifest({...manifest, schemaVersion: 2}, manifest.slug));
  assert.throws(() => parseManifest({...manifest, name: ''}, manifest.slug));
  assert.throws(() => parseManifest(null, manifest.slug));
});
