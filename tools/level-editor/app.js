'use strict';

const TARGET_W = 40;
const TARGET_H = 40;
const MIN_FILL_CELLS = 36;
const SCHEMA_VERSION = 1;

const SUPER_SAMPLE = 4;
const WORK_W = TARGET_W * SUPER_SAMPLE;
const WORK_H = TARGET_H * SUPER_SAMPLE;

const MINERAL_COLORS = [
  [0.90, 0.28, 0.35], [0.28, 0.78, 0.42], [0.30, 0.55, 0.95], [0.95, 0.82, 0.18],
  [0.65, 0.95, 0.35], [0.07, 0.08, 0.11], [0.92, 0.94, 0.98], [0.55, 0.38, 0.24],
  [0.95, 0.52, 0.18], [0.62, 0.32, 0.88], [0.72, 0.74, 0.78], [0.50, 0.52, 0.56],
  [0.14, 0.24, 0.58], [0.35, 0.88, 0.92], [0.95, 0.45, 0.65], [0.55, 0.12, 0.22],
  [0.85, 0.68, 0.22], [0.28, 0.72, 0.68], [0.88, 0.78, 0.62], [0.22, 0.38, 0.82],
];

const COLOR_NAMES = [
  'Красный', 'Зелёный', 'Синий', 'Жёлтый', 'Салатовый',
  'Чёрный', 'Белый', 'Коричневый', 'Оранжевый', 'Фиолетовый',
  'Серебро', 'Серый', 'Тёмно-синий', 'Голубой', 'Розовый',
  'Бордовый', 'Золотой', 'Мятный', 'Бежевый', 'Сапфир',
];

const BLUE_MINERALS = new Set([2, 12, 13, 19]);
const GREY_MINERALS = new Set([5, 10, 11]);

const SPACE_COLOR = MINERAL_COLORS[5];
const BLACK_MINERAL = 5;
const WHITE_MINERAL = 6;
const DARK_BG_LUM = 0.48;
const LIGHT_BG_LUM = 0.82;
const DARK_DETAIL_LUM = 0.26;
const DETAIL_MINERALS = new Set([BLACK_MINERAL]);

let sourceImage = null;
let lastExport = null;
let editState = null;

const EDIT_TOOLS = { PAINT: 'paint', ERASE: 'erase', PICK: 'pick' };
const PREVIEW_MAX_PX = 480;
const EMPTY_CELL = '.';

let currentTool = EDIT_TOOLS.PAINT;
let selectedMineral = BLACK_MINERAL;
let isPainting = false;
let hoverCell = null;
let lastPaintCell = null;
let lastPaletteKey = '';

const els = {
  fileInput: document.getElementById('fileInput'),
  dropZone: document.getElementById('dropZone'),
  levelId: document.getElementById('levelId'),
  themeName: document.getElementById('themeName'),
  maxColors: document.getElementById('maxColors'),
  convertBtn: document.getElementById('convertBtn'),
  downloadBtn: document.getElementById('downloadBtn'),
  loadExampleBtn: document.getElementById('loadExampleBtn'),
  stats: document.getElementById('stats'),
  sourceCanvas: document.getElementById('sourceCanvas'),
  previewCanvas: document.getElementById('previewCanvas'),
  palettePanel: document.getElementById('palettePanel'),
  paletteList: document.getElementById('paletteList'),
  jsonPanel: document.getElementById('jsonPanel'),
  jsonOutput: document.getElementById('jsonOutput'),
  editToolbar: document.getElementById('editToolbar'),
  mineralPicker: document.getElementById('mineralPicker'),
};

const EXAMPLE_PATH = 'examples/example_astronaut_pixel.png';

function colorToCss([r, g, b]) {
  return `rgb(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)})`;
}

function linearize(v) {
  return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
}

function labF(t) {
  return t > 0.008856 ? t ** (1 / 3) : 7.787 * t + 16 / 116;
}

function rgbToLab(r, g, b) {
  const R = linearize(r);
  const G = linearize(g);
  const B = linearize(b);
  let x = (R * 0.4124564 + G * 0.3575761 + B * 0.1804375) / 0.95047;
  let y = R * 0.2126729 + G * 0.7151522 + B * 0.0721750;
  let z = (R * 0.0193339 + G * 0.1191920 + B * 0.9503041) / 1.08883;
  x = labF(x);
  y = labF(y);
  z = labF(z);
  return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}

function labDistance(a, b) {
  const dl = a[0] - b[0];
  const da = a[1] - b[1];
  const db = a[2] - b[2];
  return Math.sqrt(dl * dl + da * da + db * db);
}

function saturation(r, g, b) {
  const mx = Math.max(r, g, b);
  const mn = Math.min(r, g, b);
  return mx <= 0.001 ? 0 : (mx - mn) / mx;
}

function luminance(r, g, b) {
  return 0.299 * r + 0.587 * g + 0.114 * b;
}

