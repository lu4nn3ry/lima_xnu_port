// tools/fdt-to-dts.js
// Simple FDT (Flattened Device Tree) binary to DTS decompiler in Node.js

const fs = require('fs');
const path = require('path');

const inputPath = process.argv[2] || path.join(__dirname, '..', 'dumps', 'boot_extracted', 'kernel.dtb');
const outputPath = process.argv[3] || path.join(__dirname, '..', 'dumps', 'boot_extracted', 'kernel.dts');

if (!fs.existsSync(inputPath)) {
  console.error(`Arquivo nao encontrado: ${inputPath}`);
  process.exit(1);
}

const buf = fs.readFileSync(inputPath);
let offset = 0;

const magic = buf.readUInt32BE(0);
if (magic !== 0xd00dfeed) {
  console.error(`Magic invalido: 0x${magic.toString(16)} (esperado 0xd00dfeed)`);
  process.exit(1);
}

const totalsize = buf.readUInt32BE(4);
const off_dt_struct = buf.readUInt32BE(8);
const off_dt_strings = buf.readUInt32BE(12);
const off_mem_rsvmap = buf.readUInt32BE(16);
const version = buf.readUInt32BE(20);
const boot_cpuid_phys = buf.readUInt32BE(28);

console.log(`DTB: tamanho=${totalsize}, versao=${version}, struct_off=${off_dt_struct}, strings_off=${off_dt_strings}`);

let dts = `/dts-v1/;\n\n`;

// Parse memory reservation map
let rsvOffset = off_mem_rsvmap;
while (rsvOffset + 16 <= buf.length) {
  const addrHigh = buf.readUInt32BE(rsvOffset);
  const addrLow = buf.readUInt32BE(rsvOffset + 4);
  const sizeHigh = buf.readUInt32BE(rsvOffset + 8);
  const sizeLow = buf.readUInt32BE(rsvOffset + 12);
  rsvOffset += 16;
  if (addrHigh === 0 && addrLow === 0 && sizeHigh === 0 && sizeLow === 0) break;
  const addr = (BigInt(addrHigh) << 32n) | BigInt(addrLow);
  const size = (BigInt(sizeHigh) << 32n) | BigInt(sizeLow);
  dts += `/memreserve/ 0x${addr.toString(16)} 0x${size.toString(16)};\n`;
}

// Helper to read string from string table
function getString(nameoff) {
  let end = off_dt_strings + nameoff;
  while (end < buf.length && buf[end] !== 0) end++;
  return buf.toString('utf8', off_dt_strings + nameoff, end);
}

// Helper to format property data
function formatProp(name, data) {
  if (data.length === 0) return '';

  // Check if printable ASCII string or string list
  let isPrintable = true;
  for (let i = 0; i < data.length; i++) {
    const c = data[i];
    if (c === 0) continue;
    if (c < 32 || c > 126) {
      isPrintable = false;
      break;
    }
  }

  if (isPrintable && data[data.length - 1] === 0) {
    const strings = data.slice(0, data.length - 1).toString('utf8').split('\0');
    return ' = ' + strings.map(s => JSON.stringify(s)).join(', ');
  }

  // Format as 32-bit big-endian words if length is multiple of 4
  if (data.length % 4 === 0) {
    const words = [];
    for (let i = 0; i < data.length; i += 4) {
      words.push('0x' + data.readUInt32BE(i).toString(16));
    }
    return ` = <${words.join(' ')}>`;
  }

  // Fallback to hex bytes
  const bytes = [];
  for (let i = 0; i < data.length; i++) {
    bytes.push(data[i].toString(16).padStart(2, '0'));
  }
  return ` = [${bytes.join(' ')}]`;
}

const FDT_BEGIN_NODE = 0x1;
const FDT_END_NODE = 0x2;
const FDT_PROP = 0x3;
const FDT_NOP = 0x4;
const FDT_END = 0x9;

let ptr = off_dt_struct;
let indent = '';

while (ptr < off_dt_struct + (buf.readUInt32BE(36) || totalsize)) {
  const token = buf.readUInt32BE(ptr);
  ptr += 4;

  if (token === FDT_BEGIN_NODE) {
    let nameEnd = ptr;
    while (nameEnd < buf.length && buf[nameEnd] !== 0) nameEnd++;
    let nodeName = buf.toString('utf8', ptr, nameEnd);
    ptr = (nameEnd + 1 + 3) & ~3; // 4-byte align

    if (nodeName === '') nodeName = '/';
    dts += `${indent}${nodeName} {\n`;
    indent += '    ';
  } else if (token === FDT_END_NODE) {
    indent = indent.slice(0, -4);
    dts += `${indent}};\n`;
  } else if (token === FDT_PROP) {
    const len = buf.readUInt32BE(ptr);
    const nameoff = buf.readUInt32BE(ptr + 4);
    ptr += 8;
    const propData = buf.subarray(ptr, ptr + len);
    ptr = (ptr + len + 3) & ~3; // 4-byte align

    const propName = getString(nameoff);
    const formatted = formatProp(propName, propData);
    dts += `${indent}${propName}${formatted};\n`;
  } else if (token === FDT_NOP) {
    continue;
  } else if (token === FDT_END) {
    break;
  } else {
    console.error(`Token desconhecido 0x${token.toString(16)} em offset ${ptr - 4}`);
    break;
  }
}

fs.writeFileSync(outputPath, dts, 'utf8');
console.log(`DTS gerado com sucesso em: ${outputPath} (${dts.length} caracteres)`);
