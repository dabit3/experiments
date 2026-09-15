import assert from 'node:assert/strict';
import {test} from 'node:test';
import {contain, mediaGeometry} from './geometry';

test('contain never distorts source aspect ratio or crops reports', () => {
  const geometry = mediaGeometry({width: 2988, height: 1622}, {width: 1800, height: 820});
  assert.equal(geometry.mediaHeight, 820);
  assert.equal(geometry.mediaWidth / geometry.mediaHeight, 2988 / 1622);
  assert.equal(geometry.mediaLeft, 0);
  assert.equal(geometry.mediaTop, 0);
  assert.ok(geometry.cropLeft > 0);
});

test('cover anchors and source-pixel inspection windows preserve the same scale on both axes', () => {
  const cover = mediaGeometry({width: 1000, height: 500}, {width: 500, height: 500},
    {...contain, fit: 'cover', anchorX: 1});
  assert.equal(cover.cropLeft, -500);
  const crop = mediaGeometry({width: 1000, height: 500}, {width: 400, height: 400},
    {...contain, crop: {x: 500, y: 100, width: 200, height: 200}});
  assert.equal(crop.mediaLeft, -1000);
  assert.equal(crop.mediaTop, -200);
  assert.equal(crop.mediaWidth, 2000);
  assert.equal(crop.mediaHeight, 1000);
});

test('invalid crop coordinates fail instead of rendering empty or stretched footage', () => {
  const source = {width: 100, height: 100};
  assert.throws(() => mediaGeometry(source, source, {...contain, anchorX: 1.2}));
  assert.throws(() => mediaGeometry(source, source, {...contain,
    crop: {x: 50, y: 0, width: 100, height: 100}}));
  assert.throws(() => mediaGeometry(source, {width: 0, height: 100}));
});