function tierFromChar(ch) {
  if (ch === '.' || ch === ' ') return -1;
  if (ch >= '0' && ch <= '9') return parseInt(ch, 10);
  if (ch >= 'a' && ch <= 'j') return ch.charCodeAt(0) - 97 + 10;
  if (ch >= 'A' && ch <= 'J') return ch.charCodeAt(0) - 65 + 10;
  return 0;
}

function charFromTier(tier) {
  tier = Math.max(0, Math.min(19, tier));
  return tier < 10 ? String(tier) : String.fromCharCode(97 + tier - 10);
}

function nearestMineral(r, g, b) {
  const lab = rgbToLab(r, g, b);
  const lum = luminance(r, g, b);
  const sat = saturation(r, g, b);
  const blueish = b > r * 1.02 && b >= g * 0.92;
  const cyanish = b > 0.45 && g > 0.45 && r < 0.35;
  const whitish = lum > 0.82 && sat < 0.18;
  let best = 0;
  let bestD = Infinity;
  for (let i = 0; i < MINERAL_COLORS.length; i++) {
    const mc = MINERAL_COLORS[i];
    let d = labDistance(lab, rgbToLab(mc[0], mc[1], mc[2]));
    if (blueish || cyanish) {
      if (BLUE_MINERALS.has(i)) d *= 0.55;
      if (GREY_MINERALS.has(i)) d *= 1.45;
    }
    if (whitish) {
      if (i === WHITE_MINERAL) d *= 0.45;
      if (GREY_MINERALS.has(i) || i === 10) d *= 1.35;
    }
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

function quantKey(r, g, b, step = 0.08) {
  const rq = Math.round(r / step) * step;
  const gq = Math.round(g / step) * step;
  const bq = Math.round(b / step) * step;
  return `${rq.toFixed(3)}:${gq.toFixed(3)}:${bq.toFixed(3)}`;
}

function drawImageFit(canvas, img) {
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.fillStyle = colorToCss(SPACE_COLOR);
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  const scale = Math.min(canvas.width / img.width, canvas.height / img.height);
  const w = img.width * scale;
  const h = img.height * scale;
  ctx.drawImage(img, (canvas.width - w) / 2, (canvas.height - h) / 2, w, h);
}

function loadImageFromUrl(url) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = url;
  });
}

function readSourcePixels(img) {
  const canvas = document.createElement('canvas');
  canvas.width = img.width;
  canvas.height = img.height;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0);
  return {
    data: ctx.getImageData(0, 0, img.width, img.height).data,
    w: img.width,
    h: img.height,
  };
}

function isVoidPixel(r, g, b, a) {
  return a < 0.20;
}

function modeColorInRect(src, sx0, sx1, sy0, sy1) {
  const { data, w } = src;
  const hist = new Map();
  let voidCount = 0;
  const total = Math.max(1, (sx1 - sx0) * (sy1 - sy0));

  for (let sy = sy0; sy < sy1; sy++) {
    for (let sx = sx0; sx < sx1; sx++) {
      const i = (sy * w + sx) * 4;
      const r = data[i] / 255;
      const g = data[i + 1] / 255;
      const b = data[i + 2] / 255;
      const a = data[i + 3] / 255;
      if (isVoidPixel(r, g, b, a)) {
        voidCount++;
        continue;
      }
      const key = quantKey(r, g, b, 0.04);
      if (!hist.has(key)) hist.set(key, { r, g, b, n: 0 });
      const bucket = hist.get(key);
      bucket.n++;
      bucket.r = (bucket.r * (bucket.n - 1) + r) / bucket.n;
      bucket.g = (bucket.g * (bucket.n - 1) + g) / bucket.n;
      bucket.b = (bucket.b * (bucket.n - 1) + b) / bucket.n;
    }
  }

  if (!hist.size) return { color: null, voidRatio: voidCount / total };

  const buckets = [...hist.values()];
  buckets.sort((a, b) => b.n - a.n);
  const best = buckets[0];
  const nonVoid = Math.max(1, total - voidCount);

  let darkBest = null;
  let darkN = 0;
  for (const bucket of buckets) {
    const lum = luminance(bucket.r, bucket.g, bucket.b);
    if (lum < DARK_DETAIL_LUM && bucket.n > darkN) {
      darkN = bucket.n;
      darkBest = bucket;
    }
  }

  if (darkBest) {
    const darkShare = darkN / nonVoid;
    if (darkShare >= 0.12) {
      return {
        color: { r: darkBest.r, g: darkBest.g, b: darkBest.b },
        voidRatio: voidCount / total,
      };
    }
  }

  return { color: { r: best.r, g: best.g, b: best.b }, voidRatio: voidCount / total };
}

function isDarkBackgroundColor(color) {
  if (!color) return false;
  return luminance(color.r, color.g, color.b) < DARK_BG_LUM;
}

function isLightBackgroundColor(color) {
  if (!color) return false;
  const lum = luminance(color.r, color.g, color.b);
  const sat = saturation(color.r, color.g, color.b);
  return lum > LIGHT_BG_LUM && sat < 0.20;
}

