# Dig Dig Graves

Incremental ativo isométrico em pixel art (Godot 4.7.2, GL Compatibility). Idioma de trabalho: português do Brasil; código em inglês.

## Fonte da verdade
- `docs/01_GDD.md` — regras, números, arquitetura (§18) e marcos (§19).
- `docs/02_DIRECAO_DE_ARTE.md` — tudo que é visual; paleta fechada em `docs/palette/`.
- Decisões novas de design entram nesses documentos (é o orquestrador quem os edita).

## Organização do trabalho
A sessão principal é o **orquestrador/designer-chefe**: decide design, quebra o trabalho em tarefas, delega, revisa as entregas e atualiza os docs. Não implementa features grandes nem desenha sprites diretamente.

| Agente | Responsabilidade | Escreve em |
|---|---|---|
| `pixel-artist` | Sprites, tiles, animações, ícones e UI via MCP do Aseprite | `art_src/`, `assets/`, `assets/MANIFEST.md` |
| `godot-dev` | Mecânicas, cenas, UI em código, animações de interface, dados `.tres`, save, sistema de áudio, integração de assets | `autoload/`, `data/`, `scenes/`, `tests/`, `project.godot` |
| `sound-designer` | Trilha sonora, SFX e ambiente (composição, síntese, mixagem) | `audio_src/`, `assets/music/`, `assets/sfx/`, `assets/AUDIO_MANIFEST.md`, `assets/AUDIO_CREDITS.md` |

Contratos: o `pixel-artist` registra cada asset exportado em `assets/MANIFEST.md` (arquivo, tamanho de frame, pivô, tags/fps, layout do atlas) e o `sound-designer` registra cada som em `assets/AUDIO_MANIFEST.md` por id; o `godot-dev` só integra o que está nos manifestos e usa placeholders (ou silêncio) enquanto isso. Vários agentes podem editar o mesmo manifesto: sempre com edições pontuais nas próprias linhas, nunca reescrevendo o arquivo inteiro.

Interface, animação e áudio seguem `docs/03_UI_UX.md`.

Ao delegar: passar o brief no formato da Direção de Arte §12 (arte) ou citar as seções do GDD e o critério de pronto (código). Tarefas de arte e código independentes rodam em paralelo.

## Comandos
Godot (console): `C:\Users\pedro\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- Importar/validar: `<godot> --headless --path . --import`
- Testes: `<godot> --headless --path . -s res://tests/<arquivo>.gd`

## Marco atual
**Marco A · "Capítulo 1: O Cemitério da Paróquia"** (GDD 2.0 §19, plano em `docs/06_PLANO_V1.md` §3). Jogável do título (com splash do Briba Studio) ao "Fim do Capítulo 1": economia nova, árvore com 44 nós, Pisão, Cava-Funda, lápides com efeito, Noite do Chefe com o Caixão Fujão. Decisões de design: `docs/05_DECISOES_PENDENTES.md`. Ao fechar o marco: `devlog/devlog01.md` e parar para revisão.

## Armadilhas do GDScript (já escaparam antes)
- Nunca inferir com `:=` a partir de `Dictionary`, `Array` sem tipo, `Variant` ou comparação com esses valores: declare o tipo.
- Nenhuma `class`/`class_name` com nome de classe nativa do Godot (`Sky`, `Path`, `Marker`, `Line`…).
- Neste ambiente de nuvem não há Godot executável: valide com `gdparse` e revisão; os testes rodam no Windows.
