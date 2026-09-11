#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Voxelhearth world renderer: a per-pixel DDA ray walk through a 128x64x128
// voxel window stored in four 512x512 textures (8x8 slices of 64x64 per
// quadrant). Every platform runs this same program, which is what gives the
// four clients pixel-identical world rendering.

uniform vec2 uRes;
uniform vec3 uCamPos;
uniform vec3 uFwd;
uniform vec3 uRight;
uniform vec3 uUp;
uniform vec2 uTanFov;
uniform vec3 uOrigin;
uniform float uDay;        // 0..1 fraction of the day (0 = dawn)
uniform float uAnim;       // seconds, for waves / flames / clouds
uniform vec3 uTarget;      // targeted block (window-relative), or -1000
uniform float uBreak;      // 0..1 break progress on target
uniform float uMaxDist;
uniform float uUnderwater; // 1 when the camera is in water
uniform float uEntityCount;
uniform vec2 uAtlasSize;
uniform float uDamage;     // red flash 0..1

uniform sampler2D uVox0;
uniform sampler2D uVox1;
uniform sampler2D uVox2;
uniform sampler2D uVox3;
uniform sampler2D uTiles;    // 256x2: row 0 = top, side, bottom tile index; row 1 = flags
uniform sampler2D uAtlas;    // 16 tiles per row, 16px tiles
uniform sampler2D uEntities; // 128x1, 3 texels per entity

out vec4 fragColor;

const float PI = 3.14159265;
const int MAX_STEPS = 220;

// ---------------------------------------------------------------- data fetch

vec4 vox(vec3 p) {
  if (p.y < 0.0) return vec4(14.0 / 255.0, 0.0, 0.0, 1.0);
  if (p.y > 63.0 || p.x < 0.0 || p.x > 127.0 || p.z < 0.0 || p.z > 127.0) {
    return vec4(0.0, 1.0, 0.0, 1.0);
  }
  float qx = step(64.0, p.x);
  float qz = step(64.0, p.z);
  vec2 local = vec2(p.x - 64.0 * qx, p.z - 64.0 * qz);
  float sx = mod(p.y, 8.0);
  float sy = floor(p.y / 8.0);
  vec2 uv = (vec2(sx * 64.0, sy * 64.0) + local + 0.5) / 512.0;
  if (qx < 0.5) {
    if (qz < 0.5) return texture(uVox0, uv);
    return texture(uVox1, uv);
  }
  if (qz < 0.5) return texture(uVox2, uv);
  return texture(uVox3, uv);
}

float voxId(vec3 p) { return floor(vox(p).r * 255.0 + 0.5); }

vec4 tileInfo(float id) {
  float u = (id + 0.5) / 256.0;
  vec4 t = texture(uTiles, vec2(u, 0.25));
  float flag = texture(uTiles, vec2(u, 0.75)).r;
  return vec4(t.rgb, flag);
}

vec4 atlas(float tile, vec2 uv) {
  uv = clamp(uv, 0.0, 0.999);
  vec2 tileOrigin = vec2(mod(tile, 16.0), floor(tile / 16.0)) * 16.0;
  vec2 px = tileOrigin + floor(uv * 16.0) + 0.5;
  return texture(uAtlas, px / uAtlasSize);
}