function floodDarkBackground(cells, w, h) {
  const bg = Array.from({ length: h }, () => Array(w).fill(false));
  const queue = [];

  const trySeed = (x, y) => {
    if (bg[y][x]) return;
    const cell = cells[y][x];
    if (!cell.isSky && !isDarkBackgroundColor(cell.color)) return;
    if (cell.isSky || isDarkBackgroundColor(cell.color)) {
      bg[y][x] = true;
      queue.push([x, y]);
    }
  };

  for (let x = 0; x < w; x++) {
    trySeed(x, 0);
    trySeed(x, h - 1);
  }
  for (let y = 0; y < h; y++) {
    trySeed(0, y);
    trySeed(w - 1, y);
  }

  while (queue.length) {
    const [x, y] = queue.pop();
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx;
      const ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h || bg[ny][nx]) continue;
      const cell = cells[ny][nx];
      if (cell.isSky) {
        bg[ny][nx] = true;
        queue.push([nx, ny]);
        continue;
      }
      if (isDarkBackgroundColor(cell.color) && !isLightBackgroundColor(cell.color)) {
        bg[ny][nx] = true;
        queue.push([nx, ny]);
      }
    }
  }
  return bg;
}

function floodLightBackground(cells, w, h, darkMask) {
  const bg = Array.from({ length: h }, () => Array(w).fill(false));
  const queue = [];

  const trySeed = (x, y) => {
    if (bg[y][x] || darkMask[y][x]) return;
    const cell = cells[y][x];
    if (cell.isSky || !isLightBackgroundColor(cell.color)) return;
    bg[y][x] = true;
    queue.push([x, y]);
  };

  for (let x = 0; x < w; x++) {
    trySeed(x, 0);
    trySeed(x, h - 1);
  }
  for (let y = 0; y < h; y++) {
    trySeed(0, y);
    trySeed(w - 1, y);
  }

  while (queue.length) {
    const [x, y] = queue.pop();
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx;
      const ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h || bg[ny][nx] || darkMask[ny][nx]) continue;
      const cell = cells[ny][nx];
      if (cell.isSky || !isLightBackgroundColor(cell.color)) continue;
      bg[ny][nx] = true;
      queue.push([nx, ny]);
    }
  }
  return bg;
}

function countUniqueSourceColors(src) {
  const { data, w, h } = src;
  const set = new Set();
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3] / 255;
    if (a < 0.20) continue;
    set.add(quantKey(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255, 0.04));
  }
  return set.size;
}

function isDetailedPixelArt(img, src) {
  const unique = countUniqueSourceColors(src);
  return unique <= 56 && Math.max(img.width, img.height) <= 640;
}

function sampleColorCells(img, gridW, gridH) {
  const src = readSourcePixels(img);
  const scale = Math.min(gridW / src.w, gridH / src.h);
  const offX = (gridW - src.w * scale) / 2;
  const offY = (gridH - src.h * scale) / 2;

  const cells = [];
  for (let gy = 0; gy < gridH; gy++) {
    const row = [];
    for (let gx = 0; gx < gridW; gx++) {
      const sx0 = Math.max(0, Math.floor((gx - offX) / scale));
      const sx1 = Math.min(src.w, Math.ceil((gx + 1 - offX) / scale));
      const sy0 = Math.max(0, Math.floor((gy - offY) / scale));
      const sy1 = Math.min(src.h, Math.ceil((gy + 1 - offY) / scale));
      if (sx1 <= sx0 || sy1 <= sy0) {
        row.push({ color: null, isSky: true });
        continue;
      }
      const sample = modeColorInRect(src, sx0, sx1, sy0, sy1);
      if (!sample.color || sample.voidRatio > 0.65) {
        row.push({ color: null, isSky: true });
      } else {
        row.push({ color: sample.color, isSky: false });
      }
    }
    cells.push(row);
  }
  return { cells, src };
}

