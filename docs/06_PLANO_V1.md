# Dig Dig Graves — Plano de produção do v1.0

> Versão 1.0 · 27/10/2026 · Implementa o [01_GDD.md](01_GDD.md) **2.0**, a [03_UI_UX.md](03_UI_UX.md) Parte 2 (§10–§20) e a [02_DIRECAO_DE_ARTE.md](02_DIRECAO_DE_ARTE.md) §13. Onde este plano e o [04_REVISAO_E_ROADMAP.md](04_REVISAO_E_ROADMAP.md) divergirem, vale este plano.
> Quem edita este documento é o orquestrador. Os agentes leem o pacote deles, as seções citadas da spec e o manifesto.

---

## 0. Regras do plano

1. **Marcos jogáveis.** O v1.0 sai em 4 builds completos: **A · Capítulo 1**, **B · Capítulo 2**, **C · Capítulo 3**, **D · v1.0** (GDD §19). Cada um vai do título ao fim do capítulo, sem placeholder visível no que entra, sem crash, com save compatível com o marco anterior. Se a produção parar em qualquer marco, aquele build é o jogo.
2. **Ondas dentro de cada marco.** W1 regras/economia → W2 estágio + chefe + fluxo → W3 meta (hub, loja, construções, marcos) → W4 noite (tabuleiro, Epitáfios, ajudantes) → W5 polimento e revisão. Arte e som correm **em paralelo** desde o W1 do marco, por estágio e por sistema.
3. **Um dono por arquivo por vez.** Cada pacote lista os arquivos que **possui**; ninguém mais edita esses arquivos enquanto o pacote estiver aberto. Quando a onda fecha, a posse passa ao pacote seguinte que o lista. Dois pacotes da mesma onda **nunca** possuem o mesmo arquivo (por isso podem rodar em paralelo, inclusive com duas instâncias de `godot-dev`).
4. **Arquivos compartilhados por edição pontual** (nunca reescrever inteiro): `assets/MANIFEST.md` (pixel-artist, cada um nas suas linhas), `assets/AUDIO_MANIFEST.md` (sound-designer), `project.godot` (só o pacote marcado com ⚙ na onda; os outros pedem a ação de input/autoload no relatório).
5. **Contrato dos manifestos.** O `godot-dev` só integra ids que estão no manifesto; até lá usa placeholder (forma cinza da DA §12 M0) ou silêncio, **com o id final já no código** (troca sem tocar em lógica).
6. **Critério de pronto de todo pacote de código:** testes headless verdes (`<godot> --headless --path . -s res://tests/<arquivo>.gd`), `--import` sem erro, sem aviso novo do GDScript, números lidos de `.tres` (nada mágico no código), texto PT-BR com acentos.
7. **Critério de pronto de todo asset:** checklist DA §11.5 + linha no manifesto (arquivo, frame, pivô, tags/fps, layout).
8. **Revisão:** o orquestrador revisa cada pacote antes de fechar a onda e atualiza os docs se algo mudou.

## 1. Visão geral

| Marco | Build | Duração-alvo | Conteúdo-chave | Ondas |
|---|---|---|---|---|
| **A** | Capítulo 1: O Cemitério da Paróquia | 40–60 min | Economia nova, árvore 44, Pisão, Cava-Funda, EX/LX, lápides com efeito, Noite do Chefe + Caixão Fujão, diálogo, Fim do Capítulo 1 | W1–W5 |
| **B** | Capítulo 2: O Campo dos Indigentes | ~1h20–1h30 | Entregas B1–B5: estágio 2; progressão; hub; loja; noite avançada e fechamento | B1–B5 (W1–W5 internos) |
| **C** | Capítulo 3: As Catacumbas de Pedra | ~2h10–2h20 | Estágio 3 + Raiz-Mãe, árvore 84, Mascate 12, Epitáfios 16, Gato, +3 construções, 15 marcos | W1–W5 |
| **D** | v1.0 | final ~3h30–4h, 100% ~5 h | Estágios 4–5 + 2 chefes, final e créditos, árvore 100 + Duas Raízes, Mascate 20, Epitáfios 24, 4 ajudantes, 9 construções, 20 marcos, gamepad e daltônico | W1–W5 |

Quantidades por sistema e marco: GDD §1.1.

## 2. Mapa de arquivos (quem possui o quê)

| Área de código | Arquivos | Pacotes que possuem (em ordem) |
|---|---|---|
| Tipos de dados | `data/types/balance_data.gd`, `layer_data.gd`, `tool_data.gd`, `stat_modifier.gd` | A-W1-ECON → B-W3-LOJA (tool_data) |
| | `data/types/skill_node_data.gd` | A-W1-ARVORE |
| | `data/types/stage_data.gd`, `boss_data.gd` (novos; `area_data.gd` vira alias) | A-W2-CHEFE → B-W2-EST2 → C-W2-EST3 → D-W2-EST4 → D-W2-EST5 |
| | `data/types/board_element_data.gd` (novo) | A-W4-TABULEIRO → B-W4-ELEM → C-W2-EST3 → D-W2-EST4/5 |
| | `data/types/dialogue_data.gd` (novo) | A-W2-FLUXO |
| | `data/types/epitaph_data.gd`, `item_data.gd`, `building_data.gd`, `milestone_data.gd` (novos) | B-W4-EPI · B-W3-LOJA · B-W3-HUB · C-W3-MARCOS |
| Dados `.tres` | `data/balance.tres`, `data/areas/layers/*` | A-W1-ECON (depois, ajuste fino só no W5 de cada marco) |
| | `data/skill_nodes/*.tres` | W1-ARVORE de cada marco |
| | `data/stages/*.tres`, `data/bosses/*.tres` | W2 de cada marco |
| | `data/board/*`, `data/dialogue/*`, `data/epitaphs/*`, `data/items/*`, `data/hub/*`, `data/milestones/*` | pacote do sistema no marco |
| Modelo do turno | `scenes/run/model/field_model.gd`, `run_state.gd`, `turn_result.gd` | A-W1-ECON → A-W2-CHEFE → A-W4-TABULEIRO → (B, C, D: W1-REGRAS → W2 → W4) |
| | `scenes/run/model/boss_state.gd` (novo) | W2-CHEFE de cada marco |
| | `scenes/run/model/board_elements.gd`, `epitaph_deck.gd`, `helpers.gd` (novos) | W4 de cada marco |
| Cena do turno | `scenes/run/run.gd`, `hud.gd`, `hud_*.gd`, `field_view.gd`, `field_decor.gd`, `grave_view.gd` | A-W1-HUD → A-W2-CHEFE (boss_view) → A-W4 … |
| | `scenes/run/boss_view.gd`, `actives_hud.gd`, `element_views.gd`, `helper_views.gd`, `epitaph_overlay.gd` (novos) | pacote que cria; depois W de cada marco |
| | `scenes/run/turn_summary.gd` | A-W2-FLUXO → B-W5 … |
| Árvore/hub | `scenes/tree/*` | A-W1-ARVORE → (cada marco: W1-ARVORE) |
| | `scenes/hub/*` (novo: `hub_surface.gd`, `stage_selector.gd`, `face_button.gd`, `building_view.gd`, `shop_panel.gd`, `milestones_panel.gd`) | A-W3-HUB → B-W3-HUB / B-W3-LOJA (arquivos distintos) → C-W3 → D-W3 |
| UI geral | `scenes/ui/dialogue_box.gd`, `chapter_end.gd`, `confirm_stone.gd` (novos), `options_menu.gd` (pausa) | A-W2-FLUXO |
| | `scenes/ending/*` (novo) | D-W2-FINAL |
| Autoloads | `autoload/game.gd` (fluxo de cenas) | A-W2-FLUXO → B/C/D-W5 |
| | `autoload/progress.gd` (novo: estágios, chefes, Inquietação, itens, hub, marcos) | A-W2-CHEFE → W3 de cada marco |
| | `autoload/save_io.gd`, `save_manager.gd` | A-W5-SAVE → W5 de cada marco |
| | `autoload/stat_sheet.gd`, `stats.gd`, `economy.gd` | A-W1-ECON |
| | `autoload/audio_bank.gd` (registro de ids) | A-W1-HUD → W5 de cada marco |
| Projeto | `project.godot` (inputs, autoloads) | ⚙: A-W1-HUD, A-W2-CHEFE, B-W1-REGRAS, D-W5-POLISH |
| Testes | `tests/test_<pacote>.gd` | o próprio pacote; `tests/sim_campaign.gd`: A-W1-ECON → W5 de cada marco |
| Arte | `art_src/**`, `assets/sprites/**`, `assets/tiles/**`, `assets/ui/**` + linhas do `MANIFEST.md` | pixel-artist, por pacote ART |
| Som | `audio_src/**`, `assets/music/**`, `assets/sfx/**` + linhas do `AUDIO_MANIFEST.md`, `AUDIO_CREDITS.md` | sound-designer, por pacote SND |

