// tools/agent-bus.js
// Barramento de comunicacao automatica em tempo real entre agentes Antigravity via HTTP/LAN

const http = require('http');
const fs = require('fs');
const path = require('path');

const COORD_DIR = path.join(__dirname, '..', '.coordination');
const BUS_LOG = path.join(COORD_DIR, 'bus.jsonl');
const STATE_FILE = path.join(COORD_DIR, 'state.json');

if (!fs.existsSync(COORD_DIR)) {
  fs.mkdirSync(COORD_DIR, { recursive: true });
}

const cmd = process.argv[2] || 'listen';

if (cmd === 'listen') {
  const port = parseInt(process.argv[3] || '9090', 10);

  const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/msg') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try {
          const msg = JSON.parse(body);
          msg.receivedAt = new Date().toISOString();
          
          fs.appendFileSync(BUS_LOG, JSON.stringify(msg) + '\n');
          fs.writeFileSync(STATE_FILE, JSON.stringify({ lastMessage: msg, updatedAt: msg.receivedAt }, null, 2));

          console.log(`\n==========================================`);
          console.log(`📩 [MENSAGEM DE ${msg.from || 'PEER'}] (${msg.type || 'INFO'}):`);
          console.log(`${msg.text}`);
          console.log(`==========================================\n`);

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'OK', id: Date.now() }));
        } catch (e) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: e.message }));
        }
      });
      return;
    }

    if (req.method === 'GET' && req.url === '/history') {
      let lines = [];
      if (fs.existsSync(BUS_LOG)) {
        lines = fs.readFileSync(BUS_LOG, 'utf8').trim().split('\n').filter(Boolean).map(l => JSON.parse(l));
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ messages: lines, count: lines.length }));
      return;
    }

    if (req.method === 'GET' && req.url === '/ping') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'pong', time: new Date().toISOString() }));
      return;
    }

    res.writeHead(404);
    res.end('Not found');
  });

  server.listen(port, '0.0.0.0', () => {
    console.log(`[AGENT-BUS] Ouvindo mensagens em http://0.0.0.0:${port}/`);
    console.log(`[AGENT-BUS] Historico salvo em: ${BUS_LOG}`);
  });

} else if (cmd === 'send') {
  const target = process.argv[3]; // ex: 192.168.0.16:9090
  const from = process.argv[4] || 'AGY-1';
  const text = process.argv.slice(5).join(' ');

  if (!target || !text) {
    console.error('Uso: node tools/agent-bus.js send <target_ip:port> <from> <mensagem>');
    process.exit(1);
  }

  let cleanTarget = target.replace(/^https?:\/\//, '');
  const [host, port] = cleanTarget.split(':');
  const payload = JSON.stringify({
    from,
    text,
    type: 'CHAT',
    sentAt: new Date().toISOString()
  });

  const req = http.request({
    hostname: host,
    port: parseInt(port || '9090', 10),
    path: '/msg',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    },
    timeout: 5000
  }, res => {
    let respBody = '';
    res.on('data', c => { respBody += c; });
    res.on('end', () => {
      console.log(`[AGENT-BUS] Enviado com sucesso para ${target}: HTTP ${res.statusCode}`);
      // Salvar copia local
      fs.appendFileSync(BUS_LOG, JSON.stringify({ from, to: target, text, sentAt: new Date().toISOString() }) + '\n');
    });
  });

  req.on('error', err => {
    console.error(`[AGENT-BUS] Erro ao enviar para ${target}:`, err.message);
    process.exit(1);
  });

  req.write(payload);
  req.end();

} else if (cmd === 'history') {
  if (fs.existsSync(BUS_LOG)) {
    const lines = fs.readFileSync(BUS_LOG, 'utf8').trim().split('\n').filter(Boolean);
    console.log(`--- Historico de Mensagens (${lines.length}) ---`);
    for (const l of lines) {
      const m = JSON.parse(l);
      console.log(`[${m.sentAt || m.receivedAt}] ${m.from || 'Eu'} -> ${m.text}`);
    }
  } else {
    console.log('Nenhuma mensagem registrada no barramento ainda.');
  }
}