function kMeansColors(points, k, iterations = 12) {
  if (!points.length) return [];
  k = Math.min(k, points.length);
  const centroids = [];
  const step = Math.max(1, Math.floor(points.length / k));
  for (let i = 0; i < k; i++) {
    centroids.push({ ...points[Math.min(i * step, points.length - 1)] });
  }

  const assignments = new Array(points.length).fill(0);
  for (let iter = 0; iter < iterations; iter++) {
    for (let i = 0; i < points.length; i++) {
      const p = points[i];
      const pl = rgbToLab(p.r, p.g, p.b);
      let best = 0;
      let bestD = Infinity;
      for (let c = 0; c < centroids.length; c++) {
        const cl = rgbToLab(centroids[c].r, centroids[c].g, centroids[c].b);
        const d = labDistance(pl, cl);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      assignments[i] = best;
    }
    const sums = centroids.map(() => ({ r: 0, g: 0, b: 0, n: 0 }));
    for (let i = 0; i < points.length; i++) {
      const a = assignments[i];
      sums[a].r += points[i].r;
      sums[a].g += points[i].g;
      sums[a].b += points[i].b;
      sums[a].n++;
    }
    for (let c = 0; c < centroids.length; c++) {
      if (sums[c].n === 0) continue;
      centroids[c] = {
        r: sums[c].r / sums[c].n,
        g: sums[c].g / sums[c].n,
        b: sums[c].b / sums[c].n,
      };
    }
  }
  return centroids;
}

function assignToCentroid(cell, centroids) {
  const lab = rgbToLab(cell.r, cell.g, cell.b);
  let best = 0;
  let bestD = Infinity;
  for (let i = 0; i < centroids.length; i++) {
    const d = labDistance(lab, rgbToLab(centroids[i].r, centroids[i].g, centroids[i].b));
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

function pickBlockMineral(counts) {
  let best = BLACK_MINERAL;
  let bestN = 0;
  for (const [m, n] of counts) {
    if (n > bestN) {
      bestN = n;
      best = m;
    }
  }
  return best;
}

function applySourceDetailPass(fineGrid, src, gridW, gridH, lightMask, darkMask) {
  const scale = Math.min(gridW / src.w, gridH / src.h);
  const offX = (gridW - src.w * scale) / 2;
  const offY = (gridH - src.h * scale) / 2;
  const { data, w } = src;

  for (let gy = 0; gy < gridH; gy++) {
    for (let gx = 0; gx < gridW; gx++) {
      if (lightMask[gy][gx] || darkMask[gy][gx]) continue;
      const sx0 = Math.max(0, Math.floor((gx - offX) / scale));
      const sx1 = Math.min(w, Math.ceil((gx + 1 - offX) / scale));
      const sy0 = Math.max(0, Math.floor((gy - offY) / scale));
      const sy1 = Math.min(src.h, Math.ceil((gy + 1 - offY) / scale));
      if (sx1 <= sx0 || sy1 <= sy0) continue;

      let darkCount = 0;
      let sampleCount = 0;
      let colorR = 0;
      let colorG = 0;
      let colorB = 0;
      let colorN = 0;

      for (let sy = sy0; sy < sy1; sy++) {
        for (let sx = sx0; sx < sx1; sx++) {
          const i = (sy * w + sx) * 4;
          const r = data[i] / 255;
          const g = data[i + 1] / 255;
          const b = data[i + 2] / 255;
          const a = data[i + 3] / 255;
          if (isVoidPixel(r, g, b, a)) continue;
          sampleCount++;
          if (luminance(r, g, b) < DARK_DETAIL_LUM) {
            darkCount++;
          } else {
            colorR += r;
            colorG += g;
            colorB += b;
            colorN++;
          }
        }
      }

      if (sampleCount === 0 || colorN === 0) continue;
      const darkShare = darkCount / sampleCount;
      const avgR = colorR / colorN;
      const avgG = colorG / colorN;
      const avgB = colorB / colorN;
      const colorful = saturation(avgR, avgG, avgB) > 0.22;

      // Семена/точки на цветном фоне — не заливаем весь объект
      if (colorful && darkCount >= 2 && darkShare >= 0.08 && darkShare < 0.55) {
        fineGrid[gy][gx] = BLACK_MINERAL;
      }
    }
  }
}

function smoothMineralGrid(grid, passes = 2) {
  let cur = grid;
  const h = cur.length;
  const w = cur[0].length;
  for (let pass = 0; pass < passes; pass++) {
    const out = cur.map((row) => row.slice());
    for (let y = 1; y < h - 1; y++) {
      for (let x = 1; x < w - 1; x++) {
        if (DETAIL_MINERALS.has(cur[y][x])) continue;
        const counts = new Map();
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            const v = cur[y + dy][x + dx];
            counts.set(v, (counts.get(v) || 0) + 1);
          }
        }
        let best = cur[y][x];
        let bestN = 0;
        for (const [m, n] of counts) {
          if (n > bestN) {
            bestN = n;
            best = m;
          }
        }
        if (bestN >= 6) out[y][x] = best;
      }
    }
    cur = out;
  }
  return cur;
}

function downsampleMineralGrid(fine, fromW, fromH, toW, toH) {
  const scale = fromW / toW;
  const out = [];
  for (let y = 0; y < toH; y++) {
    const row = [];
    for (let x = 0; x < toW; x++) {
      const counts = new Map();
      const fx0 = Math.floor(x * scale);
      const fy0 = Math.floor(y * scale);
      const fx1 = Math.min(fromW, Math.ceil((x + 1) * scale));
      const fy1 = Math.min(fromH, Math.ceil((y + 1) * scale));
      for (let fy = fy0; fy < fy1; fy++) {
        for (let fx = fx0; fx < fx1; fx++) {
          const v = fine[fy][fx];
          counts.set(v, (counts.get(v) || 0) + 1);
        }
      }
      row.push(pickBlockMineral(counts));
    }
    out.push(row);
  }
  return out;
}

function mineralGridToPattern(mineralGrid) {
  const mineralToTier = new Map();
  const palette = [];
  const pattern = [];

  for (const row of mineralGrid) {
    let line = '';
    for (const mineral of row) {
      if (!mineralToTier.has(mineral)) {
        mineralToTier.set(mineral, palette.length);
        palette.push(mineral);
      }
      line += charFromTier(mineralToTier.get(mineral));
    }
    pattern.push(line);
  }
  return { pattern, color_palette: palette };
}

function mapCellToMineral(cell, x, y, darkMask, lightMask, directMode, centroids, clusterToMineral) {
  if (darkMask[y][x] || cell.isSky) return BLACK_MINERAL;
  if (lightMask[y][x]) return WHITE_MINERAL;
  if (!cell.color) return BLACK_MINERAL;
  if (isLightBackgroundColor(cell.color)) return WHITE_MINERAL;
  if (directMode) return nearestMineral(cell.color.r, cell.color.g, cell.color.b);
  const cluster = assignToCentroid(cell.color, centroids);
  return clusterToMineral[cluster];
}

function imageToMineralGrid(img, maxPaletteSize) {
  const { cells, src } = sampleColorCells(img, WORK_W, WORK_H);
  const darkMask = floodDarkBackground(cells, WORK_W, WORK_H);
  const lightMask = floodLightBackground(cells, WORK_W, WORK_H, darkMask);
  const directMode = isDetailedPixelArt(img, src);
  const points = [];

  for (let y = 0; y < WORK_H; y++) {
    for (let x = 0; x < WORK_W; x++) {
      if (darkMask[y][x] || lightMask[y][x]) continue;
      const c = cells[y][x].color;
      if (!c) continue;
      points.push({ r: c.r, g: c.g, b: c.b });
    }
  }

  if (!points.length) {
    const allBlack = Array.from({ length: WORK_H }, () => Array(WORK_W).fill(BLACK_MINERAL));
    let mineralGrid = downsampleMineralGrid(allBlack, WORK_W, WORK_H, TARGET_W, TARGET_H);
    return { mineralGrid, filled: countFilledGrid(mineralGrid) };
  }

  let centroids = [];
  let clusterToMineral = [];
  if (!directMode) {
    centroids = kMeansColors(points, maxPaletteSize);
    clusterToMineral = centroids.map((c) => nearestMineral(c.r, c.g, c.b));
  }

  let fineGrid = cells.map((row, y) => row.map((cell, x) =>
    mapCellToMineral(cell, x, y, darkMask, lightMask, directMode, centroids, clusterToMineral)
  ));

  applySourceDetailPass(fineGrid, src, WORK_W, WORK_H, lightMask, darkMask);

  const smoothPasses = directMode ? 0 : 1;
  if (smoothPasses > 0) fineGrid = smoothMineralGrid(fineGrid, smoothPasses);
  let mineralGrid = downsampleMineralGrid(fineGrid, WORK_W, WORK_H, TARGET_W, TARGET_H);
  if (!directMode) mineralGrid = smoothMineralGrid(mineralGrid, 1);

  return { mineralGrid, filled: countFilledGrid(mineralGrid) };
}

function countFilledGrid(grid) {
  return grid.length * (grid[0]?.length || 0);
}

function countFilled(pattern) {
  let n = 0;
  for (const row of pattern) {
    for (const ch of row) if (ch !== '.' && ch !== ' ') n++;
  }
  return n;
}

function trimPattern(pattern, pad = 0) {
  if (!pattern.length) return pattern;
  let minX = pattern[0].length;
  let minY = pattern.length;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < pattern.length; y++) {
    for (let x = 0; x < pattern[y].length; x++) {
      if (pattern[y][x] === '.' || pattern[y][x] === ' ') continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < 0) return pattern;
  minX = Math.max(0, minX - pad);
  minY = Math.max(0, minY - pad);
  maxX = Math.min(pattern[0].length - 1, maxX + pad);
  maxY = Math.min(pattern.length - 1, maxY + pad);
  const out = [];
  for (let y = minY; y <= maxY; y++) out.push(pattern[y].slice(minX, maxX + 1));
  return out;
}

function patternToGrid(pattern) {
  return pattern.map((row) => row.split(''));
}

function gridToPattern(grid) {
  return grid.map((row) => row.join(''));
}

function initEditState(level) {
  const pattern = level.pattern.map((row) => row);
  const h = pattern.length;
  const w = pattern[0]?.length || 0;
  const cell = Math.max(6, Math.floor(Math.min(PREVIEW_MAX_PX / w, PREVIEW_MAX_PX / h)));
  editState = {
    grid: patternToGrid(pattern),
    palette: level.color_palette.slice(),
    w,
    h,
    cellSize: cell,
  };
  if (editState.palette.length) {
    selectedMineral = editState.palette[0];
  }
  hoverCell = null;
  lastPaintCell = null;
}

function ensureMineralInPalette(mineral) {
  if (!editState) return null;
  let tier = editState.palette.indexOf(mineral);
  if (tier >= 0) {
    return { tier, ch: charFromTier(tier) };
  }
  if (editState.palette.length >= MINERAL_COLORS.length) return null;
  editState.palette.push(mineral);
  tier = editState.palette.length - 1;
  return { tier, ch: charFromTier(tier) };
}

function mineralAtCell(x, y) {
  if (!editState) return null;
  const ch = editState.grid[y][x];
  if (ch === EMPTY_CELL || ch === ' ') return null;
  const tier = tierFromChar(ch);
  if (tier < 0 || tier >= editState.palette.length) return null;
  return editState.palette[tier];
}

function setGridCell(x, y, ch) {
  if (!editState) return;
  if (x < 0 || y < 0 || x >= editState.w || y >= editState.h) return;
  if (editState.grid[y][x] === ch) return;
  editState.grid[y][x] = ch;
  syncExportFromEdit();
  renderPreviewFromEdit();
}

function applyToolAt(x, y, tool, mineralOverride = null) {
  if (!editState) return;
  if (tool === EDIT_TOOLS.PICK) {
    const picked = mineralAtCell(x, y);
    if (picked != null) {
      selectBrushMineral(picked);
      currentTool = EDIT_TOOLS.PAINT;
      updateToolButtons();
    }
    return;
  }
  if (tool === EDIT_TOOLS.ERASE) {
    setGridCell(x, y, EMPTY_CELL);
    return;
  }
  const mineral = mineralOverride ?? selectedMineral;
  const slot = ensureMineralInPalette(mineral);
  if (!slot) return;
  setGridCell(x, y, slot.ch);
}

function syncExportFromEdit() {
  if (!editState || !lastExport) return;
  const pattern = gridToPattern(editState.grid);
  const palette = editState.palette.slice();
  const filled = countFilled(pattern);
  lastExport.level.pattern = pattern;
  lastExport.level.color_palette = palette;
  lastExport.level.total_colors = palette.length;
  els.jsonOutput.textContent = JSON.stringify(lastExport.level, null, 2);
  showStats(filled, pattern, palette.length);
  const paletteKey = palette.join(',');
  if (paletteKey !== lastPaletteKey) {
    showPalette(palette);
    lastPaletteKey = paletteKey;
  } else {
    updatePaletteSelection();
  }
  els.downloadBtn.disabled = filled < MIN_FILL_CELLS;
}

function renderPreviewFromEdit() {
  if (!editState) return;
  renderPreview(gridToPattern(editState.grid), editState.palette, els.previewCanvas, {
    cellSize: editState.cellSize,
    showGrid: true,
    hoverCell,
  });
}

function renderPreview(pattern, palette, canvas, options = {}) {
  const h = pattern.length;
  const w = pattern[0]?.length || 0;
  if (!w || !h) return;
  const cell = options.cellSize
    ?? Math.max(6, Math.floor(Math.min(PREVIEW_MAX_PX / w, PREVIEW_MAX_PX / h)));
  canvas.width = w * cell;
  canvas.height = h * cell;
  if (editState) editState.cellSize = cell;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const ch = pattern[y][x];
      let color = SPACE_COLOR;
      if (ch !== EMPTY_CELL && ch !== ' ') {
        const tier = tierFromChar(ch);
        const mineral = palette[tier] ?? tier;
        color = MINERAL_COLORS[mineral] ?? SPACE_COLOR;
      }
      ctx.fillStyle = colorToCss(color);
      ctx.fillRect(x * cell, y * cell, cell, cell);
    }
  }
  if (options.showGrid) {
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.07)';
    ctx.lineWidth = 1;
    for (let x = 0; x <= w; x++) {
      ctx.beginPath();
      ctx.moveTo(x * cell + 0.5, 0);
      ctx.lineTo(x * cell + 0.5, h * cell);
      ctx.stroke();
    }
    for (let y = 0; y <= h; y++) {
      ctx.beginPath();
      ctx.moveTo(0, y * cell + 0.5);
      ctx.lineTo(w * cell, y * cell + 0.5);
      ctx.stroke();
    }
  }
  if (options.hoverCell) {
    const { x, y } = options.hoverCell;
    ctx.strokeStyle = 'rgba(77, 163, 255, 0.95)';
    ctx.lineWidth = 2;
    ctx.strokeRect(x * cell + 1, y * cell + 1, cell - 2, cell - 2);
  }
}