---

## 3. Marco A · "Capítulo 1: O Cemitério da Paróquia"

**Critério de pronto do marco:** jogável do título ao "Fim do Capítulo 1" e "Continuar cavando"; chefe 1 aos 35–45 min (3 playtests internos + `sim_campaign`); 1º nó ≤ 40 s; nenhuma sequência de 5 noites sem compra; nenhum placeholder visível; save da demo/M0 migra sem perder moedas.

### W1 · Regras e economia (código) — 3 pacotes em paralelo
**A-W1-ECON · Economia v2 e modelo do campo** — `godot-dev`
- Spec: GDD §4.2–4.5, §4.6 (covas, sem tipos), §4.7, §5, §14.4, §18.2, §18.4; DA §7.
- Possui: `data/types/balance_data.gd`, `layer_data.gd`, `tool_data.gd`, `stat_modifier.gd`; `data/balance.tres`; `data/areas/layers/*.tres` (+ `layer_ossada.tres`); `scenes/run/model/field_model.gd`, `run_state.gd`, `turn_result.gd`; `autoload/stat_sheet.gd`, `stats.gd`, `economy.gd`; `tests/test_economy_v2.gd`, `tests/sim_campaign.gd` (novos), `tests/sim_first_turn.gd`, `tests/test_core.gd`.
- Faz: campo 5×5 (teto 18); `area_step` + `ToolData.cells(anchor, w, h, rot)` (RECT/LINE/CROSS/DIAMOND); Cobre por ponto da §4.3; Ossada como camada extra por flag; `apply_damage(carry)` (Cava-Funda); crítico por tile; caixão 1,5×; covas 1 → teto 7; fogo-fátuo 80% e stats `wisp_*`; teto do óleo de cova; Campo Limpo "desde o último"; amanhecer; stats e flags novos da §18.2 com rótulos na Ficha; **Pisão no modelo** (`use_stomp()`, recarga, ×4, anel, auto a cada 8); `sim_campaign.gd` (porta a simulação do GDD §14 para Godot, roda o estágio 1 com política gulosa e imprime os marcos de tempo para cinco sementes reproduzíveis por padrão; `MARCO_A_TEST_SEED` seleciona uma semente e `MARCO_A_TEST_SEEDS` aceita uma lista separada por vírgulas).
- Assets: consome `dig_bone` ✔.
- Pronto: `test_economy_v2` cobre área por passos (0–10), carry, Cobre por ponto, teto de óleo, decaimento 0,8, Campo Limpo; `sim_first_turn` dá 24 ± 5 Cobre; `sim_campaign` (estágio 1, sem chefe) chega a área 3×3 entre 25 e 35 min.
- Depende de: nada.

**A-W1-ARVORE · Árvore v2 (44 nós do marco A)** — `godot-dev`
- Spec: GDD §6 (tabelas, só Marco A), §15; UI/UX §7, §18; DA §10.3, §13.4.
- Possui: `data/types/skill_node_data.gd`; `data/skill_nodes/*.tres` (44 nós A); `scenes/tree/*` (inclui `tree_minimap.gd`); `tests/test_ui_logic.gd`, `tests/test_tree_minimap_runtime.gd`.
- Faz: campos `kind`, `exclusive_group`, `requires`, `reveal_trigger`, `required_stage`, `flags`, `grid`; posição = (968 + 88k, 240 + 64r); mundo 1936×1024 com os assets `tree_*` existentes; raízes desenhadas em pixel por `RootLayer` com rotações verificadas contra caixas dos nós; Raízes-mestras em Almas 1.500 × 3ⁿ; encruzilhada com selagem; revelação por gatilho; estados selado/oculto/sem dinheiro; minimapa clicável e arrastável, atalhos 1–7, Home e Shift+roda.
- Assets: consome `medallions32`, `node_icons`, `pips`, `fx_tree_new_badge`, `minimap_frame`, `seal`, `node_buy` e `root_grow`.
- Pronto: 44 nós com custo/efeito da tabela; nenhuma caixa sobreposta (teste de `TreeLayout`); comprar E12a sela E12b; 2ª mestra custa 4.500; minimapa enquadra o mundo, carrega sua moldura e move a câmera por clique/arrasto.
- Depende de: lista de stats/flags do GDD §18.2 (não bloqueia; os ids já estão fixados).
**A-W1-HUD · Entrada, Pisão no HUD e áudio do turno** — `godot-dev` ⚙
- Spec: GDD §4.4, §16; UI/UX §13.1 (marco A), §13.3.
- Possui: `scenes/run/run.gd`, `hud.gd`, `hud_lantern.gd`, `hud_medal.gd`, novo `scenes/run/actives_hud.gd`; `autoload/audio_bank.gd`; `project.godot` (ações `stomp`, `flare`, `face_boss`, `tree_branch_1..7`, `tree_home`); `scenes/ui/options_menu.gd` (opção auto-pisão); `tests/test_hud_actives.gd`.
- Faz: clique/Q/A chamam `use_stomp()`; plaqueta do ativo com pips e estados; anel `fx_stomp` + tremor; barra de XP oculta no marco A (flag `epitaphs`); opção **auto-pisão**.
- Assets: `hud_stomp`, `hud_active_frame`, `hud_pips`, `fx_stomp` (ART-A2); `stomp` ✔, `stomp_ready` ✔ (SND-A).
- Pronto: Pisão jogável por mouse, teclado e auto-pisão; sem input quando pausado.
- Depende de: A-W1-ECON (API `use_stomp()`; combinar a assinatura no início).

