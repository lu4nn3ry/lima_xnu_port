# `research/hardware/`

Coletas brutas de hardware: saídas de comandos, dumps de registradores,
identificação de componentes.

## Convenção de nomes

```
AAAA-MM-DD-<assunto>.txt
```

Exemplos:

- `2026-11-10-soc-identification.txt`
- `2026-11-10-memory-map.txt`
- `2026-11-10-irq-table.txt`
- `2026-11-10-display-timings.txt`

Cada arquivo começa com um cabeçalho:

```
# coletado em: AAAA-MM-DD
# aparelho: XT2015-2 / build <fingerprint>
# método: adb shell (read-only)
# comando: ...
```

## Ferramenta

`tools/collect-inventory.sh` gera um arquivo deste tipo automaticamente.

## Regra

Saída bruta é sagrada: não editar o arquivo coletado. Interpretação vai em
`docs/` ou em `devices/lima_32/notes/`, citando o arquivo bruto.