function selectBrushMineral(mineral) {
  selectedMineral = mineral;
  updatePaletteSelection();
}

function updatePaletteSelection() {
  document.querySelectorAll('.swatch[data-mineral]').forEach((el) => {
    el.classList.toggle('selected', parseInt(el.dataset.mineral, 10) === selectedMineral);
  });
  document.querySelectorAll('.mineral-chip[data-mineral]').forEach((el) => {
    el.classList.toggle('selected', parseInt(el.dataset.mineral, 10) === selectedMineral);
  });
}

function updateToolButtons() {
  document.querySelectorAll('.tool-btn[data-tool]').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.tool === currentTool);
  });
}

function buildMineralPicker() {
  if (!els.mineralPicker) return;
  els.mineralPicker.innerHTML = MINERAL_COLORS.map((rgb, mineral) => `
    <button type="button" class="mineral-chip" data-mineral="${mineral}" title="${COLOR_NAMES[mineral] || mineral}">
      <span class="mineral-chip-dot" style="background:${colorToCss(rgb)}"></span>
      <span>${COLOR_NAMES[mineral] || mineral}</span>
    </button>
  `).join('');
  els.mineralPicker.querySelectorAll('.mineral-chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      selectBrushMineral(parseInt(chip.dataset.mineral, 10));
      currentTool = EDIT_TOOLS.PAINT;
      updateToolButtons();
    });
  });
  updatePaletteSelection();
}