### W2 · Estágio data-driven, chefe e fluxo (código) — 2 pacotes em paralelo
**A-W2-CHEFE · StageData, Inquietação e Noite do Chefe com o Caixão Fujão** — `godot-dev` ⚙
- Spec: GDD §4.11, §10.1 (linha 1), §10.2 (chefe 1), §18.3; UI/UX §13.2.
- Possui: `data/types/stage_data.gd`, `boss_data.gd` (+ `area_data.gd` como alias de compatibilidade); `data/stages/stage_1.tres`; `data/bosses/caixao_fujao.tres`; `scenes/run/model/boss_state.gd`; `scenes/run/model/run_state.gd` (passa a ele nesta onda), `field_model.gd`; `scenes/run/boss_view.gd`; `scenes/run/hud.gd` (barra do chefe); `autoload/progress.gd` (novo) + `project.godot` (autoload); `tests/test_boss_hop.gd`, `tests/test_boss_outcomes.tscn`.
- Faz: `StageData` com multiplicadores separados de Cobre/Ossos/Almas, N de covas para a Inquietação; `Progress` guarda Inquietação por estágio, chefes vencidos/tentativas, estágio liberado; `BossState` com comportamento `HOP` (4 s, 0,6 s invulnerável); dano por tiles sobrepostos; fuga com HP cheio; vitória com prêmios e `unlocks`; revanche 20%; tremores (+25% Almas).
- Assets: `boss_caixao_fujao` ✔, `boss_caixao_buraco` ✔, `icon_boss_caixao` ✔, `barra_chefe`, `icon_key_1` (ART-A2); `mus_boss` ✔, `stinger_boss_appear` ✔, `boss_hit/sink/emerge/defeat` ✔, `jingle_boss_win` ✔, `boss_flee` ✔ (SND-A).
- Pronto: `test_boss_hop` cobre HOP; `test_boss_outcomes` cobre fuga, vitória, prêmios, desbloqueio, persistência e revanche; chefe vencível em `sim_campaign` aos 35–45 min.
- Depende de: A-W1-ECON fechado.

**A-W2-FLUXO · Diálogo, Resumo especial, Fim do Capítulo e pausa** — `godot-dev`
- Spec: GDD §3.4, §13.2, §15; UI/UX §13.3, §14, §15, §19.1, §20.
- Possui: `data/types/dialogue_data.gd`; `data/dialogue/*.tres` (≈14 falas do A: 1º turno, 1ª cova, 1º nó, Inquietação cheia, início/vitória do chefe, fim do capítulo); `scenes/ui/dialogue_box.gd` (+ `.tscn`), `scenes/ui/chapter_end.gd` (+ `.tscn`), `scenes/ui/confirm_stone.gd`; `scenes/run/turn_summary.gd`; `autoload/game.gd`; `scenes/ui/options_menu.gd` (pausa: Abandonar/Voltar ao título — recebe de A-W1-HUD ao fechar W1); `tests/test_dialogue_runtime.tscn`, `test_chapter_end_runtime.tscn`, `test_chapter_end_flow.tscn`.
- Faz: balão bloqueante e dica; máquina de escrever 40 c/s com `dialog_blip_*`; Resumo especial e faixa de derrota; "Fim do Capítulo 1" (1× por save) com Créditos e Continuar cavando; fluxo completo da UI/UX §20 para o marco A.
- Assets: `portrait_dona_ceifa` ✔, `portrait_tiao` ✔, `portrait_coveiro` ✔, `balao` ✔, `balao_rabicho` ✔, `chapter_card` ✔, `icon_key_1` ✔; `dialog_blip_ceifa/tiao` ✔, `jingle_chapter_end` ✔, `key_get` ✔.
- Pronto: dá para pular qualquer conversa; nenhuma tela sem volta; textos revisados (acentos).
- Depende de: A-W2-CHEFE (sinais de vitória/derrota) — combinar os sinais em `Events` no início da onda.

### W3 · Meta mínima (código)
**A-W3-HUB · Pátio de navegação da Árvore** — `godot-dev`
- Spec: GDD §10.3, §11; UI/UX §10.1, §10.3–10.5.
- Possui: `scenes/tree/skill_tree_screen.gd`; estações do Pátio em overlay sobre o cenário.
- Faz: entrada no Pátio com carteira e quatro destinos: Raízes/Talentos, Próxima Noite (Paróquia, início em um clique), Loja (bloqueada até B) e Fazenda (futuro); ação de Enfrentar vinculada à Próxima Noite quando a Inquietação chega a 100%; botão Pátio retorna da Árvore ao enquadramento inicial. Sem seletor de estágios no Marco A.
- Assets: cenário e kit visual existentes; estações são UI; `unrest_warning` ✔.
- Pronto: Pátio → Árvore → Pátio e Pátio → Noite funcionam; opções e carteira permanecem acessíveis; destinos futuros são claramente desabilitados.
- Depende de: A-W2-CHEFE (Progress).
**A-W4-TABULEIRO · Lápides com efeito, velas, moeda de ouro, alminhas** — `godot-dev`
- Spec: GDD §4.6 (tipos 0–2), §4.8 (linhas do marco A); DA §13.1.
- Possui: `AreaData.grave_type_weights`; `run_state.gd`, `field_model.gd` (recebem de A-W2-CHEFE); `grave_view.gd` e `hud.gd`; `tests/test_grave_types.gd`.
- Faz: tipo de lápide sorteado por peso da `AreaData` (StageData herda), com sprite e tooltip; Cruz de pedra (+1 Alma); Lápide com musgo (Caixão 1,5× mais duro e Ossos ×2); vela (aura de regen/Cobre); moeda de ouro (F09); alminhas (S04); `Kind` novos no `FieldModel`.
- Assets: `lapide` (colunas 0–2 legíveis), `vela_campo`, `moeda_ouro`, `alma_fila` ✔ (ART-A1); `tombstone_effect` ✔, `coin_gold` ✔, `soul_wander` ✔.
- Pronto: testes verificam pesos, sprites e efeitos dos três tipos; em playtest, aos 20 min, o jogador vê ≥ 3 elementos em 30 s e entende seus efeitos sem ler texto.
- Depende de: A-W2-CHEFE fechado.

### W5 · Polimento e fechamento
**A-W5-SAVE · Save v2 e migração** — `godot-dev` · Possui `autoload/save_io.gd`, `save_manager.gd`, `tests/test_save_migration.gd`, `tests/test_save_atomicity.gd`, `tests/test_save_compat.tscn` e `tests/fixtures/save_m0_v1.json`. Faz o GDD §18.5 (v1 → v2 com devolução do gasto). Pronto: fixture M0 é carregada pelo jogo, devolve o gasto da árvore e faz round-trip em v2 preservando moedas, opções, telemetria e progresso compatível.
**A-W5-POLISH · Ritmo, juice e revisão** — `godot-dev` (+ orquestrador) · Possui `data/balance.tres`, `data/skill_nodes/*.tres`, `data/stages/stage_1.tres` (ajuste fino), `tests/sim_campaign.gd`. Faz as regras do GDD §14.3 com 3 playtests; confere todos os sons/sprites do marco; nenhum `push_warning` novo. Pronto: critério do marco.

### Arte e som do marco A (paralelo ao W1–W4)
| Pacote | Dono | Produz (ids) | Consumido por | Pronto até |
|---|---|---|---|---|
| **ART-A1 · Tabuleiro do estágio 1** | pixel-artist | coluna Ossada em `tiles_a1`/`_lit`/`cracks_a1`/`regen_a1`; `lapide` com colunas 0–2 revisadas para leitura do tipo; `vela_campo`; `moeda_ouro`; `icon_key_1` (16 e 32, giro 4f) | A-W1-ECON, A-W4, A-W2-FLUXO | ✔ entregue |
| **ART-A2 · Árvore larga, HUD, Pátio e encerramento** | pixel-artist | `frame_at/r/d`, `frame_master_*` (×6 + sombra), `frame_sealed`, `root_y`, `tree_soil_wide`, `tree_sky_wide`, `tree_grass_wide`, `minimap_frame`, `hud_stomp`, `hud_active_frame`, `hud_pips`, `fx_stomp`, `barra_chefe`, `chapter_card` | A-W1-ARVORE, A-W1-HUD, A-W2, A-W3 | ✔ entregue (molduras, mestras, selado, `root_y` e fundos largos em `881e49c`) |
| ART-A3 · Chefe 1 e retratos | pixel-artist | ✔ já entregue (`boss_caixao_*`, `icon_boss_caixao`, retratos, `balao`) | A-W2 | ✔ |
| **ART-A4 · Ícones de nó** | pixel-artist | 44 ícones 16×16 exclusivos, catalogados em `assets/MANIFEST.md` e integrados à árvore | A-W1-ARVORE | ✔ entregue |
| **SND-A · Áudio do capítulo 1** | sound-designer | `stomp_ready`, `boss_flee`, `key_get`, `stage_select`, `jingle_chapter_end`, `constellation`, `second_wind` conferidos no manifesto e no disco | A-W1-HUD, A-W2, A-W3 | ✔ entregue |

