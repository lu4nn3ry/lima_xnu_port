// tools/serve-dumps.js
// Servidor HTTP local leve para transferir os dumps entre computadores na mesma rede

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const DUMPS_DIR = path.join(__dirname, '..', 'dumps');

function getFiles(dir, baseDir = dir) {
  let results = [];
  if (!fs.existsSync(dir)) return results;
  const list = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of list) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(getFiles(fullPath, baseDir));
    } else {
      const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
      const stats = fs.statSync(fullPath);
      results.push({ path: relPath, size: stats.size });
    }
  }
  return results;
}

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  if (urlPath === '/' || urlPath === '/manifest.json') {
    const files = getFiles(DUMPS_DIR);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ files, total: files.length }, null, 2));
    return;
  }

  // Sanitizar caminho para evitar directory traversal
  const safePath = path.normalize(urlPath.replace(/^\/+/, '')).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(DUMPS_DIR, safePath);

  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Arquivo nao encontrado');
    return;
  }

  const stat = fs.statSync(filePath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunksize = end - start + 1;
    const file = fs.createReadStream(filePath, { start, end });
    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': 'application/octet-stream',
    });
    file.pipe(res);
  } else {
    res.writeHead(200, {
      'Content-Length': fileSize,
      'Content-Type': 'application/octet-stream',
    });
    fs.createReadStream(filePath).pipe(res);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[DUMP-SERVER] Ativo em http://0.0.0.0:${PORT}/`);
  console.log(`[DUMP-SERVER] Servindo pasta: ${DUMPS_DIR}`);
});