function canvasCellFromEvent(e) {
  if (!editState) return null;
  const canvas = els.previewCanvas;
  const rect = canvas.getBoundingClientRect();
  if (!rect.width || !rect.height) return null;
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  const px = (e.clientX - rect.left) * scaleX;
  const py = (e.clientY - rect.top) * scaleY;
  const x = Math.floor(px / editState.cellSize);
  const y = Math.floor(py / editState.cellSize);
  if (x < 0 || y < 0 || x >= editState.w || y >= editState.h) return null;
  return { x, y };
}

function paintAtCell(cell, tool) {
  if (!cell) return;
  if (lastPaintCell && lastPaintCell.x === cell.x && lastPaintCell.y === cell.y) return;
  lastPaintCell = cell;
  applyToolAt(cell.x, cell.y, tool);
}

function onCanvasPointerDown(e) {
  if (!editState) return;
  e.preventDefault();
  const cell = canvasCellFromEvent(e);
  if (!cell) return;
  isPainting = true;
  lastPaintCell = null;
  const tool = e.button === 2 ? EDIT_TOOLS.ERASE : currentTool;
  paintAtCell(cell, tool);
}

function onCanvasPointerMove(e) {
  if (!editState) return;
  const cell = canvasCellFromEvent(e);
  const changed = !hoverCell || !cell
    || hoverCell.x !== cell.x || hoverCell.y !== cell.y;
  hoverCell = cell;
  if (changed) renderPreviewFromEdit();
  if (isPainting && cell) {
    const tool = e.buttons === 2 ? EDIT_TOOLS.ERASE : currentTool;
    paintAtCell(cell, tool);
  }
}