---

## 4. Marco B · "Capítulo 2: O Campo dos Indigentes"

**Critério de pronto do marco:** jogável do título ao "Fim do Capítulo 2"; save do A continua; chefe 2 a ~1h20 (±15); cada noite do estágio 2 tem ≥ 2 decisões; hub, loja e Epitáfios com arte e som finais.

O Marco B é entregue em cinco builds incrementais. Cada build parte do anterior, mantém a compatibilidade do save e tem um resultado jogável próprio. A ordem abaixo também permite validar o estágio e o ritmo antes de ampliar a meta progressiva. Os pacotes W1–W5 abaixo detalham o trabalho; esta lista define os pontos de integração e aceite.

| Entrega | Resultado jogável e aceite | Pacotes incluídos |
|---|---|---|
| **B1 · Campo dos Indigentes** | Um seletor mínimo libera o estágio 2, com diorama e elementos próprios; Seu Damião pode ser enfrentado e vencido; chave e desbloqueio persistem. Build de título a vitória do chefe, sem hub/loja novo obrigatório. | B-W2-EST2, B-W2-CHEFE e fatia do seletor de B-W3-HUB; arte/som ART-B1–B2 e dependências do estágio. |
| **B2 · Novas escolhas de progressão** | Árvore passa a 64 nós; Clarão funciona; barra de XP, fila de níveis e tela de escolha passam a operar; Replantar devolve 100% e reseta o multiplicador. Save B1 continua abrindo. | B-W1-ARVORE, B-W1-REGRAS; ART-B3/B5 e sons correspondentes. |
| **B3 · Superfície e construções** | Hub apresenta Portão, Casa, Capelinha e Barraca com estados e efeitos; retratos de Mascate e Madame Ossada; navegação de retorno ao campo. Critério: construções e estado persistem após salvar/carregar. | Restante de B-W3-HUB (o seletor mínimo já entrou em B1); parte de ART-B3/SND-B. |
| **B4 · Mascate** | Loja permite comprar/equipar os cinco itens, trocar pá no início da noite e usar dois espaços; escolhas de item/pá ficam disponíveis em runs do estágio 2. | B-W3-LOJA; parte de ART-B3/SND-B. |
| **B5 · Noite completa e capítulo** | Oito Epitáfios com sorteio, pausa, escolha e rerrolagem; Tita, baús e Ossário; diálogos, resumo e "Fim do Capítulo 2". Save do A compatível, chefe no alvo de ritmo e ≥2 decisões por noite no estágio 2; arte e som finais. | B-W4-EPI, B-W4-ELEM, B-W5-POLISH; ART-B4 e fechamento de SND-B. |

**Regra de fechamento:** cada entrega deve compilar e abrir como build jogável, com seu próprio checklist de aceite e save migrável para a seguinte. B5 fecha o critério integral do Marco B. Arte e som podem avançar em paralelo, mas só contam como aceitos quando integrados e revisados no build que os consome.

### W1 · Regras
**B-W1-ARVORE · +20 nós (B)** — `godot-dev` · Spec GDD §6 (linhas B), §8 (F06), §6.2 (Replantar) · Possui `data/skill_nodes/*` (novos B), `scenes/tree/*`, `tests/test_tree_v2.gd` · Faz os 20 nós, **Replantar** (UI/UX §16, com `respec` ✔) e FX · Pronto: Replantar devolve 100% e zera o ×3 · Depende de: A fechado.
**B-W1-REGRAS · Clarão, Epitáfios no modelo, FX/L07** — `godot-dev` ⚙ · Spec GDD §4.4 (Clarão), §4.9, §4.7 (Chuva de Moedas) · Possui `scenes/run/model/run_state.gd`, `field_model.gd`, `scenes/run/actives_hud.gd`, `hud.gd`, `run.gd`, `project.godot`, `tests/test_economy_v2.gd` · Faz Clarão (custo de óleo, luz máxima, +50%), barra de XP visível com N02, fila de níveis (sem a tela: só o sinal), L07a/b, `coin_rain` · Assets `hud_flare`, `fx_flare` (ART-B3); `flare` ✔, `flare_ready`* · Pronto: Clarão por mouse/teclado; XP do estágio ×3.

### W2 · Estágio 2 e chefe 2
**B-W2-EST2 · Estágio 2 data-driven** — `godot-dev` · Spec GDD §10.1 (linha 2), §4.8 (fantasma, poça, cruz), §4.6 (lápide rachada); DA §13.1 · Possui `data/stages/stage_2.tres`, `data/types/stage_data.gd`, `data/board/*` (novos), `scenes/run/model/board_elements.gd`, `scenes/run/element_views.gd`, `scenes/run/field_view.gd`, `field_decor.gd`, `diorama_block.gd`, `tests/test_board.gd` · Faz troca de diorama por `StageData` (tiles, bloco, fundo, cerca, placa, música, ambiente), fantasma travesso (tapa buraco), poça de lama (obstáculo), cruz de madeira (C15), lápide rachada · Assets estágio 2 ✔ (`tiles_a2` … `bg_a2_*`, `cruz_madeira`, `lapide_a2`, `poca_lama`) + `fantasma`, coluna Ossada do `tiles_a2`, coluna 3 da `lapide_a2` (ART-B1); `mus_area2` ✔, `dig_mud` ✔, `ghost_appear/fill/pop`*, `cross_break`* · Pronto: estágio 2 jogável pelo seletor com tudo final.
**B-W2-CHEFE · Seu Damião (TRAIL)** — `godot-dev` · Spec GDD §10.2 (chefe 2) · Possui `scenes/run/model/boss_state.gd`, `scenes/run/boss_view.gd`, `data/bosses/seu_damiao.tres`, `data/dialogue/*` (falas do chefe 2), `tests/test_boss.gd` · Faz trilha marcada, tapar buracos, dano só em tiles marcados, vitória com unlocks (estágio 3 em silhueta "em breve", Gato na árvore oculto até C) · Assets `boss_damiao`, `icon_boss_damiao` (ART-B2); `boss_*` ✔, `dialog_blip_damiao`* · Pronto: `test_boss` cobre TRAIL.

### W3 · Hub e Mascate (em paralelo; arquivos distintos)
**B-W3-HUB · Construções do hub** — `godot-dev` · Spec GDD §11.1 (linhas B), UI/UX §10.2 · Possui `data/types/building_data.gd`, `data/hub/*.tres` (Portão, Casa, Capelinha, Barraca), `scenes/hub/building_view.gd`, `hub_surface.gd`, `autoload/progress.gd`, `tests/test_hub.gd` · Faz estados ruína/restaurada/comprável, painel de obra, animação de obra, fonte `hub` no StatSheet, personagens da superfície (Mascate, Madame Ossada) · Assets `bld_portao*`, `bld_casa*`, `bld_capela*`, `bld_barraca*` (ART-B3), `mascate` ✔, `madame_ossada`; `build_complete` ✔ · Pronto: 4 construções com efeito na Ficha.
**B-W3-LOJA · Mascate (5 itens, 2 espaços)** — `godot-dev` · Spec GDD §8; UI/UX §11 · Possui `data/types/item_data.gd`, `data/types/tool_data.gd`, `data/items/*.tres` (Pá de Bico, Enxadão, Dentadura, Terço, Retrato), `data/tools/*.tres`, `scenes/hub/shop_panel.gd` (+ `.tscn`), `tests/test_shop.gd` · Faz prateleira, estados, equipar, troca de pá no início da noite, giro do Enxadão (roda/R), fonte `items` no StatSheet, desconto F06 · Assets `shop_slot`, `shop_tabs`, `icon_item_*` (5), `portrait_mascate` ✔; `mus_shop` ✔, `shop_bell/buy/deny` ✔, `shop_equip`*, `dialog_blip_mascate` ✔ · Pronto: comprar, equipar e jogar com cada pá.