// Light 0..1 in the (air) cell p, combining sky and block light.
float lightAt(vec3 p, float dayLight) {
  vec4 v = vox(p);
  float id = floor(v.r * 255.0 + 0.5);
  float sky = v.g;
  float blk = v.b;
  float l = max(sky * dayLight, blk);
  return l;
}

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash12(i);
  float b = hash12(i + vec2(1.0, 0.0));
  float c = hash12(i + vec2(0.0, 1.0));
  float d = hash12(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ---------------------------------------------------------------- sky

vec3 sunDir() {
  float a = uDay * 2.0 * PI;
  return normalize(vec3(cos(a) * 0.55, sin(a), 0.35));
}

float dayLightAmount() {
  float e = sin(uDay * 2.0 * PI);
  return clamp(e * 2.4 + 0.25, 0.06, 1.0);
}

vec3 skyColor(vec3 d, float dayLight) {
  float e = sin(uDay * 2.0 * PI);
  vec3 dayZenith = vec3(0.18, 0.52, 0.67);
  vec3 dayHorizon = vec3(0.80, 0.89, 0.85);
  vec3 nightZenith = vec3(0.015, 0.025, 0.06);
  vec3 nightHorizon = vec3(0.05, 0.07, 0.13);
  float t = clamp(e * 2.4 + 0.25, 0.0, 1.0);
  vec3 zenith = mix(nightZenith, dayZenith, t);
  vec3 horizon = mix(nightHorizon, dayHorizon, t);
  float h = clamp(d.y, 0.0, 1.0);
  vec3 col = mix(horizon, zenith, pow(h, 0.6));
  // Dusk / dawn glow near the sun's azimuth.
  vec3 s = sunDir();
  float twilight = exp(-abs(e) * 9.0);
  float towardSun = pow(max(dot(normalize(vec2(d.x, d.z)), normalize(vec2(s.x, s.z))), 0.0), 3.0);
  col += vec3(0.95, 0.45, 0.15) * twilight * (1.0 - h) * (0.35 + 0.65 * towardSun);
  // Sun and moon discs.
  float sd = dot(d, s);
  col += vec3(1.0, 0.93, 0.75) * smoothstep(0.9985, 0.9995, sd) * t;
  col += vec3(1.0, 0.85, 0.55) * pow(max(sd, 0.0), 180.0) * 0.35 * t;
  float md = dot(d, -s);
  col += vec3(0.85, 0.9, 1.0) * smoothstep(0.9988, 0.9996, md) * (1.0 - t) * 0.9;
  // Stars.
  if (t < 0.6 && d.y > 0.0) {
    vec3 sp = floor(d * 160.0);
    float star = hash12(sp.xy + sp.z * 7.1);
    float twinkle = 0.7 + 0.3 * sin(uAnim * 2.0 + star * 40.0);
    col += vec3(0.9, 0.95, 1.0) * step(0.9965, star) * (1.0 - t / 0.6) * twinkle;
  }
  // Clouds on a plane above the world.
  if (d.y > 0.015) {
    vec2 cp = (uCamPos.xz + d.xz * (90.0 - uCamPos.y) / d.y) * 0.012 + vec2(uAnim * 0.004, 0.0);
    float n = vnoise(cp) * 0.6 + vnoise(cp * 2.3 + 5.0) * 0.3 + vnoise(cp * 5.1 + 9.0) * 0.1;
    float cov = smoothstep(0.52, 0.72, n);
    vec3 cloudCol = mix(vec3(0.08, 0.09, 0.14), vec3(1.0, 0.98, 0.95), t);
    cloudCol += vec3(0.9, 0.4, 0.15) * twilight * 0.5;
    col = mix(col, cloudCol, cov * smoothstep(0.015, 0.12, d.y) * 0.9);
  }
  return col;
}

// ---------------------------------------------------------------- boxes

// Returns (tNear, tFar); miss if tNear > tFar or tFar < 0.
vec2 boxHit(vec3 ro, vec3 rd, vec3 bmin, vec3 bmax, out vec3 n) {
  vec3 inv = 1.0 / rd;
  vec3 t0 = (bmin - ro) * inv;
  vec3 t1 = (bmax - ro) * inv;
  vec3 tmin = min(t0, t1);
  vec3 tmax = max(t0, t1);
  float tn = max(max(tmin.x, tmin.y), tmin.z);
  float tf = min(min(tmax.x, tmax.y), tmax.z);
  n = vec3(0.0);
  if (tn == tmin.x) n = vec3(-sign(rd.x), 0.0, 0.0);
  else if (tn == tmin.y) n = vec3(0.0, -sign(rd.y), 0.0);
  else n = vec3(0.0, 0.0, -sign(rd.z));
  return vec2(tn, tf);
}

vec2 faceUv(vec3 hp, vec3 n) {
  vec3 f = fract(hp);
  if (abs(n.y) > 0.5) return vec2(f.x, f.z);
  if (abs(n.x) > 0.5) return vec2(n.x > 0.0 ? 1.0 - f.z : f.z, 1.0 - f.y);
  return vec2(n.z > 0.0 ? f.x : 1.0 - f.x, 1.0 - f.y);
}

float faceShade(vec3 n, vec3 s, float dayLight) {
  float base = n.y > 0.5 ? 1.0 : (n.y < -0.5 ? 0.55 : (abs(n.x) > 0.5 ? 0.82 : 0.72));
  float sun = max(dot(n, s), 0.0) * 0.18 * dayLight;
  return base + sun;
}

// Smooth lighting: bilinear blend of the four air cells touching the face
// around the hit point. Solid neighbours store zero light, giving soft
// ambient occlusion in corners for free.
float smoothLight(vec3 cell, vec3 n, vec3 hp, float dayLight) {
  vec3 front = cell + n;
  vec3 f = hp - cell;
  vec3 u, v;
  float fu, fv;
  if (abs(n.y) > 0.5) { u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 0.0, 1.0); fu = f.x; fv = f.z; }
  else if (abs(n.x) > 0.5) { u = vec3(0.0, 0.0, 1.0); v = vec3(0.0, 1.0, 0.0); fu = f.z; fv = f.y; }
  else { u = vec3(1.0, 0.0, 0.0); v = vec3(0.0, 1.0, 0.0); fu = f.x; fv = f.y; }
  float su = fu < 0.5 ? -1.0 : 1.0;
  float sv = fv < 0.5 ? -1.0 : 1.0;
  float wu = abs(fu - 0.5);
  float wv = abs(fv - 0.5);
  float l00 = lightAt(front, dayLight);
  float l10 = lightAt(front + u * su, dayLight);
  float l01 = lightAt(front + v * sv, dayLight);
  float l11 = lightAt(front + u * su + v * sv, dayLight);
  // Occluded diagonal: if both edge neighbours are solid the corner is dark.
  float solid10 = voxId(front + u * su) > 0.5 && vox(front + u * su).g + vox(front + u * su).b < 0.001 ? 1.0 : 0.0;
  float solid01 = voxId(front + v * sv) > 0.5 && vox(front + v * sv).g + vox(front + v * sv).b < 0.001 ? 1.0 : 0.0;
  if (solid10 > 0.5 && solid01 > 0.5) l11 = 0.0;
  float a = mix(l00, l10, wu);
  float b = mix(l01, l11, wu);
  return mix(a, b, wv);
}