function onCanvasPointerUp() {
  isPainting = false;
  lastPaintCell = null;
}

function setupEditCanvas() {
  const canvas = els.previewCanvas;
  canvas.oncontextmenu = (e) => e.preventDefault();
  canvas.addEventListener('mousedown', onCanvasPointerDown);
  canvas.addEventListener('mousemove', onCanvasPointerMove);
  window.addEventListener('mouseup', onCanvasPointerUp);
  canvas.addEventListener('mouseleave', () => {
    if (!isPainting) {
      hoverCell = null;
      renderPreviewFromEdit();
    }
  });
  canvas.addEventListener('touchstart', (e) => {
    if (!editState || !e.touches.length) return;
    e.preventDefault();
    const touch = e.touches[0];
    isPainting = true;
    lastPaintCell = null;
    paintAtCell(canvasCellFromEvent(touch), currentTool);
  }, { passive: false });
  canvas.addEventListener('touchmove', (e) => {
    if (!editState || !e.touches.length) return;
    e.preventDefault();
    const touch = e.touches[0];
    const cell = canvasCellFromEvent(touch);
    hoverCell = cell;
    renderPreviewFromEdit();
    if (cell) paintAtCell(cell, currentTool);
  }, { passive: false });
  canvas.addEventListener('touchend', onCanvasPointerUp);

  document.querySelectorAll('.tool-btn[data-tool]').forEach((btn) => {
    btn.addEventListener('click', () => {
      currentTool = btn.dataset.tool;
      updateToolButtons();
    });
  });
}

function buildLevelData(img, options) {
  const { maxColors, levelId, themeName } = options;
  const { mineralGrid } = imageToMineralGrid(img, maxColors);
  let { pattern, color_palette } = mineralGridToPattern(mineralGrid);
  pattern = trimPattern(pattern, 1);
  const trimmedFilled = countFilled(pattern);

  return {
    level: {
      schema_version: SCHEMA_VERSION,
      id: levelId,
      theme_name: themeName || `Уровень ${levelId}`,
      pattern,
      color_palette,
      total_colors: color_palette.length,
      source: { width: img.width, height: img.height, filled_cells: trimmedFilled },
    },
    filled: trimmedFilled,
  };
}

function showStats(filled, pattern, paletteSize) {
  const w = pattern[0]?.length || 0;
  const h = pattern.length;
  els.stats.classList.remove('hidden');
  els.stats.innerHTML = `
    <div>Размер сетки: <strong>${w}×${h}</strong></div>
    <div>Заполненных клеток: <strong>${filled}</strong> (мин. ${MIN_FILL_CELLS})</div>
    <div>Цветов в палитре: <strong>${paletteSize}</strong></div>
    ${filled >= MIN_FILL_CELLS ? '' : '<div class="warn">Мало клеток — увеличьте объект или уменьшите прозрачный фон.</div>'}
  `;
}