### W4 · Noite
**B-W4-EPI · Epitáfios (8)** — `godot-dev` · Spec GDD §7 (linhas B), §4.9; UI/UX §12, §13.1 · Possui `data/types/epitaph_data.gd`, `data/epitaphs/*.tres`, `scenes/run/model/epitaph_deck.gd`, `scenes/run/epitaph_overlay.gd` (+ `.tscn`), `scenes/run/hud.gd` (fileira), `tests/test_epitaphs.gd` · Faz sorteio por peso, fila, pausa, Embaralhar, Capelinha (Raro no nível 5), fonte `night` no StatSheet · Assets `ui_card_*`, `ui_card_back`, `card_art_*` (8), `icon_epitaph_*` (8), `portrait_madame_ossada` ✔; `card_flip/pick/legendary` ✔, `card_reroll`*, `dialog_blip_ossada` ✔ · Pronto: 8 cartas com efeito verificável em teste.
**B-W4-ELEM · Tita, baús e Ossário** — `godot-dev` · Spec GDD §9 (Tita), §4.8 (baú, ossário) · Possui `scenes/run/model/helpers.gd`, `scenes/run/helper_views.gd`, `scenes/run/model/board_elements.gd` (recebe de B-W2-EST2), `scenes/run/element_views.gd`, `data/board/bau.tres`, `ossario.tres`, `tests/test_helpers.gd` · Assets `tita`, `bau`, `ossario` (ART-B4); `helper_mole` ✔, `chest_open` ✔, `bone_rain` ✔ · Pronto: Tita cava; baú pode dar amuleto não comprado.

### W5
**B-W5-POLISH** — `godot-dev` + orquestrador · Possui `data/**/*.tres` (ajuste), `autoload/game.gd`, `scenes/ui/chapter_end.gd`, `scenes/run/turn_summary.gd`, `autoload/save_io.gd`, `tests/test_save_compat.tscn`, `tests/sim_campaign.gd` · Faz "Fim do Capítulo 2", diálogos do B (~20 falas), revisão de ritmo §14.3, compatibilidade A → B.

### Arte e som do marco B
| Pacote | Dono | Produz | Pronto até |
|---|---|---|---|
| ART-B1 · Estágio 2 (complemento) | pixel-artist | coluna Ossada em `tiles_a2`/`_lit`/`cracks_a2`/`regen_a2`; `lapide_a2` col. 3 (rachada); `fantasma` | W2 |
| ART-B2 · Seu Damião chefe | pixel-artist | `boss_damiao` (walk/fill/hit/defeat + `trail`), `icon_boss_damiao`, `icon_key_2` | W2 |
| ART-B3 · Hub B, Clarão e loja | pixel-artist | `bld_portao`, `bld_casa`, `bld_capela`, `bld_barraca` (+ `_ruina`), `madame_ossada`, `shop_slot`, `shop_tabs`, `icon_item_*` ×5, `hud_flare`, `fx_flare`, `fx_coin_rain` | W3 |
| ART-B4 · Cartas e noite | pixel-artist | `ui_card_comum/raro/lendario`, `ui_card_back`, `card_art_*` ×8, `icon_epitaph_*` ×8, `tita`, `bau`, `ossario` | W4 |
| ART-B5 · Ícones de nó B | pixel-artist | 20 ícones 16×16 | W1 |
| SND-B | sound-designer | `flare_ready`, `card_reroll`, `ghost_appear`, `ghost_fill`, `ghost_pop`, `cross_break`, `shop_equip`, `dialog_blip_damiao`, `coin_rain`, `amb_field` | W3 |

---

## 5. Marco C · "Capítulo 3: As Catacumbas de Pedra"

**Critério:** jogável até o "Fim do Capítulo 3"; saves de A e B compatíveis; chefe 3 a ~2h10 (±15); 15 marcos disparando sem custo de desempenho.

| Onda | Pacote | Dono | Spec | Possui | Assets (consome) | Pronto | Depende |
|---|---|---|---|---|---|---|---|
| W1 | **C-W1-ARVORE** · +20 nós (CX, AX, C09, E17–E19…) | godot-dev | GDD §6 (C) | `data/skill_nodes/*` (C), `scenes/tree/*` | ícones C (ART-C5), `seal` ✔ | 84 nós; C09 sela; CX nasce o Mausoléu (flag) | B fechado |
| W1 | **C-W1-REGRAS** · Mausoléu CX, Coral, Prenúncio, Bola de Cristal, Dízimo, 3º espaço | godot-dev | GDD §4.8 (Mausoléu), §6 flags | `run_state.gd`, `field_model.gd`, `epitaph_deck.gd`, `tests/test_economy_v2.gd` | `mausoleu_cx` (ART-C4) | flags testadas | B fechado |
| W2 | **C-W2-EST3** · Estágio 3: escuridão e raízes | godot-dev | GDD §10.1 (3), §4.8 (raiz, escuridão); DA §13.1 | `data/stages/stage_3.tres`, `stage_data.gd`, `board_element_data.gd`, `data/board/raiz.tres`, `board_elements.gd`, `element_views.gd`, `field_view.gd` (`_dark`) | `tiles_a3*` (+`_dark`), `bg_a3_*`, `bloco_a3`, `lapide_a3`, `raiz` (ART-C1); `mus_area3` ✔, `dig_stone` ✔, `root_break`*, `amb_catacomb`* | estágio 3 final pelo seletor | C-W1 |
| W2 | **C-W2-CHEFE** · A Raiz-Mãe (BULBS) | godot-dev | GDD §10.2 (3) | `boss_state.gd`, `boss_view.gd`, `data/bosses/raiz_mae.tres`, `data/dialogue/*` (C) | `boss_raiz_mae`, `icon_boss_raiz`, `icon_key_3` (ART-C2); `boss_phase`* | `test_boss` cobre BULBS | C-W1 |
| W3 | **C-W3-HUB** · Poço, Canteiro, Torre; Damião no hub | godot-dev | GDD §11.1 (C) | `data/hub/*` (C), `building_view.gd`, `hub_surface.gd`, `progress.gd` | `bld_poco/canteiro/torre*`, `damiao_hub`, `portrait_damiao` (ART-C3) | 6 construções | C-W2 |
| W3 | **C-W3-LOJA** · +7 itens (Picareta, Jardineiro…) | godot-dev | GDD §8 (C) | `data/items/*` (C), `data/tools/*`, `tool_data.gd`, `shop_panel.gd`, `tests/test_shop.gd` | `icon_item_*` ×7 (ART-C3) | Picareta em cruz com ×3 em Pedra | C-W2 |
| W3 | **C-W3-MARCOS** · 15 marcos, toast e painel | godot-dev | GDD §13.1; UI/UX §17 | `data/types/milestone_data.gd`, `data/milestones/*` (15), `scenes/hub/milestones_panel.gd`, `scenes/ui/toast.gd`, `tests/test_milestones.gd` | `icon_milestone_*` ×15, `toast_frame` (ART-C4); `milestone` ✔, `ui_toast`* | contadores no save; prêmios na fonte `milestones` | C-W2 |
| W4 | **C-W4-EPI** · +8 Epitáfios | godot-dev | GDD §7 (C) | `data/epitaphs/*` (C), `epitaph_deck.gd`, `epitaph_overlay.gd` | `card_art_*` ×8, `icon_epitaph_*` ×8 (ART-C4) | 16 cartas | C-W1 |
| W4 | **C-W4-GATO** · Gato Breu + coroa de flores | godot-dev | GDD §9, §4.6 (col. 4) | `helpers.gd`, `helper_views.gd`, `board_elements.gd` (recebe de C-W2-EST3) | `gato_breu`, `lapide_*` col. 4 (ART-C4); `helper_cat` ✔ | Gato marca tiles; Sete Vidas marca cova | C-W2 |
| W5 | **C-W5-POLISH** · Fim do Cap. 3, compat A/B → C, ritmo | godot-dev + orquestrador | GDD §14.3, §18.5 | `data/**` (ajuste), `game.gd`, `chapter_end.gd`, `save_io.gd`, testes de compat | — | critério do marco | W1–W4 |