// ---------------------------------------------------------------- entities

vec4 entityTexel(float i) {
  return texture(uEntities, vec2((i + 0.5) / 128.0, 0.5));
}

vec3 hashColor(float seed) {
  return vec3(0.45 + 0.5 * fract(sin(seed * 12.9898) * 43758.5453),
              0.4 + 0.5 * fract(sin(seed * 78.233) * 43758.5453),
              0.45 + 0.5 * fract(sin(seed * 39.425) * 43758.5453));
}

// Tests the ray against one entity made of a few boxes. Returns hit t or -1.
float entityHit(vec3 ro, vec3 rd, float idx, out vec3 col, out vec3 nrm) {
  vec4 a = entityTexel(idx * 3.0);
  vec4 b = entityTexel(idx * 3.0 + 1.0);
  vec4 k = entityTexel(idx * 3.0 + 2.0);
  float ex = (a.r * 255.0 * 256.0 + a.g * 255.0) / 256.0 - 16.0;
  float ez = (a.b * 255.0 * 256.0 + b.r * 255.0) / 256.0 - 16.0;
  float ey = (b.g * 255.0 * 256.0 + b.b * 255.0) / 256.0 - 16.0;
  float kind = floor(k.r * 255.0 + 0.5);
  float yaw = k.g * 2.0 * PI;
  float hurt = k.b;
  vec3 pos = vec3(ex, ey, ez);
  float seed = floor(kind / 10.0);
  kind = mod(kind, 10.0);

  // Rotate ray into entity space.
  float c = cos(yaw), s = sin(yaw);
  vec3 lo = ro - pos;
  lo = vec3(c * lo.x - s * lo.z, lo.y, s * lo.x + c * lo.z);
  vec3 ld = vec3(c * rd.x - s * rd.z, rd.y, s * rd.x + c * rd.z);

  float best = 1e9;
  vec3 bestN = vec3(0.0);
  vec3 bestCol = vec3(1.0);
  vec3 n;
  vec2 h;
  float bob = sin(uAnim * 6.0 + seed) * 0.03;

  if (kind < 0.5) {
    // Wanderer (player): head, torso, legs, arms.
    vec3 tunic = hashColor(seed + 1.0);
    vec3 skin = vec3(0.93, 0.78, 0.62);
    vec3 trousers = tunic * 0.45;
    h = boxHit(lo, ld, vec3(-0.25, 1.35, -0.25), vec3(0.25, 1.85, 0.25), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n;
      vec3 hp = lo + ld * h.x;
      bestCol = skin;
      // Hair cap and eyes on the front (-z is forward in entity space).
      if (hp.y > 1.72) bestCol = tunic * 0.35;
      if (n.z < -0.5 && hp.y > 1.55 && hp.y < 1.63 && (abs(hp.x - 0.1) < 0.045 || abs(hp.x + 0.1) < 0.045)) bestCol = vec3(0.08, 0.1, 0.14);
    }
    h = boxHit(lo, ld, vec3(-0.25, 0.75, -0.15), vec3(0.25, 1.35, 0.15), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n; bestCol = tunic;
      vec3 hp = lo + ld * h.x;
      if (abs(hp.x) < 0.05 && n.z < -0.5) bestCol = tunic * 0.7;
    }
    h = boxHit(lo, ld, vec3(-0.25, 0.0, -0.13), vec3(0.25, 0.75, 0.13), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n; bestCol = trousers;
      vec3 hp = lo + ld * h.x;
      if (hp.y < 0.12) bestCol = vec3(0.2, 0.14, 0.1);
      if (abs(hp.x) < 0.02) bestCol = trousers * 0.6;
    }
    h = boxHit(lo, ld, vec3(-0.4, 0.75, -0.12), vec3(-0.25, 1.32, 0.12), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) { best = h.x; bestN = n; bestCol = (lo + ld * h.x).y < 0.98 ? skin : tunic; }
    h = boxHit(lo, ld, vec3(0.25, 0.75, -0.12), vec3(0.4, 1.32, 0.12), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) { best = h.x; bestN = n; bestCol = (lo + ld * h.x).y < 0.98 ? skin : tunic; }
  } else if (kind < 1.5) {
    // Mossback: a low, wide grazer with a mossy shell and stubby head.
    vec3 moss = vec3(0.36, 0.55, 0.25);
    vec3 shell = vec3(0.32, 0.27, 0.2);
    h = boxHit(lo, ld, vec3(-0.45, 0.25 + bob, -0.5), vec3(0.45, 1.0 + bob, 0.5), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n;
      vec3 hp = lo + ld * h.x;
      bestCol = hp.y > 0.72 + bob ? moss : shell;
      if (hp.y > 0.72 + bob && fract(hp.x * 3.0 + hp.z * 2.0) > 0.7) bestCol = moss * 1.25;
    }
    h = boxHit(lo, ld, vec3(-0.22, 0.35 + bob, -0.85), vec3(0.22, 0.75 + bob, -0.45), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n; bestCol = shell * 1.15;
      vec3 hp = lo + ld * h.x;
      if (n.z < -0.5 && hp.y > 0.58 + bob && hp.y < 0.66 + bob && abs(abs(hp.x) - 0.11) < 0.035) bestCol = vec3(0.05);
    }
    h = boxHit(lo, ld, vec3(-0.4, 0.0, -0.4), vec3(0.4, 0.3, 0.4), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) { best = h.x; bestN = n; bestCol = shell * 0.75; }
  } else if (kind < 2.5) {
    // Hollow: tall, thin, ash-dark night creature with ember eyes.
    vec3 ash = vec3(0.12, 0.11, 0.14);
    h = boxHit(lo, ld, vec3(-0.22, 1.4, -0.22), vec3(0.22, 1.9, 0.22), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n; bestCol = ash;
      vec3 hp = lo + ld * h.x;
      if (n.z < -0.5 && hp.y > 1.6 && hp.y < 1.7 && abs(abs(hp.x) - 0.09) < 0.05) bestCol = vec3(2.2, 0.9, 0.3);
    }
    h = boxHit(lo, ld, vec3(-0.22, 0.6, -0.14), vec3(0.22, 1.4, 0.14), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n; bestCol = ash * 1.2;
      vec3 hp = lo + ld * h.x;
      if (fract(hp.y * 4.0) < 0.15) bestCol = vec3(0.5, 0.2, 0.08);
    }
    h = boxHit(lo, ld, vec3(-0.2, 0.0, -0.12), vec3(0.2, 0.6, 0.12), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) { best = h.x; bestN = n; bestCol = ash * 0.8; }
  } else {
    // Cinderling: small hopping ember cube.
    vec3 ember = vec3(0.95, 0.35, 0.08);
    float hop = abs(sin(uAnim * 5.0 + seed)) * 0.3;
    h = boxHit(lo, ld, vec3(-0.25, hop, -0.25), vec3(0.25, 0.7 + hop, 0.25), n);
    if (h.x < h.y && h.y > 0.0 && h.x < best) {
      best = h.x; bestN = n;
      vec3 hp = lo + ld * h.x;
      float crack = step(0.75, fract(hp.x * 5.0 + hp.y * 3.0) + fract(hp.z * 4.0) * 0.5);
      bestCol = mix(vec3(0.15, 0.08, 0.06), ember * 1.6, crack);
      if (n.z < -0.5 && hp.y > 0.4 + hop && hp.y < 0.5 + hop && abs(abs(hp.x) - 0.1) < 0.04) bestCol = vec3(2.5, 2.0, 0.6);
    }
  }
  if (best > 1e8) return -1.0;
  // Rotate normal back to world.
  nrm = vec3(c * bestN.x + s * bestN.z, bestN.y, -s * bestN.x + c * bestN.z);
  col = mix(bestCol, vec3(1.0, 0.3, 0.3), hurt * 0.6);
  return best;
}