function showPalette(palette) {
  els.palettePanel.classList.remove('hidden');
  els.paletteList.innerHTML = palette.map((mineral, tier) => `
    <button type="button" class="swatch" data-mineral="${mineral}" data-tier="${tier}">
      <span class="swatch-color" style="background:${colorToCss(MINERAL_COLORS[mineral])}"></span>
      <span>T${tier} → ${COLOR_NAMES[mineral] || mineral}</span>
    </button>
  `).join('');
  els.paletteList.querySelectorAll('.swatch').forEach((swatch) => {
    swatch.addEventListener('click', () => {
      selectBrushMineral(parseInt(swatch.dataset.mineral, 10));
      currentTool = EDIT_TOOLS.PAINT;
      updateToolButtons();
    });
  });
  updatePaletteSelection();
}

function setSourceImage(img, nameHint) {
  sourceImage = img;
  editState = null;
  if (els.editToolbar) els.editToolbar.classList.add('hidden');
  drawImageFit(els.sourceCanvas, img);
  els.convertBtn.disabled = false;
  els.downloadBtn.disabled = true;
  if (nameHint && !els.themeName.value) {
    els.themeName.placeholder = nameHint;
  }
}

function handleFile(file) {
  if (!file || !file.type.startsWith('image/')) return;
  const reader = new FileReader();
  reader.onload = () => {
    const img = new Image();
    img.onload = () => {
      const base = file.name.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' ');
      setSourceImage(img, base.slice(0, 40) || 'Космонавт');
    };
    img.src = reader.result;
  };
  reader.readAsDataURL(file);
}

async function loadExample() {
  try {
    const img = await loadImageFromUrl(EXAMPLE_PATH);
    setSourceImage(img, 'Космонавт (эталон)');
    await convert();
  } catch (e) {
    alert('Не удалось загрузить пример. Запустите через ./scripts/run-level-editor.sh');
  }
}

async function downloadZip() {
  if (!lastExport) return;
  lastExport.previewBlob = await canvasToBlob(els.previewCanvas);
  const { level, pngBlob, previewBlob } = lastExport;
  const id = String(level.id).padStart(3, '0');
  const zip = new JSZip();
  zip.file(`level_${id}.json`, JSON.stringify(level, null, 2));
  zip.file(`level_${id}.png`, pngBlob);
  zip.file(`level_${id}_preview.png`, previewBlob);
  zip.file('README.txt', [
    'Space Crawler — экспорт уровня',
    '',
    `Скопируйте в app/data/levels/:`,
    `  level_${id}.json`,
    `  level_${id}.png`,
  ].join('\n'));
  const blob = await zip.generateAsync({ type: 'blob' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `space-crawler-level_${id}.zip`;
  a.click();
  URL.revokeObjectURL(a.href);
}

function canvasToBlob(canvas) {
  return new Promise((resolve) => canvas.toBlob((blob) => resolve(blob), 'image/png'));
}

async function convert() {
  if (!sourceImage) return;
  const levelId = parseInt(els.levelId.value, 10) || 25;
  const themeName = els.themeName.value.trim() || els.themeName.placeholder || `Уровень ${levelId}`;
  const maxColors = Math.min(20, Math.max(2, parseInt(els.maxColors.value, 10) || 14));

  const { level, filled } = buildLevelData(sourceImage, {
    levelId,
    themeName,
    maxColors,
  });

  initEditState(level);
  lastPaletteKey = level.color_palette.join(',');
  renderPreviewFromEdit();
  showStats(filled, level.pattern, level.color_palette.length);
  showPalette(level.color_palette);
  buildMineralPicker();
  if (els.editToolbar) els.editToolbar.classList.remove('hidden');
  els.jsonPanel.classList.remove('hidden');
  els.jsonOutput.textContent = JSON.stringify(level, null, 2);

  const exportCanvas = document.createElement('canvas');
  exportCanvas.width = sourceImage.width;
  exportCanvas.height = sourceImage.height;
  exportCanvas.getContext('2d').drawImage(sourceImage, 0, 0);

  lastExport = {
    level,
    pngBlob: await canvasToBlob(exportCanvas),
    previewBlob: await canvasToBlob(els.previewCanvas),
  };
  els.downloadBtn.disabled = filled < MIN_FILL_CELLS;
}

setupEditCanvas();
buildMineralPicker();

els.fileInput.addEventListener('change', (e) => handleFile(e.target.files[0]));
els.convertBtn.addEventListener('click', convert);
els.downloadBtn.addEventListener('click', downloadZip);
if (els.loadExampleBtn) els.loadExampleBtn.addEventListener('click', loadExample);

els.dropZone.addEventListener('dragover', (e) => {
  e.preventDefault();
  els.dropZone.classList.add('dragover');
});
els.dropZone.addEventListener('dragleave', () => els.dropZone.classList.remove('dragover'));
els.dropZone.addEventListener('drop', (e) => {
  e.preventDefault();
  els.dropZone.classList.remove('dragover');
  handleFile(e.dataTransfer.files[0]);
});