**Arte e som do C:** ART-C1 estágio 3 completo (tiles + `_dark` + rachaduras + regen + covas + lápides + bloco + fundo + `raiz`) · ART-C2 Raiz-Mãe · ART-C3 hub C, Damião no hub, retrato do Damião, 7 ícones de item · ART-C4 8 cartas, 15 ícones de marco, `toast_frame`, `gato_breu`, `mausoleu_cx`, lápide col. 4 em todos os `lapide_aN` existentes · ART-C5 20 ícones de nó · SND-C: `root_break`, `combo`, `boss_phase`, `amb_catacomb`, `ui_toast`, `heir_spawn` (antecipa D).

---

## 6. Marco D · v1.0

**Critério:** final aos 3h30–4h e árvore inteira em ~5–6 h (mediana de 5 testadores ±20%); zero bloqueio de progressão; 60 fps com campo 18×18 e área 6×6; saves A–C compatíveis; gamepad completo; modo daltônico; texto revisado.

| Onda | Pacote | Dono | Spec | Possui | Assets | Pronto |
|---|---|---|---|---|---|---|
| W1 | **D-W1-ARVORE** · +16 nós (N05, SX, E20, E21, C17, C18…) | godot-dev | GDD §6 (D) | `data/skill_nodes/*` (D), `scenes/tree/*` | ícones D (ART-D6) | 100 nós; Duas Raízes libera o 2º lado |
| W1 | **D-W1-REGRAS** · Farol, Jardim Florido, Alminha Dourada, SX | godot-dev | GDD §6 flags | `run_state.gd`, `field_model.gd`, `epitaph_deck.gd` | — | flags testadas |
| W2 | **D-W2-EST4** · Estágio 4 + baú dos barões + lápide de anjo | godot-dev | GDD §10.1 (4), §4.8 | `stage_4.tres`, `board_elements.gd`, `element_views.gd`, `data/board/*` (D) | ART-D1; `mus_area4` ✔, `dig_marble` ✔ | estágio 4 final |
| W2 | **D-W2-CHEFES** · Mausoléu Vivo (PHASES) e Cova da Dona Ceifa (CYCLE) | godot-dev | GDD §10.2 (4–5) | `boss_state.gd`, `boss_view.gd`, `data/bosses/*` (D), `data/dialogue/*` (D) | ART-D2; `heir_spawn`*, `ceifa_layer`* | `test_boss` cobre PHASES/CYCLE |
| W2 | **D-W2-EST5** · Estágio 5 + névoa + lápide flutuante | godot-dev | GDD §10.1 (5), §4.8 | `stage_5.tres`, `stage_data.gd`, `field_view.gd` (névoa) | ART-D1; `mus_area5` ✔, `dig_mist` ✔, `mist_fade`*, `amb_mist`* | estágio 5 final (depois de D-W2-EST4 liberar `board_elements.gd`) |
| W2 | **D-W2-FINAL** · Diálogo final, cena de encerramento, créditos, "Fim", título pós-final | godot-dev | GDD §13.3; UI/UX §19.2 | `scenes/ending/*` (novo), `scenes/title/title_screen.gd` (variante pós-final), `autoload/game.gd` | ART-D4; `mus_ending` ✔, `credits_roll`* | final completo, pulável depois da 1ª vez |
| W3 | **D-W3-HUB** · Galinheiro, Jazigo, Coreto, 4º espaço | godot-dev | GDD §11.1 (D) | `data/hub/*` (D), `building_view.gd`, `progress.gd` | ART-D3 | 9 construções |
| W3 | **D-W3-LOJA** · +8 itens (Pá Fantasma, Pá Benta…) | godot-dev | GDD §8 (D) | `data/items/*` (D), `data/tools/*`, `tool_data.gd`, `shop_panel.gd` | ART-D3 | 20 itens, Pá Fantasma atinge névoa |
| W3 | **D-W3-MARCOS** · +5 marcos | godot-dev | GDD §13.1 (D) | `data/milestones/*` (D), `milestones_panel.gd` | ART-D3 | 20 marcos |
| W4 | **D-W4-EPI** · +8 Epitáfios | godot-dev | GDD §7 (D) | `data/epitaphs/*` (D), `epitaph_deck.gd`, `epitaph_overlay.gd` | ART-D5 | 24 cartas |
| W4 | **D-W4-AJUDANTES** · Cão Ossinho e Morcegos | godot-dev | GDD §9 | `helpers.gd`, `helper_views.gd` | ART-D5; `helper_dog`*, `helper_bats`* | 4 ajudantes |
| W5 | **D-W5-POLISH** ⚙ · gamepad completo, daltônico, desempenho, balanceamento final, revisão de texto, créditos | godot-dev + orquestrador | GDD §14.3, §16, §19.4 | `project.godot`, `run.gd`, `options_menu.gd`, `data/**` (ajuste), `tests/*` | — | critério do marco |

**Arte e som do D:** ART-D1 estágios 4 e 5 completos (tiles/`_lit`/rachaduras/regen/covas/lápides col. 5–6/bloco/fundo/props, `bau_baroes`, `nevoa_tile`) · ART-D2 `boss_mausoleu` + herdeiro + `boss_cova_ceifa` + ícones + chaves 4–5 · ART-D3 3 construções + 8 ícones de item + 5 ícones de marco · ART-D4 cena final (`end_bg` ×3 céus, `end_ceifa`, `end_coveiro`) + `title_ceifa_ferias` · ART-D5 8 cartas + `cao_ossinho` + `morcegos` · ART-D6 16 ícones de nó · SND-D: `heir_spawn`, `ceifa_layer`, `mist_fade`, `amb_mist`, `helper_dog`, `helper_bats`, `credits_roll`, mixagem final.

---

## 7. Briefs de arte (formato DA §12)

**Marco A**
> **Asset:** coluna Ossada (`tiles_a1` col. 4, `_lit`, `cracks_a1` linha 4, `regen_a1` reaproveitado) · **Canvas:** 32×24 · **Pivô:** (16, 16) · **Área:** 1 (e depois todas) · **Rampas:** Terra 13–17 + Osso 21–22 (ossinhos ≤ 15% do losango) · **Luz:** NO · **Contorno:** sem (tile) · **Frames/tags:** estático; 3 variantes · **Referência de tom:** terra escura cheia de ossinhos de desenho, nunca crânio humano realista · **Critério de pronto:** §11.5 + valor do centro entre o Barro (51) e o Buraco (30) para a profundidade continuar legível.

