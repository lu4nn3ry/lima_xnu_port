const https = require('https');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

const URL = 'https://mirrors-obs-2.lolinet.com/firmware/lenomola/2019/lima_32/official/RETBR/XT2015-2_LIMA_32_RETBR_10_QMDS30.47-33-5_subsidy-DEFAULT_regulatory-DEFAULT_CFC.xml.zip';

const TARGETS = [
  { name: 'boot.img', dataOffset: 292158666, compSize: 16213220, uncompSize: 33554432 },
  { name: 'dtbo.img', dataOffset: 485937219, compSize: 119166, uncompSize: 474736 },
  { name: 'dtb.img',  dataOffset: 1340196705, compSize: 30573, uncompSize: 115120 }
];

const outDir = path.resolve(__dirname, '..', 'dumps', 'firmware');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

function downloadAndInflate(target) {
  return new Promise((resolve, reject) => {
    const start = target.dataOffset;
    const end = target.dataOffset + target.compSize - 1;
    const range = `bytes=${start}-${end}`;
    const destPath = path.join(outDir, target.name);

    console.log(`[+] Baixando ${target.name} (${(target.compSize / 1024 / 1024).toFixed(2)} MB comprimido, range ${range})...`);

    const req = https.get(URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Range': range
      }
    }, res => {
      if (res.statusCode !== 206) {
        return reject(new Error(`HTTP status inesperado: ${res.statusCode}`));
      }

      const inflate = zlib.createInflateRaw();
      const outStream = fs.createWriteStream(destPath);
      const hash = crypto.createHash('sha256');

      let received = 0;
      let lastReport = 0;

      res.on('data', chunk => {
        received += chunk.length;
        const now = Date.now();
        if (now - lastReport > 2000 || received === target.compSize) {
          lastReport = now;
          const pct = ((received / target.compSize) * 100).toFixed(1);
          console.log(`    ${target.name}: ${pct}% (${(received / 1024 / 1024).toFixed(2)} MB / ${(target.compSize / 1024 / 1024).toFixed(2)} MB)`);
        }
      });

      inflate.on('data', chunk => hash.update(chunk));

      res.pipe(inflate).pipe(outStream);

      outStream.on('finish', () => {
        const sha256 = hash.digest('hex');
        const st = fs.statSync(destPath);
        console.log(`[✓] ${target.name} salvo com sucesso!`);
        console.log(`    Tamanho descompactado: ${st.size} bytes (esperado: ${target.uncompSize})`);
        console.log(`    SHA-256: ${sha256}`);
        resolve({ name: target.name, size: st.size, sha256 });
      });

      inflate.on('error', err => reject(new Error(`Erro de descompressão em ${target.name}: ${err.message}`)));
      outStream.on('error', reject);
    });

    req.on('error', reject);
  });
}

async function main() {
  console.log(`Iniciando download direcionado (apenas imagens de boot/dtb, sem baixar os 1.8 GB da ROM)...`);
  for (const t of TARGETS) {
    await downloadAndInflate(t);
  }
  console.log(`\nTodos os alvos foram baixados e verificados em: ${outDir}`);
}

main().catch(err => {
  console.error(`Falha:`, err);
  process.exit(1);
});