// ---------------------------------------------------------------- main walk

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 ndc = (frag / uRes) * 2.0 - 1.0;
  vec3 rd = normalize(uFwd + uRight * ndc.x * uTanFov.x - uUp * ndc.y * uTanFov.y);
  vec3 ro = uCamPos - uOrigin;

  float dayLight = dayLightAmount();
  vec3 sun = sunDir();

  // Entities first (cheap), remember nearest.
  float entT = 1e9;
  vec3 entCol = vec3(0.0);
  vec3 entN = vec3(0.0);
  for (int i = 0; i < 24; i++) {
    if (float(i) >= uEntityCount) break;
    vec3 c, n;
    float t = entityHit(ro, rd, float(i), c, n);
    if (t > 0.0 && t < entT) { entT = t; entCol = c; entN = n; }
  }

  vec3 cell = floor(ro);
  vec3 stepDir = sign(rd);
  vec3 safeRd = vec3(abs(rd.x) < 1e-6 ? 1e-6 : rd.x, abs(rd.y) < 1e-6 ? 1e-6 : rd.y, abs(rd.z) < 1e-6 ? 1e-6 : rd.z);
  vec3 tDelta = abs(1.0 / safeRd);
  vec3 tMax = ((stepDir * (cell - ro)) + (stepDir * 0.5) + 0.5) * tDelta;
  vec3 n = vec3(0.0);
  float t = 0.0;

  bool hit = false;
  vec3 hitCell = cell;
  vec3 hitN = vec3(0.0, 1.0, 0.0);
  float hitT = 0.0;
  float hitId = 0.0;
  vec2 hitUv = vec2(0.0);
  float hitTile = 0.0;
  bool startInWater = uUnderwater > 0.5;
  float waterT = -1.0;
  vec3 waterN = vec3(0.0);
  vec3 waterP = vec3(0.0);
  float glassT = -1.0;
  vec4 glassCol = vec4(0.0);

  // If we start inside a solid block, shade it dark immediately.
  float startId = voxId(cell);
  vec4 startInfo = tileInfo(startId);
  float startFlag = floor(startInfo.a * 255.0 + 0.5);
  if (startId > 0.5 && startFlag == 0.0) {
    fragColor = vec4(0.03, 0.03, 0.035, 1.0);
    return;
  }

  for (int i = 0; i < MAX_STEPS; i++) {
    // advance
    if (tMax.x < tMax.y && tMax.x < tMax.z) {
      cell.x += stepDir.x; t = tMax.x; tMax.x += tDelta.x; n = vec3(-stepDir.x, 0.0, 0.0);
    } else if (tMax.y < tMax.z) {
      cell.y += stepDir.y; t = tMax.y; tMax.y += tDelta.y; n = vec3(0.0, -stepDir.y, 0.0);
    } else {
      cell.z += stepDir.z; t = tMax.z; tMax.z += tDelta.z; n = vec3(0.0, 0.0, -stepDir.z);
    }
    if (t > uMaxDist || t > entT) break;
    if (cell.y < 0.0 || cell.y > 63.0) {
      if (cell.y > 63.0 && rd.y > 0.0) break;
      if (cell.y < 0.0) break;
    }
    float id = voxId(cell);
    if (id < 0.5) continue;
    vec4 info = tileInfo(id);
    float flag = floor(info.a * 255.0 + 0.5);
    vec3 hp = ro + rd * t;

    if (flag == 2.0) {
      // water
      if (waterT < 0.0 && !startInWater) { waterT = t; waterN = n; waterP = hp; }
      continue;
    }
    if (flag == 3.0) {
      // glass: remember first pane, keep going
      if (glassT < 0.0) {
        vec2 uv = faceUv(hp, n);
        glassT = t;
        glassCol = atlas(info.g * 255.0, uv);
      }
      continue;
    }
    float tile = abs(n.y) > 0.5 ? (n.y > 0.0 ? info.r : info.b) * 255.0 : info.g * 255.0;
    if (flag == 1.0) {
      // cutout (leaves)
      vec2 uv = faceUv(hp, n);
      vec4 tex = atlas(tile, uv);
      if (tex.a < 0.5) continue;
      hit = true; hitCell = cell; hitN = n; hitT = t; hitId = id; hitUv = uv; hitTile = tile;
      break;
    }
    if (flag >= 4.0) {
      // sub-box decorations
      vec3 bmin, bmax;
      if (flag == 4.0) { bmin = vec3(0.43, 0.0, 0.43); bmax = vec3(0.57, 0.6, 0.57); }        // torch
      else if (flag == 5.0) { bmin = vec3(0.12, 0.0, 0.12); bmax = vec3(0.88, 0.8, 0.88); }   // plant
      else if (flag == 7.0) { bmin = vec3(0.0, 0.0, 0.0); bmax = vec3(1.0, 0.56, 1.0); }      // bed
      else if (flag == 8.0) { bmin = vec3(0.3, 0.0, 0.3); bmax = vec3(0.7, 0.55, 0.7); }      // lantern
      else { bmin = vec3(0.06, 0.0, 0.06); bmax = vec3(0.94, 1.0, 0.94); }                   // cactus
      vec3 bn;
      vec2 bh = boxHit(ro, rd, cell + bmin, cell + bmax, bn);
      if (bh.x < bh.y && bh.y > 0.0 && bh.x < uMaxDist && bh.x < entT) {
        float bt = max(bh.x, 0.0);
        vec3 bp = ro + rd * bt;
        vec3 local = (bp - cell - bmin) / (bmax - bmin);
        vec2 uv;
        if (abs(bn.y) > 0.5) uv = vec2(local.x, local.z);
        else if (abs(bn.x) > 0.5) uv = vec2(bn.x > 0.0 ? 1.0 - local.z : local.z, 1.0 - local.y);
        else uv = vec2(bn.z > 0.0 ? local.x : 1.0 - local.x, 1.0 - local.y);
        float btile = abs(bn.y) > 0.5 ? (bn.y > 0.0 ? info.r : info.b) * 255.0 : info.g * 255.0;
        if (flag == 4.0) {
          // The torch tile paints a 4px stick in columns 6..10; stretch that
          // strip over the thin box instead of showing the tile's empty margin.
          if (abs(bn.y) > 0.5) uv = vec2(mix(0.375, 0.625, uv.x), mix(0.1875, 0.375, uv.y));
          else uv = vec2(mix(0.375, 0.625, uv.x), mix(0.125, 1.0, uv.y));
        }
        if (flag == 5.0) {
          // plants: use the side texture on every face, cutout, no top
          if (abs(bn.y) > 0.5) continue;
          vec4 tex = atlas(btile, uv);
          if (tex.a < 0.5) {
            // try the far side of the same box for the cross look
            vec3 bp2 = ro + rd * bh.y;
            vec3 l2 = (bp2 - cell - bmin) / (bmax - bmin);
            // Leaving through the top/bottom means no far blade face to show.
            if (l2.y < 0.002 || l2.y > 0.998) continue;
            bool exitX = l2.x < 0.002 || l2.x > 0.998;
            vec2 uv2 = exitX ? vec2(l2.z, 1.0 - l2.y) : vec2(l2.x, 1.0 - l2.y);
            vec4 tex2 = atlas(btile, uv2);
            if (tex2.a < 0.5) continue;
            bt = bh.y; bn = -bn; uv = uv2;
          }
        }
        hit = true; hitCell = cell; hitN = bn; hitT = bt; hitId = id; hitUv = uv; hitTile = btile;
        // Keep face shading for lanterns/torches soft.
        break;
      }
      continue;
    }
    // ordinary solid block
    hit = true; hitCell = cell; hitN = n; hitT = t; hitId = id; hitUv = faceUv(hp, n); hitTile = tile;
    break;
  }

  vec3 color;
  float finalT;
  if (entT < 1e8 && (!hit || entT < hitT)) {
    // entity in front
    vec3 ep = ro + rd * entT;
    vec3 ecell = floor(ep + entN * 0.01);
    float l = lightAt(ecell, dayLight);
    float shade = faceShade(entN, sun, dayLight);
    float bright = mix(0.05, 1.0, pow(l, 1.6));
    color = entCol * shade * bright;
    // eyes glow regardless of light
    if (entCol.r > 1.5) color = entCol;
    finalT = entT;
  } else if (hit) {
    vec4 tex = atlas(hitTile, hitUv);
    vec3 hp = ro + rd * hitT;
    vec4 info = tileInfo(hitId);
    float flag = floor(info.a * 255.0 + 0.5);
    // Sub-box decorations live inside their own (air-lit) cell, so sample it
    // directly instead of the neighbour behind the hit face.
    float l = flag >= 4.0 ? lightAt(hitCell, dayLight) : smoothLight(hitCell, hitN, hp, dayLight);
    if (flag == 4.0 || flag == 8.0 || hitId == 13.0) l = max(l, 0.95);
    float bright = mix(0.035, 1.0, pow(l, 1.5));
    float shade = faceShade(hitN, sun, dayLight);
    color = tex.rgb * shade * bright;
    color *= mix(vec3(0.87, 0.98, 1.05), vec3(1.07, 1.02, 0.89), max(dot(hitN, sun), 0.0) * dayLight);
    // torch flame flicker & lantern warmth
    if (flag == 4.0 && hitUv.y < 0.35) color = tex.rgb * (1.3 + 0.3 * sin(uAnim * 14.0 + hp.x * 7.0));
    if (flag == 8.0) color = tex.rgb * 1.25;
    if (hitId == 13.0 && tex.r > tex.b * 1.6) color = tex.rgb * (1.4 + 0.2 * sin(uAnim * 3.0));
    // Block selection outline & break cracks.
    if (all(lessThan(abs(hitCell - uTarget), vec3(0.5)))) {
      vec2 e = min(hitUv, 1.0 - hitUv);
      float edge = min(e.x, e.y);
      float lineW = 0.012 * max(1.0, hitT * 0.9);
      if (edge < lineW) color = mix(color, vec3(1.0, 0.80, 0.46), 0.85);
      if (uBreak > 0.0) {
        vec2 cu = hitUv * 16.0;
        float cr = hash12(floor(cu) + floor(hitCell.xy) * 3.0);
        float cr2 = hash12(floor(cu * 0.5 + 3.0) + hitCell.z);
        float cracks = step(1.0 - uBreak * 0.85, cr * 0.7 + cr2 * 0.3);
        color = mix(color, vec3(0.08, 0.07, 0.06), cracks * 0.85);
      }
    }
    finalT = hitT;
  } else {
    color = skyColor(rd, dayLight);
    finalT = uMaxDist;
  }

  // Glass pane blending.
  if (glassT >= 0.0 && glassT < finalT) {
    vec3 glassTint = vec3(0.78, 0.9, 1.0);
    if (glassCol.a > 0.5) color = mix(color, glassCol.rgb, 0.85);
    else color = mix(color, glassTint, 0.18) * 1.02;
  }

  // Water surface & depth tint.
  if (waterT >= 0.0 && waterT < finalT) {
    float depth = finalT - waterT;
    vec3 deep = vec3(0.04, 0.25, 0.31);
    vec3 shallow = vec3(0.20, 0.65, 0.60);
    float absorb = 1.0 - exp(-depth * 0.32);
    vec3 wcol = mix(shallow, deep, clamp(depth * 0.12, 0.0, 1.0));
    float wl = lightAt(floor(waterP + waterN * 0.01), dayLight);
    wcol *= mix(0.08, 1.0, wl);
    color = mix(color, wcol, 0.45 + 0.5 * absorb);
    // ripples and sun sparkle on the top surface
    if (waterN.y > 0.5) {
      float wave = vnoise(waterP.xz * 3.0 + vec2(uAnim * 0.8, uAnim * 0.55)) + vnoise(waterP.xz * 6.0 - uAnim * 0.6) * 0.5;
      vec3 wn = normalize(vec3((wave - 0.75) * 0.25, 1.0, (vnoise(waterP.zx * 3.0 - uAnim * 0.7) - 0.5) * 0.25));
      vec3 refl = reflect(rd, wn);
      float spec = pow(max(dot(refl, sun), 0.0), 90.0) * dayLight;
      color += vec3(1.0, 0.95, 0.8) * spec * 0.9;
      color += skyColor(refl, dayLight) * 0.12;
    }
  }

  // Distance fog into the sky colour.
  vec3 fogCol = skyColor(normalize(vec3(rd.x, max(rd.y, 0.02), rd.z)), dayLight);
  float fog = 1.0 - exp(-pow(finalT / uMaxDist, 2.6) * 3.5);
  if (!hit && entT > 1e8) fog = 0.0;
  color = mix(color, fogCol, fog);

  if (uUnderwater > 0.5) {
    color = mix(color, vec3(0.08, 0.28, 0.5), clamp(0.35 + finalT * 0.05, 0.0, 0.9));
  }

  // Damage flash.
  color = mix(color, vec3(0.7, 0.05, 0.05), uDamage * 0.45);

  // Gentle tonemap + vignette.
  color = color / (color + 0.65) * 1.55;
  vec2 vc = frag / uRes - 0.5;
  color *= 1.0 - dot(vc, vc) * 0.35;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