> **Asset:** `lapide` col. 0–2 (foto oval · cruz de pedra · musgo) · **Canvas:** 16×24 · **Pivô:** (8, 23) · **Área:** 1 · **Rampas:** Noite 05–08, Grama 10–11 (musgo), Osso 22 (foto) · **Luz:** NO · **Contorno:** seletivo · **Frames/tags:** estático · **Referência:** cada tipo reconhecível só pela silhueta (cruz alta, lápide arredondada com foto, lápide torta com musgo) · **Critério:** §11.5 + teste em cinza com as 3 lado a lado.

> **Asset:** `vela_campo` · **Canvas:** 32×24 · **Pivô:** (16, 16) · **Rampas:** Osso 21–23, Lanterna 25–26 · **Contorno:** seletivo · **Frames/tags:** `idle` 3f 8 fps (chama) · **Referência:** pote de vela de sete dias com 2 velinhas, halo em xadrez separado (`vela_campo_halo`) · **Critério:** §11.5; ocupa o tile sem esconder a lápide vizinha.

> **Asset:** `moeda_ouro` · **Canvas:** 8×8 · **Pivô:** centro · **Rampas:** Lanterna 24–26, 23 · **Contorno:** 01 · **Frames/tags:** `spin` 4f 10 fps, `pop` 3f · **Critério:** §11.5; mais quente e maior que o ícone de Cobre do HUD.

> **Asset:** `frame_master_<ramo>` ×6 + `frame_master_shadow` · **Canvas:** 40×40 · **Rampas:** a do ramo (DA §10.3) + Caixão 18–20 nas raízes · **Contorno:** 01 completo · **Frames/tags:** estático; sombra 02 · **Critério:** legível a 1× ao lado dos medalhões 32×32; a sombra mostra o desenho sem cor.

> **Asset:** `hud_stomp` · **Canvas:** 20×20 · **Rampas:** Terra 14–17, Noite 05–07 · **Contorno:** 01 · **Frames/tags:** `ready`, `cooldown` (05/06) · **Referência:** bota de coveiro pisando um torrão com 3 riscos de impacto · **Critério:** §11.5.

> **Asset:** `chapter_card` · **Canvas:** 48×48 · **9-slice:** margens 8/8/8/8 · **Rampas:** Pergaminho 21–23, fita 31–32, contorno 01 e rebites 17 · **Frames/tags:** estático · **Referência:** cartão do capítulo preso por fita; centro liso para conteúdo dinâmico · **Critério:** UI/UX §19.1; mantém leitura a 1× e permite títulos localizados sem texto rasterizado.

> **Asset:** `tree_soil_wide` / `tree_sky_wide` / `tree_grass_wide` · **Canvas:** 1936×848 / 1936×176 / 1936×16 · **Rampas:** as do `tree_soil` atual · **Referência:** estender o corte de solo existente para o mundo largo, com 3 "veios" verticais mais escuros separando as faixas dos ramos (sem linhas duras) · **Critério:** emendas invisíveis; dá para montar por blocos de 64 px.

**Marco B**
> **Asset:** `boss_damiao` · **Canvas:** 24×32 · **Pivô:** (12, 31) · **Área:** 2 · **Rampas:** Alma 30/23 (xadrez nas bordas), Caixão 18 (chapéu), Ecto 28 (pá) · **Contorno:** seletivo · **Frames/tags:** `walk` 4f 8 fps (NE e SE; o código espelha), `fill` 4f, `hit` 1f, `defeat` 6f (tira o chapéu), `trail` 16×8 3f · **Referência:** o Seu Damião da ficha §8.2, rabugento, bigode enorme · **Critério:** §11.5; legível sobre lama 14/27.

> **Asset:** `bld_<id>` e `bld_<id>_ruina` (Portão, Casa, Capelinha, Barraca) · **Canvas:** 48–96 × 48–96 · **Pivô:** base central · **Rampas:** Noite 05–08 (muro caiado), Caixão 18–20, Lanterna 25 (1 luz quente na restaurada) · **Contorno:** seletivo · **Frames/tags:** estático (+ fumaça da Casa 3f) · **Referência:** ruína = tábuas caídas, mato 09/10, sem luz; restaurada = mesma silhueta, inteira e com luz · **Critério:** as duas versões ocupam o mesmo canvas e o mesmo pivô.

> **Asset:** `ui_card_comum` / `ui_card_raro` / `ui_card_lendario` + `ui_card_back` · **Canvas:** 64×88 · **Rampas:** Pedra 06–08 / Ecto 27–29 / Lanterna 24–26 · **Contorno:** 01 completo · **Frames/tags:** raro e lendário com 2f de brilho · **Critério:** DA §10.4 (área de título, ilustração 32×32, pergaminho da descrição, tags 8×8).

> **Asset:** `tita` · **Canvas:** 16×16 · **Pivô:** base · **Rampas:** Terra 14–16, focinho 32, óculos 07/26 · **Frames/tags:** `idle` 2f, `act` 4f (emerge, golpe, some) · **Critério:** §11.5; lê sobre grama e terra.

**Marco C**
> **Asset:** `tiles_a3` + `_lit` + `_dark` · **Canvas:** 32×24 · **Pivô:** (16, 16) · **Área:** 3 · **Rampas:** Noite 02–07 (pedra), Terra 13–16, Caixão 18–19 (raízes) · **Contorno:** sem · **Frames:** estático, mesmo layout dos estágios 1–2 · **Referência:** chão de catacumba com juntas de pedra; `_dark` = 1 degrau abaixo de tudo · **Critério:** §11.5 + as 4 profundidades legíveis no `_dark`.

> **Asset:** `boss_raiz_mae` (núcleo 64×64 + bulbo 32×32) · **Pivô:** (32, 48) / (16, 24) · **Rampas:** Caixão 18–20, Terra 14–15, Perigo 31–32 (coração, ≤ 8%), Lanterna 26 (olhos) · **Frames/tags:** núcleo `idle` 4f, `shield` 2f, `hit` 1f, `defeat` 8f; bulbo `idle` 2f, `hit` 1f, `pop` 4f · **Critério:** §11.5; o estado imune (`shield`) é óbvio sem a barra.

**Marco D**
> **Asset:** `boss_mausoleu` + `heir` · **Canvas:** 128×96 / 16×16 · **Pivô:** (64, 80) / base · **Rampas:** Noite 06–08, Lanterna 25–26, vitral Ecto 28 / Alma 30 · **Frames/tags:** `idle` 4f, `phase1..3`, `spawn` 4f, `hit` 1f, `defeat` 8f; herdeiro `idle` 4f, `pop` 3f · **Critério:** §11.5.

> **Asset:** `boss_cova_ceifa` · **Canvas:** 96×96 · **Pivô:** (48, 80) · **Rampas:** as 6 camadas (grama, terra, barro, pedra, mármore, névoa) + Pedra 07–08 (lápide) · **Frames/tags:** `layer0..5`, `regen` 3f, `hit` 1f, `open` 8f · **Referência:** a cova mais bem-feita do jogo, com a lápide de Dona Ceifa (foice, óculos e "Volto já") · **Critério:** §11.5; cada camada lê pela cor do topo.

> **Asset:** `end_bg` (3 céus), `end_ceifa`, `end_coveiro`, `title_ceifa_ferias` · **Canvas:** 640×360 / 48×48 / 32×32 / 24×32 · **Rampas:** Noite → Lanterna 26/23 no amanhecer (troca por passos, sem gradiente) · **Frames/tags:** `end_ceifa` `glasses` 4f, `lie` 6f; `end_coveiro` `take` 6f · **Critério:** §11.5; a cena se lê sem texto.

