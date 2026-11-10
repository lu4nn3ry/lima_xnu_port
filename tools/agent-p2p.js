// tools/agent-p2p.js
// Protocolo P2P Inter-Agentes com Auto-Wakeup (Encerra no recebimento da mensagem)
//
// Como funciona:
// 1. Cada agente roda: `node tools/agent-p2p.js wait 9090 [timeoutSegundos]`
//    - O processo fica aguardando conexao na porta especificada.
//    - Assim que uma mensagem POST /msg chega de outro agente, o servidor responde HTTP 200,
//      imprime o conteudo na tela, salva no .coordination/bus.jsonl e ENCERRA (process.exit(0)).
//    - Isso DESPERTA o agente Antigravity instantaneamente via conclusao da ferramenta!
//
// 2. Para enviar uma mensagem: `node tools/agent-p2p.js send <IP:PORTA> <DE> <MENSAGEM>`
//    - Faz retry automatico caso o outro agente esteja apenas iniciando o listener.

const http = require('http');
const fs = require('fs');
const path = require('path');

const COORD_DIR = path.join(__dirname, '..', '.coordination');
const BUS_LOG = path.join(COORD_DIR, 'bus.jsonl');

if (!fs.existsSync(COORD_DIR)) {
  fs.mkdirSync(COORD_DIR, { recursive: true });
}

const cmd = process.argv[2] || 'help';

if (cmd === 'wait') {
  const port = parseInt(process.argv[3] || '9090', 10);
  const timeoutSec = parseInt(process.argv[4] || '300', 10); // padrao 5 minutos

  let server;
  let timer;

  server = http.createServer((req, res) => {
    if (req.method === 'POST' && (req.url === '/msg' || req.url === '/')) {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try {
          const msg = JSON.parse(body);
          msg.receivedAt = new Date().toISOString();
          
          fs.appendFileSync(BUS_LOG, JSON.stringify(msg) + '\n');

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'OK', delivered: true }));

          console.log('\n======================================================');
          console.log(`📩 [MENSAGEM RECEBIDA DE ${msg.from || 'PEER'}] em ${msg.receivedAt}:`);
          console.log('------------------------------------------------------');
          console.log(msg.text);
          console.log('======================================================\n');

          clearTimeout(timer);
          server.close(() => {
            process.exit(0); // ENCERRA COM SUCESSO PARA ACORDAR O AGENTE!
          });
        } catch (e) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: e.message }));
        }
      });
      return;
    }

    if (req.method === 'GET' && req.url === '/ping') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('PONG');
      return;
    }

    res.writeHead(404);
    res.end();
  });

  server.on('error', err => {
    if (err.code === 'EADDRINUSE') {
      console.error(`[P2P-WAIT] Porta ${port} ja esta em uso. Verifique processos anteriores.`);
    } else {
      console.error(`[P2P-WAIT] Erro no servidor:`, err.message);
    }
    process.exit(1);
  });

  server.listen(port, '0.0.0.0', () => {
    console.log(`[P2P-WAIT] Aguardando mensagem do outro agente na porta ${port}... (Timeout: ${timeoutSec}s)`);
  });

  if (timeoutSec > 0) {
    timer = setTimeout(() => {
      console.log(`[P2P-WAIT] Timeout de ${timeoutSec}s atingido sem novas mensagens.`);
      server.close(() => {
        process.exit(2);
      });
    }, timeoutSec * 1000);
  }

} else if (cmd === 'send') {
  let target = process.argv[3];
  const from = process.argv[4] || 'AGY';
  const text = process.argv[5];

  if (!target || !text) {
    console.error('Uso: node tools/agent-p2p.js send <IP:PORTA> <DE> <MENSAGEM>');
    process.exit(1);
  }

  target = target.replace(/^https?:\/\//, '');
  const [host, portStr] = target.split(':');
  const port = parseInt(portStr || '9090', 10);

  const payload = JSON.stringify({
    from,
    text,
    sentAt: new Date().toISOString()
  });

  let attempts = 0;
  const maxAttempts = 5;

  function trySend() {
    attempts++;
    const req = http.request({
      hostname: host,
      port: port,
      path: '/msg',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: 4000
    }, res => {
      let resp = '';
      res.on('data', c => { resp += c; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log(`[P2P-SEND] Mensagem entregue com sucesso para ${target}!`);
          fs.appendFileSync(BUS_LOG, JSON.stringify({ from, to: target, text, sentAt: new Date().toISOString() }) + '\n');
          process.exit(0);
        } else {
          console.error(`[P2P-SEND] Servidor retornou HTTP ${res.statusCode}: ${resp}`);
          retry();
        }
      });
    });

    req.on('error', err => {
      console.warn(`[P2P-SEND] Tentativa ${attempts}/${maxAttempts} falhou (${err.message})...`);
      retry();
    });

    req.on('timeout', () => {
      req.destroy();
      console.warn(`[P2P-SEND] Tentativa ${attempts}/${maxAttempts} timed out...`);
      retry();
    });

    req.write(payload);
    req.end();
  }

  function retry() {
    if (attempts < maxAttempts) {
      setTimeout(trySend, 1500);
    } else {
      console.error(`[P2P-SEND] Falha ao enviar para ${target} apos ${maxAttempts} tentativas.`);
      process.exit(1);
    }
  }

  trySend();

} else if (cmd === 'broadcast') {
  const from = process.argv[3] || 'AGY';
  const text = process.argv[4];

  if (!text) {
    console.error('Uso: node tools/agent-p2p.js broadcast <DE> <MENSAGEM>');
    process.exit(1);
  }

  const peersFile = path.join(COORD_DIR, 'peers.json');
  if (!fs.existsSync(peersFile)) {
    console.error('Arquivo de peers nao encontrado:', peersFile);
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(peersFile, 'utf8'));
  const peers = (config.peers || []).filter(p => p.name !== from);

  console.log(`[P2P-BROADCAST] Enviando de ${from} para ${peers.length} agentes...`);

  let sent = 0;
  for (const peer of peers) {
    const payload = JSON.stringify({ from, text, sentAt: new Date().toISOString() });
    const req = http.request({
      hostname: peer.host,
      port: peer.port,
      path: '/msg',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: 3000
    }, res => {
      console.log(`  ✔ Entregue para ${peer.name} (${peer.host}:${peer.port})`);
      sent++;
      if (sent >= peers.length) process.exit(0);
    });

    req.on('error', err => {
      console.warn(`  ✖ Falha ao enviar para ${peer.name} (${peer.host}:${peer.port}): ${err.message}`);
      sent++;
      if (sent >= peers.length) process.exit(0);
    });

    req.write(payload);
    req.end();
  }

} else {
  console.log(`Uso:
  node tools/agent-p2p.js wait <porta> [timeoutSec]   (Aguarda mensagem e encerra ao receber)
  node tools/agent-p2p.js send <IP:PORTA> <DE> <MSG>   (Envia mensagem com retry automatico)
  node tools/agent-p2p.js broadcast <DE> <MSG>        (Envia mensagem para todos os peers)
`);
}