---

## 8. Áudio: lista completa de ids do v1.0

✔ = já no `AUDIO_MANIFEST.md` (levas 1–3). **Falta** = produzir (sound-designer), com o marco em que precisa estar pronto.

**Música**
| id | Uso | Status | Marco |
|---|---|---|---|
| `mus_title` | Tela-título (tema principal) | ✔ | A |
| `mus_tree` | Árvore/hub | ✔ | A |
| `mus_area1` … `mus_area5` | Turno em cada estágio | ✔ | A/B/C/D |
| `mus_boss` | Noite do Chefe (todos) | ✔ | A |
| `mus_shop` | Loja do Mascate | ✔ | B |
| `mus_ending` | Cena final | ✔ | D |
| `jingle_summary` · `jingle_boss_win` | Resumo · vitória sobre chefe | ✔ | A |
| `jingle_chapter_end` | Fim do Capítulo (5–8 s, cita `mus_title`) | ✔ | A |
| `credits_roll` | Créditos (arranjo calmo de `mus_title`, loop) | **Falta** | D |
| `stinger_grave` · `stinger_level` · `stinger_boss_appear` · `stinger_stage_unlock` | Cova · nível · chefe surge · estágio liberado | ✔ | A |

**Ambiente**
| id | Uso | Status | Marco |
|---|---|---|---|
| `amb_night` · `amb_souls_choir` | Noite (todos) · título | ✔ | A |
| `amb_field` | Vento no campo aberto (estágio 2, por cima de `amb_night`) | **Falta** | B |
| `amb_catacomb` | Gotejar e eco de pedra (estágio 3, substitui grilos) | **Falta** | C |
| `amb_mist` | Coral etéreo baixo e sinos de vento (estágio 5) | **Falta** | D |

**SFX**
| id | Uso | Status | Marco |
|---|---|---|---|
| `dig_grass/dirt/clay/coffin/rock` · `layer_break` | Golpes e quebra | ✔ | A |
| `dig_bone` · `dig_mud` · `dig_stone` · `dig_marble` · `dig_mist` | Ossada · lama · pedra · mármore · névoa | ✔ | A · B · C · D · D |
| `pickup_copper/bone/soul` · `wisp_collect` · `oil_tick` · `oil_out` · `grave_open` | Turno base | ✔ | A |
| `stomp` · `flare` | Ativos | ✔ | A · B |
| `stomp_ready` · `flare_ready` | Ativo recarregado (tique baixo, nunca cansativo) | A: ✔; B: **Falta** | A · B |
| `second_wind` | Segundo Fôlego (chama reacendendo) | ✔ | A |
| `constellation` | Constelação da LX (3 estrelas tilintando + o tempo "para") | ✔ | A |
| `coin_gold` · `soul_wander` · `tombstone_effect` | Moeda de ouro · alminha · lápide com efeito | ✔ | A |
| `coin_rain` | Chuva de Moedas (FX) | **Falta** | B |
| `chest_open` · `bone_rain` | Baú · Ossário cheio | ✔ | B |
| `ghost_appear` · `ghost_fill` · `ghost_pop` | Fantasma surge · tapa buraco · derrubado | **Falta** | B |
| `cross_break` | Cruz de madeira quebra | **Falta** | B |
| `root_break` | Raiz (estágio 3) quebra | **Falta** | C |
| `combo` | Vala Comum: 2 covas em ≤ 3 s | **Falta** | C |
| `mist_fade` | Tiles entrando/saindo da névoa | **Falta** | D |
| `boss_hit` · `boss_sink` · `boss_emerge` · `boss_defeat` | Chefe | ✔ | A |
| `boss_flee` | Chefe foge (óleo acabou) | ✔ | A |
| `boss_phase` | Fase/bulbo/camada do chefe | **Falta** | C |
| `heir_spawn` | Herdeiros do Mausoléu saindo | **Falta** | D |
| `ceifa_layer` | Camada da Cova da Dona Ceifa quebrada / regenerando | **Falta** | D |
| `key_get` | Chave da Cripta pousa no Resumo e entra no seletor | ✔ | A |
| `unrest_warning` | "A terra treme" | ✔ | A |
| `card_flip` · `card_pick` · `card_legendary` | Epitáfios | ✔ | B |
| `card_reroll` | Embaralhar | **Falta** | B |
| `shop_bell` · `shop_buy` · `shop_deny` | Loja | ✔ | B |
| `shop_equip` | Equipar/trocar item | **Falta** | B |
| `build_complete` | Construção restaurada | ✔ | B |
| `seal` · `respec` · `milestone` | Raiz selada/mestra · Replantar · marco | ✔ | A · B · C |
| `ui_toast` | Toast de marco entrando (bem leve; o `milestone` toca no centro) | **Falta** | C |
| `stage_select` | Trocar estágio no seletor | ✔ | A |
| `helper_mole` · `helper_cat` | Tita · Gato | ✔ | B · C |
| `helper_dog` · `helper_bats` | Cão Ossinho · Morcegos | **Falta** | D |
| `dialog_blip` · `dialog_blip_ossada/ceifa/tiao/mascate` | Vozes | ✔ | A |
| `dialog_blip_damiao` | Voz do Seu Damião (grave, rabugenta, com eco fantasma) | **Falta** | B |
| UI (`ui_*`, `node_*`, `root_grow`, `level_up`, `screen_transition`), título (`logo_*`, `ui_wisp_slide`, `ui_bury`) | Já em uso | ✔ | A |

**Faltam 29 ids** (2 músicas, 3 ambientes, 24 SFX): A 7 · B 10 · C 5 · D 7.

## 9. Testes por marco
| Teste | Cobre | Marco |
|---|---|---|
| `tests/test_economy_v2.gd` | Área por passos, carry, Cobre por ponto, óleo (decay, tetos), Campo Limpo, ativos | A (amplia em B–D) |
| `tests/sim_campaign.gd` | Campanha simulada com o `RunState` real; imprime os marcos da GDD §14.2 e falha se o chefe do estágio sair da faixa ±25% | A (estágio 1) → D (5 estágios) |
| `tests/test_tree_v2.gd` | Grade sem colisão (100 `grid`), pré-requisitos com nível, selagem, ×3 das mestras, Replantar, Duas Raízes | A → D |
| `tests/test_boss_hop.gd` · `tests/test_boss_outcomes.tscn` · `test_boss.gd` (B–D) | HOP; fuga, vitória, prêmios, persistência e revanche em A; outros comportamentos em B–D | A → D |
| `tests/test_board.gd` | Lápides por peso, vela, moeda, alminha, fantasma, cruz, poça, ossário, baú, raiz, névoa | A → D |
| `tests/test_dialogue.gd` · `test_epitaphs.gd` · `test_shop.gd` · `test_hub.gd` · `test_helpers.gd` · `test_milestones.gd` | Sistemas de cada marco | A · B · B · B · B · C |
| `tests/test_save_migration.gd` · `test_save_atomicity.gd` · `test_save_compat.tscn` | v1 → v2, gravação recuperável; fixture M0 aplicada ao jogo e round-trip do save compatível | A → D |
| `tests/test_core.gd` · `test_ui_logic.gd` · `test_title.gd` | Já existentes; atualizar onde o comportamento mudou | A |
| `tests/test_chapter_end_runtime.tscn` · `test_chapter_end_flow.tscn` | Cartão 9-slice, Créditos, retorno ao Pátio e início de nova escavação | A |
| `tests/test_hall_skill_panel_runtime.tscn` | Detalhes das skills ocultos no Pátio e restaurados nas Raízes | A |
