# Revisão do jogo e roadmap de melhorias

> ⚠️ **Superado pelo [GDD 2.0](../core/01_GDD.md) e pelo [06_PLANO_V1.md](../planning/06_PLANO_V1.md) onde houver conflito** (27/10/2026). Mudanças principais: Raízes-mestras todas compráveis (Almas, ×3 cada), só 3 encruzilhadas, campo começa em 5×5, Cobre por ponto cresce com a profundidade, hub na superfície da Árvore, 5 estágios no v1.0 e marcos jogáveis A–D. Este documento fica como registro da análise.
> Versão 1.0 · 27/10/2026 · Análise de design (não altera o GDD por si só: o que for aprovado aqui entra no [01_GDD.md](../core/01_GDD.md), [02_DIRECAO_DE_ARTE.md](../design/02_DIRECAO_DE_ARTE.md) e [03_UI_UX.md](../design/03_UI_UX.md) pelo designer-chefe).
> Base: código e dados do commit `d50b3e1` (branch `claude/confident-mayer-0au1lp`), mais os dois manifestos. A tela-título está **em implementação** (UI/UX §9 e §9.6) e foi tratada como tal. Números de economia vêm de uma simulação em Python que reproduz `scenes/run/model/run_state.gd` e `field_model.gd` (método no Apêndice A); não havia Godot executável no container.

---

## Sumário executivo

1. **O M0 está pronto e passou do ponto**: campo, pulso, camadas, óleo, covas, rochas, fogos-fátuos, Campo Limpo, Resumo, Árvore aconchegante, save e opções existem, com arte final de boa parte da Área 1. O M1 está em ~30–35%: faltam Epitáfios, chefe, ajudantes, hub, ~30 nós, localização e, principalmente, **duração**.
2. **A árvore maxa em ~8 minutos (10 turnos)** com jogo atento, e em 11–13 min jogando relaxado. A árvore inteira custa 15.252 Cobre + 2.023 Ossos, o que dá **um turno do fim do jogo**. A causa é estrutural (área barata e multiplicativa, dano que "estoura" além do HP da camada, Ossos que inflacionam, nada de escolha), e não dá para resolver só subindo custo.
3. Proposta: **demo de 60 min** com o campo e a pá começando pequenos (campo 6×6, área 1×1), a área crescendo em Ossos, uma árvore de ~60 nós em 7 ramos com nós ativos, regras e desbloqueios de tabuleiro, **encruzilhadas "escolha 1 de 2"** e **uma única Raiz-mestra por partida**. Simulada, a curva entrega um nó-ponta entre 40 e 60 min, conforme a build, e deixa ~50% da árvore por comprar. É isso que dá o fator replay.
4. O tabuleiro ganha **8 elementos de cemitério com efeito** (velas, cruzes, ossário, túmulo de criança com cata-vento, coroa de flores, raízes, baú, alminhas errantes). Lojas: só **uma** na demo (o Mascate: pás e amuletos).
5. Fluxo de telas: **sem hub/cidade na demo**. A Árvore é o "lar". O hub entra no M2 como camada de cima da Árvore (a superfície do ipê), não como cena separada.

---

## 1. Referências do nicho

### 1.1 O que é o nicho "Nodebuster-like"
Incremental **ativo e curto** (1–7 h): o jogador move uma área de efeito com o cursor, o dano sai sozinho em pulsos, a run acaba por um recurso que se esgota (vida, tempo, óleo) e o dinheiro da run compra nós numa árvore grande. Depois do sucesso do Nodebuster (98% positivas em ~13,5 mil análises, segundo o nodal.gg) surgiu uma leva de clones. O IncrementalDB e o itch.io já usam a tag "Nodebuster-like", e um artigo do Gamedev.net fala em "node busters inundando o mercado". **Consequência para nós:** o loop básico não diferencia mais nada. O que diferencia é o tema bem executado, a sensação de cavar e uma árvore com escolhas.

### 1.2 Os jogos e o que vale copiar

| Jogo | O que faz | O que vale copiar / adaptar | Fonte |
|---|---|---|---|
| **Nodebuster** (Goblobin, 2024, Godot) | Retícula com área quadrada em pulsos; vida drenando é o timer; *bits* comuns e *nodes* raros (inimigos azuis) compram uma árvore extensa; chefe roxo encerra a fase e dá um *core*; prestígio aumenta os stats dos inimigos; aba de **marcos** (milestones) dá recompensas por contagem de inimigos | (a) **Moeda rara vinda de alvo raro** = nossas Almas das covas. (b) **Marcos** por contagem ("100 covas abertas" → bônus), baratos de fazer e ótimos para ritmo. (c) Chefe como portão de fase. Evitar: os jogadores reclamam de 20–25 min de repetição "no automático" no fim, de chefes que quase não dão pontos e de uma árvore "facsímile de ARPG, um pouco chata" | [Mancunion](https://mancunion.com/2025/05/08/nodebuster-review-a-short-and-sweet-incremental-game/), [Vaporlens](https://vaporlens.app/app/3107330/nodebuster.md), [nodal.gg](https://nodal.gg/game/nodebuster-3107330), [Backloggd](https://backloggd.com/u/specialfriedjazz/activity/), [Steam](https://steamcommunity.com/app/3107330/discussions/0/6929437211297706726) |
| **SuperReap** (ZoomGames, Unity; demo em 28/08/2026, lançamento em 10–11/11/2026) | Foice passando por plantação na tela cheia; vende a colheita por moedas; **cartas de talento 3→1** (bruxa); árvore que cresce; **restaurar a fazenda** (galinhas, animais amigos, produção offline); artefatos colecionáveis; nível máximo 25 na demo, listado como "Desafio da demo" | (a) **Desafios da demo** listados na loja (ex.: "nível máximo", "100% do campo"): metas claras de fim de demo. (b) Meta de restauração visual (já previsto no hub do GDD §11). (c) Cartas por run = Epitáfios. Evitar o erro registrado: um jogador "zerou a demo em menos de 20 min" porque o rendimento era alto e o upgrade *Ever Sprouting* deixava o campo sempre cheio, e "os upgrades pareciam sem sentido". É exatamente o nosso problema atual | [Steam](https://store.steampowered.com/app/4714820/SuperReap/), [Demo](https://store.steampowered.com/app/4946910/SuperReap_Demo/), [Comunidade](https://steamcommunity.com/app/4714820), [itch.io](https://zoomgamesstudio.itch.io/super-reap), [SteamDB](https://steamdb.info/app/4714820/charts/), [IncrementalDB](https://www.incrementaldb.com/game/superreap), pesquisa interna [00_PESQUISA_SUPERREAP.md](../research/00_PESQUISA_SUPERREAP.md) |
| **Harventure** (IcyQuill; demo no Steam em nov/2025) | Colheita incremental "inspirada em To the Core e Nodebuster"; **demo de 60–90 min**; árvore com 45+ upgrades na demo (100+ no jogo final); habilidades na árvore (raios, ondas de choque, explosões) e automação; 4 ilhas com recursos próprios; objetivo de "limpar a corrupção" de cada uma | É o **benchmark mais próximo do nosso alvo**: 45 nós dão 60–90 min. **Nós ativos na árvore** (onda de choque etc.) são o que dá "uau". Um jogador pediu "área de colheita girável", que nós já temos (Enxadão). O auto-clique foi desligado por padrão depois de reclamações: o ativo precisa ser opcional | [itch.io](https://icyquill.itch.io/harventure), [devlog](https://icyquill.itch.io/harventure/devlog/1067208/-game-update-improved-interactions-resource-auto-collect-), [stmstat](https://stmstat.com/fr/app/4140980) |
| **To The Core** (SomethingExtra, 2023; 5.086 análises "Muito positivas") | Perfuração de planetas; upgrades de durabilidade, combustível e dano da broca; **maestria por material** (minerar muito de um material dá bônus nele) | **Maestria por camada**: "quebrou 1.000 Barros → Barro rende +10%". Dá valor permanente ao que o jogador já faz e um motivo para cavar fundo. É tema-irmão do nosso (cavar) | [MobyGames](https://www.mobygames.com/game/207150/to-the-core/) |
| **Legion Breaker** (BaffledEngineer; lançado em 13/10/2026) | Mira manual + feitiços automáticos contra hordas de mortos-vivos; árvore que libera feitiços e "muda como a magia funciona"; 12 campos com chefe cada; **demo de 30–60 min com 3 chefes** | Demo com **vários chefes pequenos** dá ritmo de marcos. A crítica ("satisfatório, mas falta variedade") reforça que nós de **regra** valem mais que nós de número | [KeenGamer](https://www.keengamer.com/articles/reviews/pc-reviews/legion-breaker-review-a-satisfying-spell-slinger-that-runs-out-of-variety-pc/), [games.gg](https://games.gg/news/legion-breaker-first-impressions/), [itch.io](https://baffledengineer.itch.io/legion-breaker) |
| **Xenosensory** (caiys, 2025; ~97% de 125 análises) | Cursor que "pega" Xenos ao passar por cima; árvore meta; **Actions** (habilidades nos botões) e **Gadgets** (bônus de build, com limite de equipados); setores com inimigos próprios; minijogo idle; **modo que randomiza a árvore** | **Gadgets com limite de slots** = nossos amuletos da Loja do Mascate (§5.4): escolha de build fora da árvore. O **modo "árvore embaralhada"** é fator replay quase de graça para o pós-demo | [Steam](https://store.steampowered.com/app/4037830/Xenosensory/), [nodal.gg](https://nodal.gg/game/xenosensory-4037830) |
| **Fleshborn** (Castitatis; demo no Steam em 2026; 4,8/5 no itch) | Lança-chamas limpando salas; andares de 5 salas; "árvore grande que libera habilidades poderosas" | Lição dos comentários: **"maxado" e "comprável" eram difíceis de distinguir**; uma moeda (orbes verdes) **ficou inútil antes do fim da demo**. Isso acontece com as nossas Almas hoje (§2) | [itch.io](https://castitatis.itch.io/fleshborn-alpha) |
| **Arcannon**, **Gridlocked**, **Coreward**, **Shapebuster**, **Deep Sea Fish** | Variações (canhão, grade, escudos girando, pesca com retícula) | Prova de saturação: um resenhista chama o de pesca de "genérico". Tema sozinho não basta; precisa mudar o **verbo** (no nosso caso, profundidade + covas) | [IncrementalDB/Arcannon](https://www.incrementaldb.com/game/arcannon), [itch tag nodebuster](https://itch.io/games/free/tag-nodebuster), [Backloggd](https://backloggd.com/u/Hexxproof/reviews/) |

> Observação de pesquisa: o fetch direto das páginas (Steam, IncrementalDB, Vaporlens) estava bloqueado neste ambiente; os dados acima vêm de buscas na web com as fontes indicadas e da pesquisa interna já feita em 26/10/2026. As datas do SuperReap seguem conflitantes entre fontes.

### 1.3 O que adotar (resumo opinativo)
1. **Duração de demo de referência: 45–90 min** (Harventure 60–90, Legion Breaker 30–60, SuperReap foi criticado com 20). Nosso alvo de 60 min está certo.
2. **~45–60 nós na demo** e **nós ativos e de regra** misturados aos números (Harventure, Legion Breaker).
3. **Moeda rara presa a alvo raro e sempre útil** (Nodebuster). As Almas precisam de uso desde a primeira cova.
4. **Escolha de build fora da árvore com limite** (Xenosensory: gadgets) e **marcos/desafios** com fim claro (SuperReap, Nodebuster).
5. **Maestria por camada** (To The Core), para Cobre e Ossos não virarem números mortos.
6. **Não deixar o campo "sempre cheio"** nem a run virar espera (SuperReap, Nodebuster): o teto de 300 s fica, e a curva tem que evitar o "fim fácil".

---

## 2. GDD × implementação

Legenda: ✅ implementado · 🟡 parcial · ❌ não implementado · ⚠️ divergente (existe, mas contradiz o GDD ou não tem função).
Evidências no formato `arquivo:linha` (commit `d50b3e1`). Há edições locais de outros agentes em andamento (título, espaçamento da Árvore); elas não mudam as conclusões.

| GDD | Sistema | Status | Evidência | Observação |
|---|---|---|---|---|
| §18.1 | Configuração do projeto (640×360, integer, Nearest, snap) | ✅ | `project.godot` [display]/[rendering] | Conforme |
| §18.2 | Autoloads Events/Economy/Stats/SaveManager/Audio/Game | ✅ | `project.godot` [autoload]; `autoload/*.gd` | Conforme; `StatSheet` puro em `autoload/stat_sheet.gd:1` |
| §18.2 | Dados por Resource (.tres) | ✅ | `data/types/*.gd`, `data/balance.tres` | `BalanceData` concentra os números (`data/types/balance_data.gd:5–120`) |
| §18.2 | Campo como `TileMapLayer` | ⚠️ | `scenes/run/field_view.gd`, `tile_atlas.gd` | Desenho próprio por atlas, não TileMapLayer. Divergência aceitável (funciona e foi testada); atualizar o GDD |
| §18.2 | Save JSON com versão e migração; autosave | ✅ | `autoload/save_io.gd:6,48`; `autoload/game.gd:324,346` | Autosave na compra e no fim do turno; escrita atômica |
| §4.1 | Loop do Turno | 🟡 | `scenes/run/run.gd:94–107`, `run_state.gd:148` | Sem Epitáfios e sem chefe; o resto do loop está fechado |
| §4.2 | Campo N×N, 12→18 | ✅ | `balance_data.gd:51,66`; `data/skill_nodes/c03.tres` | Começa em 12×12 |
| §4.3 | Camadas da Área 1 (Grama/Terra/Barro) | ✅ | `data/areas/layers/layer_*.tres` | HP 2/4/8, Cobre 1/2/4 |
| §4.3 | Cobre por ponto de dano (v1.1); excedente não passa | ✅ | `field_model.gd:584,600`; `run_state.gd:215` | Correto, mas é a raiz de "dano inútil" depois de 8 (§3.1) |
| §4.4 | Pulso, área quadrada, crítico por tile | ✅ | `run_state.gd:190–241`; `data/types/tool_data.gd:16` | Formatos CROSS/LINE/DIAMOND já existem no código, sem ferramenta que os use |
| §4.4 | Pisão (habilidade ativa) | ❌ | Ação `stomp` em `project.godot` sem nenhum uso em `.gd` | O clique não faz nada hoje |
| §4.5 | Óleo, dreno de rocha, luz que encolhe, bônus de óleo, amanhecer | ✅ | `run_state.gd:117–127,228,458`; `balance_data.gd:72–75` | — |
| §4.5 | Fogos-fátuos (+2 s) | ✅ | `run_state.gd:417–449`; `scenes/run/grave_view.gd:17` | Ver o risco de "noite infinita" em §3.3 |
| §4.5 | "Abandonar o turno pela pausa perde os recursos" | ❌ | `scenes/ui/options_menu.gd` | A pausa só abre Opções; não há "abandonar" nem "voltar ao título" (previsto em UI/UX §9.4) |
| §4.6 | Covas (lápide bloqueia, caixão 2× HP, recompensas, reaparecimento) | ✅ | `run_state.gd:291–397`; `field_model.gd:540`; `balance_data.gd:80–89` | Cova Dupla/Mausoléu ❌ |
| §4.7 | Regeneração só de Buraco; Campo Limpo | ✅ | `field_model.gd:619`; `run_state.gd:271` | — |
| §4.8 | Rocha | ✅ | `run_state.gd:402`; `layer_rock.tres` | HP 30× topo = 60 |
| §4.8 | Raiz, Fantasma Travesso, Baú Enterrado | ❌ | — | Nenhum evento além de fogo-fátuo |
| §4.9 | XP do turno e nível | ⚠️ | `run_state.gd:259–268`; `hud.gd:331` | O nível sobe, toca som e **não faz nada** (sem Epitáfios). Feedback sem consequência |
| §4.9/§7 | Epitáfios (cartas) | ❌ | `autoload/events.gd:20` ("quando N01 existir") | Nenhum `.tres`, nenhuma cena |
| §5 | Cobre, Ossos, Almas | ⚠️ | `autoload/economy.gd:5–9`; `game.gd:334–336` | **Almas são coletadas e não servem para nada**: nenhum nó custa Almas (mesma falha criticada no Fleshborn). Selos/Chave só existem como ícone |
| §6.1 | Árvore: revelação com "?", raízes, compra repetida ao segurar, antes→depois | ✅ | `skill_tree_model.gd:336–355`; `skill_tree_screen.gd:312,484` | Arte e juice muito acima do previsto para M0 |
| §6.1 | Zoom (3 níveis), filtro, busca, "Centralizar" | ❌ | `scenes/tree/tree_camera.gd` (só arrastar com inércia) | Com 11 nós não faz falta; com 60 fará |
| §6.1/§15.5 | Ficha do Coveiro (Tab) | ❌ | Ação `toggle_stats` em `project.godot` sem uso | Rótulos já prontos em `stat_sheet.gd:21` |
| §6.3 | ~70 nós estruturais | ⚠️ | `data/skill_nodes/` = **11 arquivos** (N00 + 10) | M0 pedia 10 ✔; mas os nós escolhidos são todos "+X% num stat" (sem N01, E10, C01, L04…) |
| §6.4 | Desbloqueio por área (`required_area`) | 🟡 | `skill_node_data.gd:35` | Campo existe, não é usado |
| §8 | Ferramentas | 🟡 | `data/tools/tool_shovel.tres` | Só a Pá; o código dos formatos já está pronto |
| §9 | Ajudantes | ❌ | — | M1 pede Toupeira + Gato |
| §10 | Chefe e Inquietação | ⚠️ | `run_state.gd:17–18,319–325`; `hud.gd:145` | A barra enche e persiste entre turnos, mas em 100% nada acontece |
| §11 | Hub, construções, ganho offline | ❌ | `game.gd:374` ("sem título no M0") | — |
| §12/§13 | Lua Nova, Relíquias, conquistas, final | ❌ | — | Esperado (M2/M3) |
| §14.1 | Simulação do 1º turno | ✅ | `tests/sim_first_turn.gd` | 50–60 Cobre com o modelo "humano 75%"; a minha simulação, com cursor guloso, dá 73 (Apêndice A) |
| §14.3 | Ritmo (chefe A1 em 35–45 min) e telemetria | ⚠️ | `game.gd:338–357` | Telemetria e alerta de "5 turnos sem compra" ✅; ritmo ❌: **a árvore maxa em ~8 min** (§3) |
| §15.1 | Fluxo Título → Hub → Turno → Resumo → Árvore | 🟡 | `scenes/boot.gd:6`; `game.gd:362–380`; `turn_summary.gd:70–71` | Boot → Turno (1º jogo) ou Árvore. Resumo com "Árvore" e "Mais uma noite" ✅; "Cavar ▶" na Árvore ✅ (`skill_tree_screen.gd:180`). Título em implementação; hub ❌ |
| §15.2 | HUD (recursos, nível, Inquietação, óleo, Pisão) | 🟡 | `scenes/run/hud.gd` | Tudo menos o Pisão |
| §15.4 | Resumo do Turno | ✅ | `scenes/run/turn_summary.gd:49–63` | Com nó mais barato e botão que "chama" |
| §16 | Controles: gamepad | ❌ | `run.gd:110–112` (só `mouse_cell()`) | Nenhum movimento de cursor por analógico |
| §16 | Acessibilidade | 🟡 | `autoload/game_settings.gd:14–28`; `run.gd:80` | Volumes, tremor, flashes, movimento, tamanho dos números e pausa ao perder o foco ✅; daltônico ❌, auto-pisão ❌ |
| §17 | Áudio do MVP | ✅ | `assets/AUDIO_MANIFEST.md`; `autoload/audio.gd`, `audio_bank.gd` | Música da Árvore, da Área 1, jingle, stingers, 25 SFX. Título em produção; chefe/hub ❌ |
| DA §12 M1 | Itens 1–6, 8, 13 (tileset+lit, cursor 24, ícones, lápides/rocha/vela/crisântemo, HUD, fogo-fátuo/alma, Árvore, bordas A1) | ✅ | `assets/MANIFEST.md` | Atlas com 44 células para os 44 nós do Marco A; validação automatizada de unicidade em `test_ui_logic.gd` |
| DA §12 M1 | Itens 7, 9–12 (cartas, chefe, ajudantes, personagens, hub) | ❌ | — | Personagens do título estão sendo feitos agora (`b9b1992`) |
| DA §12 M1 | Item 14 (logo) | 🟡 | `0f8cf26` | Em implementação |
| UI/UX §4–§7 | HUD em plaquetas, diorama, catálogo de juice, Árvore aconchegante | ✅ | `hud.gd`, `diorama_block.gd`, `scenes/ui/juice.gd`, `tree_ambience.gd`, `tree_fx.gd` | O ponto mais forte do projeto |
| §1 | PT-BR e EN | ❌ | Nenhum `tr()`/tradução no código | Todo texto está fixo em PT-BR no código |

**Quanto está pronto:**
- **M0 · 100%** dos itens ("campo iso, cursor, pulso, 3 camadas, óleo, resumo, 10 nós, save") e o critério numérico ("1º turno = 50–60 Cobre", pelo `sim_first_turn.gd`). Já vem com várias coisas do M1: covas, rochas, fogos-fátuos, arte final da Área 1 e áudio do MVP. "Cavar já é gostoso" ✅ pelo relato do dono; o que falha é a progressão.
- **M1 · ~30–35%**. Pronto: arte da Área 1 (~85%), covas, opções/acessibilidade (~70%), áudio do MVP. Falta: chefe, ~30 nós (11 de ~40), 12 Epitáfios, 2 ajudantes, hub, gamepad, PT/EN e o critério "40–50 min de jogo" (estamos em ~8).

---

## 3. Diagnóstico de balanceamento

### 3.1 A economia de hoje, a partir dos dados

**Árvore** (`data/skill_nodes/*.tres`; custo = `ceil(base × cresc^nível)`, `skill_node_data.gd:42`):

| Nó | Efeito/nível | Máx | Moeda | Custos por nível | Total |
|---|---|---|---|---|---|
| E01 Lâmina Afiada | +1 dano | 10 | Cobre | 10, 15, 22, 31, 45, 65, 93, 135, 196, 284 | 896 |
| E02 Braço Firme | ×0,94 intervalo | 8 | Cobre | 25 … 538 | 1.473 |
| E03 Pá Larga | +1 raio | 3 | Ossos | 15, 90, 540 | 645 |
| E04 Golpe Certeiro | +5% crítico | 6 | Cobre | 60 … 630 | 1.580 |
| E05 Crítico Brutal | +0,5 mult. | 5 | Ossos | 20 … 210 | 448 |
| L01 Pavio Longo | +3 s óleo | 10 | Cobre | 15 … 577 | 1.703 |
| C02 Terra Fofa | ×0,88 regeneração | 6 | Cobre | 60 … 630 | 1.580 |
| C03 Campo Maior | +2 de lado | 3 | Ossos | 30, 150, 750 | 930 |
| F01 Bolso Fundo | +10% Cobre | 10 | Cobre | 20 … 769 | 2.269 |
| F02 Faro de Osso | +2 p.p. Osso | 10 | Cobre | 40 … 2.066 | 5.751 |
| **Total** | 71 níveis | | | | **15.252 Cobre + 2.023 Ossos** |

**Recompensas:** Grama 2 HP/1 Cobre, Terra 4/2, Barro 8/4: **0,5 Cobre por ponto** em todas, e um tile cavado até o fundo dá **7 Cobre**. Cova: 25 Cobre, 2–5 Ossos, 1 Alma, caixão 16 HP. Rocha 60 HP, 1 Osso. Óleo 15 s + fogo-fátuo +2 s a cada 12 ± 3 s. Regeneração 25 s. Campo Limpo +20%.

**Estado com a árvore maxada:** dano 11 · intervalo 0,61 s · área **9×9 (81 tiles)** · crítico 30% ×4,5 · óleo 45 s · Cobre ×2 · Osso +20 p.p. · regeneração 11,6 s · campo 18×18.

### 3.2 Simulação: quanto tempo para maxar hoje
Modelo: jogador que mira bem (guloso por Cobre/golpe, prioriza covas, caça 90% dos fogos-fátuos, 25% dos golpes "em trânsito"), compra sempre o nó mais barato ao fim do turno e gasta ~10 s entre turnos (Resumo + Árvore + cortinas).

| Turno | Relógio | Duração | Cobre no turno | Ossos | Comprou |
|---|---|---|---|---|---|
| 1 | 0:30 | 17 s | 76 | 0 | 4 níveis |
| 2 | 1:06 | 20 s | 228 | 0 | 7 |
| 3 | 1:48 | 26 s | 470 | 7 | 9 |
| 4 | 2:30 | 31 s | 755 | 17 | 9 (raio 2) |
| 5 | 3:24 | 32 s | 2.475 | 84 | 14 |
| 6 | 4:18 | 40 s | 3.895 | 146 | 13 |
| 7 | 5:24 | 50 s | 6.585 | 233 | 10 (raio 3) |
| 8 | 6:24 | 50 s | 11.723 | 545 | 3 (todo o Cobre já gasto) |
| 9 | 7:24 | 48 s | 12.086 | 603 | 1 (raio 4) |
| 10 | **8:24** | 51 s | 13.596 | 669 | 1 (campo 18) → **árvore maxada** |

Sensibilidade (10 sementes): **8,4 min** (mira boa, 10 s entre turnos) · **10,6 min** (50% dos golpes perdidos, 20 s entre turnos) · **13,1 min** (60% perdidos, 30 s entre turnos). Em todos os casos são **10–11 turnos**. Os nós de Cobre acabam no turno 7–8; os últimos 2–3 turnos só esperam os Ossos de E03 Nv3 (540) e C03 Nv3 (750).

### 3.3 Por que isso acontece
1. **A árvore é pequena e tem fim barato.** São 71 níveis, que custam ~1,1 turno da renda final. Não há "nó caro na ponta" nem moeda escassa.
2. **A área é barata e multiplicativa.** E03 custa 15 + 90 Ossos para levar a área de 9 para 49 tiles (×5,4) até o turno 7. Como o Cobre por tile é fixo (7), a renda escala direto com a área, que é o stat mais forte do jogo e o mais barato.
3. **Tudo multiplica tudo.** Renda/s do turno 1 = 4,4; do turno 10 = 267 (**×60**). Área ×9, duração ×3, Cobre ×2, ritmo ×1,6, covas e Campo Limpo por cima.
4. **"Dano estoura".** Com dano ≥ 8 qualquer camada quebra num golpe, e o excedente não passa (`field_model.gd:600`). Dali em diante os níveis 8–10 de E01 e quase todo E04/E05 (~2.200 Cobre + 448 Ossos) **não fazem nada**: o crítico só ajuda enquanto o dano é menor que 8. São nós mortos, e o jogador sente isso como "monótono".
5. **Os Ossos inflacionam.** F02 soma +20 p.p. em todas as camadas de solo, inclusive na Grama, que tem 0% de base (`run_state.gd:247–249`). Com área 7×7 isso dá ~200–800 Ossos por turno. A moeda "rara" vira comum no turno 6.
6. **As Almas não têm uso**, e a Inquietação e o XP enchem sem consequência. Três barras de progresso viram decoração.
7. **Nenhuma escolha.** Depois de 2 compras tudo está revelado, e não há exclusividade, regra nova ou habilidade. Comprar o mais barato é sempre ótimo, então a árvore se joga sozinha.
8. **Risco latente no GDD:** com L02 + L03 no máximo (GDD §6.3), um fogo-fátuo dá 7 s a cada ~6,9 s, ou **≥ 1 s de óleo por segundo**: a noite só acaba no amanhecer. Na simulação da proposta isso apareceu (turnos de 189 s → 300 s). **Correção proposta:** cada fogo-fátuo coletado no mesmo turno vale 80% do anterior (2 s → 1,6 → 1,28…; soma máxima ≈ 5× o primeiro).

### 3.4 Curva-alvo para uma demo de ~60 min

**Princípios:**
- **Começar pequeno de verdade**: campo **6×6**, área **1×1**. O crescimento é visível e é o próprio prêmio (pedido do dono).
- **Cobre = combustível** (nós de número, ativos, loja). **Ossos = estrutura** (tamanho da área, campo, camadas, elementos do tabuleiro). **Almas = regras e personagens** (ajudantes, Epitáfios, nós de mudança de regra). Cada moeda tem um papel claro e um sumidouro até o fim.
- **Cobre por ponto = 1** em todas as camadas (Grama 2/2, Terra 4/4, Barro 8/8): número inteiro, legível ("cada golpe de 1 = 1 moeda").
- O crescimento da área e do campo fica **atrás de Ossos com crescimento forte** (×6 e ×9 por nível), e os lados 4×4/5×5 ficam **em pontas distantes** do ramo Escavação.
- **Uma Raiz-mestra por partida** (§4.3) e **encruzilhadas 1-de-2**: maxar tudo fica impossível por regra, não por grind.

**Marcos-alvo** (mediana de 4 builds simuladas, Apêndice A; a faixa mostra a diferença entre builds):

| Relógio | Turno | Duração do turno | Área da pá | Campo | Cobre/turno | Acumulado (Cobre / Ossos / Almas) | Momento de design |
|---|---|---|---|---|---|---|---|
| 0:30 | 1 | 15 s | 1×1 | 6×6 | ~15 | 15 / 0 / 0 | 1º nó (E01 a 8 Cobre) |
| 2:00 | 4 | 20 s | 1×1 | 6×6 | 60–80 | ~180 / 5 / 1 | 1ª cova, Ficha do Coveiro |
| 5:00 | 8 | 25 s | 1×1 → 2×2 | 6×6 | 100–500 | 0,4–1,2 mil / 10–35 / 2–6 | Pá Larga (2×2), Visita da Vidente (Epitáfios), ramos A/S aparecem |
| 15:00 | 17–20 | ~60 s | 2×2 → 3×3 | 8×8 | 3–7 mil | 14–33 mil / 0,3–0,8 mil / 33–56 | Pisão ou Clarão; 1ª encruzilhada; 1º elemento de tabuleiro |
| 30:00 | 26–30 | 80–100 s | 3×3 → 4×4 | 10×10 | 16–30 mil | 114–174 mil / 3,7–6,3 mil / 130–165 | **Chefe Caixão Fujão** (30–40 min); 2ª encruzilhada; camada Ossada |
| 45:00 | 33–36 | 120–140 s | 4×4 → 5×5 | 12×12 | 55–120 mil | 0,45–0,7 mi / 17–28 mil / 260–350 | Raiz-mestra do Cemitério (~40 min); as outras pontas ficam à vista |
| 60:00 | 39–44 | 130–160 s | 5×5 | 12×12 | 160–260 mil | 1,2–1,6 mi / 40–50 mil* / 400–520 | Raiz-mestra das builds Escavação/Lanterna/Fortuna (49–62 min); "Fim da demo" |

\* Os Ossos sobram no fim da simulação porque ela não modela a loja nem os elementos de tabuleiro, que são os sumidouros de Ossos da proposta (§4, §5.4). Alvo real: ~20–25 mil Ossos acumulados aos 60 min. Para isso a camada Ossada fica com 15% de chance de Osso (não 30%).

**Valores para levar ao `.tres`** (Área 1 da demo; o que não está aqui fica como hoje):

| Arquivo / campo | Hoje | Proposta |
|---|---|---|
| `balance.tres` `base_stats.field_size` | 12 | **6** (máx. da demo 12; `stat_max` 12 → 18 no jogo completo) |
| `base_stats.radius` → trocar por `area_side` | raio 1 (3×3) | **lado 1** (1×1); máx. da demo 5, 6 com a Raiz-mestra da Escavação. Exige `ToolData.cells()` aceitar lado par (2×2 e 4×4 com o cursor no canto superior esquerdo do bloco central) |
| `base_stats.regen_time` | 25 | **18** (campo pequeno precisa voltar rápido) |
| `base_stats.grave_count` | 2 | **1** (2 com C02 Nv1) |
| `base_stats.oil_max` | 15 | 15 |
| `grave_copper` / `grave_bones_*` | 25 / 2–5 | **30 / 3–6** |
| `grave_unrest` | 0,10 | **0,04** (25 covas para o chefe → ~30 min) |
| novo `wisp_decay` | — | **0,8** (cada fogo-fátuo do turno vale 80% do anterior) |
| `layer_grass` / `dirt` / `clay` (HP / Cobre / Osso) | 2/1/0 · 4/2/0,03 · 8/4/0,06 | **2/2/0 · 4/4/0,04 · 8/8/0,08** |
| novo `layer_ossada` (liberada por C08) | — | **14 HP / 14 Cobre / 0,15 Osso**, sfx `dig_bone` |
| `bone_chance` (F02) | soma em todas as camadas de solo | **soma só em Terra, Barro e Ossada** |

**Custos:** tabela completa na §4.4. Regra geral: nós de número em Cobre com crescimento **1,33–1,8** e 5–15 níveis; nós de estrutura em Ossos com crescimento **×4–×9** e 1–3 níveis; nós de regra/ativos com **nível único** e preço fixo no degrau de renda em que devem chegar (ex.: Pisão a 400 Cobre ≈ 1 turno aos 8–10 min).

---

## 4. Árvore de Habilidades: proposta completa

> Seção própria, a pedido do dono. Substitui a simplificação atual (11 nós) **e** a tabela da §6.3 do GDD como base da demo. Os ids reaproveitam os do GDD quando o efeito é o mesmo; nós novos ganham ids livres.

### 4.1 Objetivos
1. **Cada compra muda alguma coisa que se vê ou se sente**: número maior, área maior, elemento novo no campo, botão novo, regra quebrada.
2. **Não dá para maxar na demo.** Orçamento simulado aos 60 min: ~1,4 mi Cobre, ~20–25 mil Ossos, ~450 Almas. A árvore da demo custa **2,63 mi Cobre, 32,7 mil Ossos e 3.855 Almas** (≈ 1,9×, 1,4× e 8,5× o orçamento) e ainda tem **exclusividade** (1 Raiz-mestra, 1 lado de cada encruzilhada). Um jogador focado termina a demo com o seu ramo completo e ~40–50% do resto.
3. **Escolha que muda o jeito de cavar.** Cada ramo tem um verbo (bater forte, durar, colecionar, cultivar o campo, comandar bichos, falar com almas).
4. **Legível.** No início aparecem 5 medalhões; os ramos se abrem em leque; a ponta de cada ramo aparece de longe como silhueta com custo (o "objetivo distante").

### 4.2 Estrutura e ramos

```
                         (superfície: ipê — no M2, o hub mora aqui)
                                     N00 Pá Velha
               ┌──────────┬──────────┼──────────┬──────────┐
             E01        L01        F01        C01         (A e S nascem depois)
          ESCAVAÇÃO   LANTERNA   FORTUNA    CEMITÉRIO
           (Cobre      (Cobre)   (Cobre)    (Ossos)
           +Ossos)        │          │          │
              │        ── encruzilhadas 1-de-2 em cada ramo ──
              │           │          │          │
             EX          LX         FX         CX       ← Raízes-mestras (escolha 1 por partida)
                           AJUDANTES (Almas)    ALMAS/MÉDIUM (Almas)
                           entre L e C           entre E e F, a partir de N02
```

| Ramo | Cor (DA §10.3) | Moeda principal | Identidade / estilo de jogo |
|---|---|---|---|
| **N · Centro** | Escavação | Cobre / Almas | Utilidades de interface e sistemas (Ficha, Vidente, Replantar) |
| **E · Escavação** — "Coveiro Bruto" | 16/17 | Cobre (área em Ossos) | Bate forte e rápido, área grande, **Pisão** como botão principal. Mira ativa, clique no momento certo |
| **L · Lanterna** — "Noite Longa" | 25/26 | Cobre | Turnos longos, caça de fogos-fátuos, **Clarão**, jogo de risco com o óleo baixo. Cursor sempre em movimento |
| **F · Fortuna** — "Ganancioso" | 26/23 | Cobre | Baús, moedas douradas, juros por cova, **Mascate** (loja). Joga pelos bônus do Resumo e pelos alvos raros |
| **C · Cemitério** — "Zelador" | 11/12 | Ossos | Mais covas, campo maior, **elementos de tabuleiro** (velas, cruzes, ossário), camada Ossada. Joga "lendo o campo" |
| **A · Ajudantes** — "Mestre dos Bichos" | 05/06 | Almas | Toupeira e Gato cavam e marcam tiles. Joga posicionando o cursor para combinar com eles |
| **S · Almas** — "Médium" | 30/23 | Almas | Epitáfios mais fortes, alminhas errantes. Joga pela build da noite (roguelite) |
| **Lunar** | 08/26 | Selos | **Pós-demo** (prestígio, §5.4) |

### 4.3 Regras que garantem escolha e replay
1. **Raiz-mestra única.** EX, LX, FX, CX, AX e SX são nós-ponta caros. Comprar um **sela** os outros (medalhão vira pedra, tooltip "Uma raiz-mestra por coveiro. Replante para trocar."). É a decisão principal da partida.
2. **Encruzilhadas (1 de 2).** Cada ramo tem 1 nó com dois lados (E12, L07, F07, C09, A04, S06). Comprar um lado sela o outro. Na tela são dois medalhões lado a lado ligados por uma raiz em "Y".
3. **Moeda por ramo.** E/L/F gastam Cobre, C gasta Ossos, A/S gastam Almas. Focar em C não tira Cobre de E; focar em A/S compete pela moeda mais escassa (~450 Almas na demo para 3.855 de custo).
4. **Custos crescentes e pontas caras.** As pontas custam ≈ 1–2 turnos da renda que o jogador terá aos 45–60 min (150–300 mil Cobre ou 15 mil Ossos).
5. **Replantar (N03), o respec.** Liberado ao derrotar o chefe. Devolve **100%** do que foi gasto e solta Raiz-mestra e encruzilhadas. Custa 10 Almas e só pode ser usado na Árvore. Com isso a demo tem dois jeitos de replay: **nova partida** (outra build desde o começo) e **replantar depois do chefe** (testar outra ponta nos últimos 15 min).
6. **Lua Nova (pós-demo).** No jogo completo o prestígio reseta a árvore e muda a rota com o Ramo Lunar (GDD §12). Na demo aparece só como medalhão-silhueta "Em breve", para gerar wishlist.
7. **Revelação progressiva.** Ver §4.6.

### 4.4 Nós por ramo
Tipos: **P** = passivo (número) · **At** = ativo (habilidade com recarga/gatilho) · **R** = regra ("uau", muda como o jogo funciona) · **D** = desbloqueio (área, elemento do tabuleiro, loja, ajudante) · **X** = encruzilhada (1 de 2) · **M** = Raiz-mestra.
Custo do nível n (0-based) = `ceil(base × cresc^n)`; "—" = nível único.

#### N · Centro
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| N00 | Pá Velha | — | Início. Revela E01, L01, F01, C01 | — | — | — | — | — |
| N01 | Ficha do Coveiro | D | Painel de stats (Tab). Revelado no 2º turno | 1 | Cobre | 5 | — | N00 |
| N02 | Visita da Vidente | D | Libera Epitáfios ao subir de nível (3 → 1); revela o ramo S | 1 | Cobre | 150 | — | 5 nós comprados |
| N03 | Replantar | D | Respec com devolução de 100%; troca de Raiz-mestra e encruzilhadas | 1 (uso: 10 Almas) | Almas | 10 | — | Chefe Caixão Fujão |

#### E · Escavação — "Coveiro Bruto"
Identidade: o Pisão vira o "botão" da build; dano alto tem uso graças a **Cava-Funda** (o excedente passa para baixo), o que mata o problema do "dano estourado".
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| E01 | Lâmina Afiada | P | +1 dano | 15 | Cobre | 8 | 1,36 | N00 |
| E02 | Braço Firme | P | −5% intervalo do golpe (mult.) | 10 | Cobre | 25 | 1,6 | E01 |
| E03 | Pá Larga | D | +1 de lado na área (1×1 → 2×2 → 3×3) | 2 | Ossos | 10 | ×6 | E01 |
| E04 | Golpe Certeiro | P | +4% crítico | 8 | Cobre | 60 | 1,65 | E02 |
| E05 | Crítico Brutal | P | +0,5 no mult. de crítico | 5 | Ossos | 20 | 1,8 | E04 |
| E10 | Pisão | At | Clique/A: golpe ×4 na área, recarga 8 s | 1 | Cobre | 400 | — | E02 Nv3 |
| E11 | Pisão Pesado | P | −1 s de recarga do Pisão | 4 | Cobre | 900 | 1,9 | E10 |
| E12a | Pisão Sísmico | X | O Pisão também bate no anel de 1 tile em volta, com ×2 | 1 | Cobre | 3.000 | — | E11 |
| E12b | Pisão Ritmado | X | O Pisão dispara sozinho a cada 10 golpes (bom para gamepad e acessibilidade) | 1 | Cobre | 3.000 | — | E11 |
| E13 | Cava-Funda | R | O dano excedente passa para a camada de baixo (quebra a regra §4.3) | 1 | Ossos | 400 | — | E05 |
| E06 | Pá de Coveiro | D | Área 3×3 → 4×4 | 1 | Ossos | 900 | — | E03 Nv2 + E02 Nv5 |
| E08 | Lâmina Temperada | P | +3 dano | 8 | Cobre | 5.000 | 1,7 | E13 |
| E09 | Ombro de Ferro | P | −4% intervalo | 6 | Cobre | 8.000 | 1,8 | E08 |
| E07 | Pá Larguíssima | D | Área 4×4 → 5×5 | 1 | Ossos | 5.000 | — | E06 |
| **EX** | **Pá do Seu Damião** | M | +1 lado de área (até 6×6) e **golpe duplo**: cada pulso bate 2× (o 2º com 50%); críticos racham os tiles vizinhos | 1 | Cobre | 250.000 | — | E09 Nv3 + E07 |

#### L · Lanterna — "Noite Longa"
Identidade: a noite como recurso. Caçar fogos-fátuos, decidir quando gastar óleo no Clarão, jogar no limite com Breu.
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| L01 | Pavio Longo | P | +2 s de óleo | 12 | Cobre | 10 | 1,42 | N00 |
| L02 | Vidro Polido | P | Fogo-fátuo +0,5 s | 4 | Cobre | 80 | 1,8 | L01 |
| L03 | Isca de Fogo-fátuo | P | +12% de frequência de fogos-fátuos | 4 | Cobre | 120 | 1,8 | L02 |
| L04 | Óleo de Osso | P | Cova aberta dá +0,5 s de óleo | 3 | Ossos | 40 | 2,0 | L01 + C02 |
| L05 | Clarão | At | Botão direito/X: por 3 s a luz vai a raio 4 e tiles iluminados levam +50% de dano; custa 2 s de óleo; recarga 20 s | 1 | Cobre | 600 | — | L03 |
| L06 | Segundo Fôlego | R | 1× por turno, ao zerar o óleo, volta com 5 s | 1 | Almas | 15 | — | L05 |
| L07a | Lua Cheia | X | +25% de dano enquanto o óleo estiver acima de 50% | 1 | Cobre | 4.000 | — | L05 |
| L07b | Breu | X | +40% de Cobre enquanto o óleo estiver abaixo de 25% (a luz encolhe e o risco sobe) | 1 | Cobre | 4.000 | — | L05 |
| L08 | Querosene | P | +5 s de óleo | 6 | Cobre | 4.000 | 1,8 | L03 |
| L09 | Vidro Fumê | P | Tiles dentro da luz rendem +10% de Cobre | 5 | Cobre | 2.500 | 1,7 | L07 |
| **LX** | **Lua que Não se Põe** | M | +15 s de óleo e **constelação**: pegar 3 fogos-fátuos seguidos em menos de 6 s **para o tempo** por 8 s (o óleo não queima e a luz fica no máximo) | 1 | Cobre | 150.000 | — | L08 Nv4 + L09 Nv3 |

#### F · Fortuna — "Ganancioso"
Identidade: alvos raros e bônus de fim de noite. Dá valor ao Cobre "parado" (juros, herança) e abre a loja.
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| F01 | Bolso Fundo | P | +8% de Cobre | 15 | Cobre | 15 | 1,38 | N00 |
| F02 | Faro de Osso | P | +2 p.p. de chance de Osso (Terra/Barro/Ossada) | 8 | Cobre | 40 | 1,65 | F01 |
| F03 | Moeda Enterrada | D | **Baús Enterrados** (§5.2): 1% por tile cavado até o fundo, +0,5 p.p./nível | 5 | Cobre | 200 | 1,8 | F01 |
| F04 | Juros dos Mortos | P | +1% de Cobre por cova aberta no turno (acumula) | 5 | Ossos | 30 | 1,9 | F02 |
| F05 | Herança | P | +5% do Cobre do turno como bônus no Resumo | 6 | Cobre | 800 | 1,75 | F02 |
| F06 | O Mascate | D | Libera a **Loja do Mascate** (pás e amuletos, §5.4) | 1 | Cobre | 1.500 | — | F03 |
| F09 | Moeda de Ouro | D | Uma moeda dourada pula no campo a cada 20 s; passar o cursor = +5% do Cobre do turno | 3 | Cobre | 6.000 | 2,0 | F03 |
| F07a | Avareza | X | ×1,5 Cobre; Ossos −50% | 1 | Cobre | 20.000 | — | F05 |
| F07b | Dízimo | X | Cada 100 Cobre do turno vira +1 Osso no Resumo | 1 | Cobre | 20.000 | — | F05 |
| F08 | Cofre Pesado | P | ×1,25 Cobre | 4 | Cobre | 25.000 | 2,6 | F07 |
| **FX** | **Tesouro da Paróquia** | M | ×1,5 Cobre; o Campo Limpo vira **Chuva de Moedas** (+50% em vez de +20%, moedas caindo no campo para pegar) | 1 | Cobre | 300.000 | — | F08 Nv2 + F09 Nv2 |

#### C · Cemitério — "Zelador"
Identidade: o ramo que **muda o tabuleiro**. É onde os Ossos ganham importância (pedido do dono): os Ossos compram terreno, covas e elementos.
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| C01 | Campo Maior | D | +2 de lado no campo (6 → 8 → 10 → 12) | 3 | Ossos | 12 | ×9 | N00 |
| C02 | Mais Covas | P | +1 cova simultânea | 3 | Ossos | 30 | ×4 | C01 |
| C03 | Terra Fofa | P | −10% no tempo de regeneração | 6 | Cobre | 60 | 1,7 | C01 |
| C04 | Lápides Antigas | P | +25% de recompensa das covas | 6 | Ossos | 40 | 1,8 | C02 |
| C05 | Velas de Finados | D | Velas no campo (§5.2); +1 vela por nível | 3 | Ossos | 80 | 2,2 | C02 |
| C06 | Cruzes de Madeira | D | Cruzes no campo (§5.2); +1 cruz por nível | 3 | Ossos | 150 | 2,2 | C04 |
| C07 | Ossário | D | Ossário 2×2 no campo (§5.2); níveis: +25% de Ossos do ossário | 4 | Ossos | 80 | 2,2 | C04 |
| C08 | Cova Funda | D | Nova camada **Ossada** no fundo de todos os tiles (14 HP, 14 Cobre, 15% Osso) | 1 | Ossos | 600 | — | C04 Nv3 |
| C10 | Inquietação | P | +1 p.p. de Inquietação por cova (o chefe chega antes) | 5 | Almas | 5 | 1,7 | C02 |
| C09a | Covas Duplas | X | 25% das covas novas são 2×2 (×3 recompensa) | 1 | Ossos | 2.500 | — | C08 |
| C09b | Vala Comum | X | Covas nascem coladas; abrir 2 covas em ≤ 3 s = **combo** ×2 | 1 | Ossos | 2.500 | — | C08 |
| **CX** | **Mausoléu da Família** | M | A cada turno, um **Mausoléu 3×3** nasce no centro do campo: 3 camadas de mármore (HP 3× Barro), abre como cova ×8 e dá +3 Almas | 1 | Ossos | 15.000 | — | C09 + C07 Nv2 |

#### A · Ajudantes — "Mestre dos Bichos" (revela com a 1ª Alma)
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| A01 | Toupeira Tita | D | Libera a Tita (GDD §9); níveis: +1 dano dela | 10 | Almas | 3 | 1,6 | 1ª Alma + C02 |
| A02 | Gato Breu | D | Libera o Gato (tile da sorte ×5 a cada 10 s); níveis: +1 tile | 5 | Almas | 8 | 1,8 | A01 |
| A03 | Ração Especial | P | +20% de eficiência dos ajudantes | 5 | Cobre | 2.000 | 1,9 | A01 |
| A04a | Toca Ligada | X | A Tita cava em túnel: linha de 4 tiles em vez de 1 | 1 | Almas | 40 | — | A02 |
| A04b | Sete Vidas | X | O Gato marca a **cova** mais próxima: cova da sorte ×3 | 1 | Almas | 40 | — | A02 |
| **AX** | **Bicharada** | M | Cada Pisão ou Clarão acorda os ajudantes: 3 s em que eles agem 3× mais rápido; +1 Toupeira | 1 | Almas | 200 | — | A04 + A03 Nv3 |

(Cão Ossinho e Morcegos ficam para o M2.)

#### S · Almas — "Médium" (revela com N02)
| Id | Nome | Tipo | Efeito | Máx | Moeda | Base | Cresc. | Pré-req. |
|---|---|---|---|---|---|---|---|---|
| S01 | Descanso Eterno | P | +5% de todo recurso | 10 | Almas | 10 | 1,6 | N02 |
| S02 | Embaralhar | P | +1 nova rolagem de Epitáfios por turno | 3 | Almas | 20 | 2,2 | N02 |
| S03 | Bola de Cristal | R | Epitáfios mostram 4 opções | 1 | Almas | 60 | — | S02 |
| S04 | Alminhas Errantes | D | Alminhas vagam no campo (§5.2); +1 por nível | 3 | Almas | 25 | 2,0 | S01 |
| S05 | Prenúncio | R | Começa o turno com 1 Epitáfio Comum (3 → 1) | 1 | Almas | 100 | — | S03 |
| S06a | Romaria | X | Almas das covas ×2 | 1 | Almas | 150 | — | S04 |
| S06b | Coral | X | Cada Alma coletada no turno dá +1 s de óleo e +2% de dano (acumula) | 1 | Almas | 150 | — | S04 |
| **SX** | **Madame Ossada** | M | Epitáfios Lendários 3× mais frequentes; no nível 5, escolha **2** cartas | 1 | Almas | 300 | — | S05 + S06 |

**Totais da demo:** 59 nós (65 medalhões contando os dois lados das encruzilhadas) · E: 1,10 mi Cobre + 6,8 mil Ossos · L: 371 mil Cobre · F: 1,10 mi Cobre · C: 24,8 mil Ossos · A: 969 Almas + 53 mil Cobre · S: 2.765 Almas.

**Lunar (pós-demo, Selos):** Lua Minguante (×1,5 Cobre, acumula), Cofre Herdado (começa com 500 Cobre), Espantalho (2ª área fixa), Maré Alta (+1 opção de Epitáfio), Raízes Velhas (nós 10% mais baratos), **Duas Raízes** (permite 2 Raízes-mestras: a recompensa máxima do prestígio).

### 4.5 Builds de exemplo (como cada uma muda o jeito de cavar)

| Build | Rota | Como se joga | Simulação: o que tem em 5 / 15 / 30 / 45 / 60 min |
|---|---|---|---|
| **Coveiro Bruto** (E → EX) | E01–E05, Pisão → Pisão Sísmico, Cava-Funda, áreas 4×4/5×5, Pá do Damião | Cursor parado em cima das covas, Pisão no ritmo do pulso, buracos abertos em 2–3 golpes. Pede atenção ao clique | 5: E01 Nv9, E02 Nv4, área 2×2 · 15: área 3×3, Pisão, crítico cheio, campo 8 · 30: área 4×4, Lâmina Temperada Nv4, ~30 mil/turno · 45: área 5×5, campo 12 · **60: EX (57–62 min)** |
| **Zelador** (C → CX) | Campo Maior, Mais Covas, Velas, Ossário, Cova Funda, Vala Comum, Mausoléu | Lê o tabuleiro: abre covas em combo, cava perto das velas, enche o Ossário. Menos clique, mais rota | 5: área 1×1, campo 6–7 · 15: 2 covas, Velas · 30: Ossada, Vala Comum · **~40 min: CX** · 45–60: compra os ramos vizinhos com os Ossos que sobram |
| **Noite Longa** (L → LX) | Pavio, fogos-fátuos, Clarão, Breu, Querosene, Lua que Não se Põe | Cursor em movimento caçando fogos-fátuos; decide quando gastar óleo no Clarão; com Breu, joga no vermelho de propósito | 5: só óleo, área 1×1 (começo lento: compensar com Pavio Longo Nv1 a 6 Cobre) · 15: Clarão · 30: Breu, turnos de 100 s · **48–53 min: LX** |
| **Ganancioso** (F → FX) | Bolso Fundo, Baús, Mascate, Moeda de Ouro, Avareza, Cofre, Tesouro | Caça alvos raros (baús, moedas douradas) e monta amuletos na loja; o Resumo é o momento alto | 5: Bolso Nv5 · 15: Baús, Mascate · 30: Avareza ou Dízimo · 45: Cofre Nv2 · **53–62 min: FX** |

Com A e S como "tempero" de qualquer build (competem pelas ~450 Almas da demo): um Bruto com Toupeira + Toca Ligada, ou um Zelador com Romaria. A próxima partida pode inverter tudo.

### 4.6 Layout, legibilidade e o que pede de arte e código
- **No início: 5 medalhões visíveis** (N00 + E01, L01, F01, C01) e, como silhueta "?", os filhos imediatos. N01 aparece no 2º turno. Os ramos A e S **brotam** quando acontece o gatilho (1ª Alma / N02), com o "!" e o broto que já existem (`fx_tree_sprout`, `fx_tree_new_badge`).
- **As Raízes-mestras aparecem desde o início** como silhuetas grandes (40×40) no fundo de cada ramo, com o nome e o custo visíveis no hover ("Pá do Seu Damião · 250.000"). É o objetivo distante, que dá direção.
- **Geometria:** ramos em leque descendo do N00 (o subsolo já tem 720 px de altura, `MANIFEST tree_soil`); ~6–9 linhas de 64 px por ramo; encruzilhada = 2 medalhões a 48 px um do outro, ligados por uma raiz em Y. A câmera atual (arrastar com inércia) passa a precisar de **zoom 1×/0,5×** e do botão **Centralizar** (GDD §6.1). Com 65 medalhões, sem isso a árvore fica ilegível.
- **Estado "selado"** (outra ponta/encruzilhada escolhida): medalhão em pedra 06/07 com uma raiz cortada. É diferente de "oculto" e de "sem dinheiro", e resolve a queixa do Fleshborn ("maxado e comprável difíceis de distinguir").
- **Arte (pixel-artist):** ~40 ícones 16×16 novos (25 existem, 11 em uso); moldura de **Raiz-mestra** 40×40 por ramo (6) + estado selado; moldura de **encruzilhada** (raiz em Y); moldura para tipos **At** e **R** (ex.: aro com raio para ativos, aro rúnico para regras), para o jogador saber o tipo antes de ler; ícone do botão do Pisão/Clarão no HUD (20×20, recarga em pips).
- **Código (godot-dev):** `SkillNodeData` ganha `kind` (P/At/R/D/X/M), `exclusive_group` (StringName: o mesmo grupo sela os irmãos), `requires` (lista de {id, nível}, para pré-requisitos com nível), `reveal_trigger` (ex.: `first_soul`), e `effect_script`/flags para regras (`excess_carries`, `stomp_ring`…); `SkillTreeModel` ganha `is_sealed()`, `respec()`; o `StatSheet` continua para os P; os At/R viram flags lidas pelo `RunState`.

### 4.7 Balanceamento: ligação com a curva de 60 min
- **Degraus de renda por turno** (§3.4): ~15 (início) · 100–500 (5 min) · 3–7 mil (15) · 16–30 mil (30) · 55–120 mil (45) · 160–260 mil (60). Cada nó R/At/D tem preço fixo de **0,5–2 turnos** da renda do degrau em que deve chegar: Pisão 400 (~8–10 min), Clarão 600 (~10 min), Mascate 1.500 (~12 min), encruzilhadas 3–4 mil (15–20 min) e 20 mil (F, ~25 min), Cova Funda 600 Ossos (~25 min), pontas 150–300 mil (45–60 min).
- **O que se compra em cada build:** ver a última coluna da §4.5 (vem da simulação).
- **Medida de controle no playtest:** se a Raiz-mestra sair antes de 40 min na mediana, subir as pontas em 50%; se depois de 70, baixar E08/E09/L08/F08 em 20%. Se o alerta de "5 turnos sem compra" (`game.gd:350`) disparar entre 30 e 45 min, inserir 1–2 nós de reforço baratos (+X%) entre os nós caros. É a regra dos "nós de reforço" do GDD §6.2.

---

## 5. Melhorias futuras e recomendações

### 5.1 Mecânica principal (cavar, camadas, pulso, óleo)
**O que falta:** o clique (Pisão), o XP com função (Epitáfios), motivo para cavar fundo depois do Barro, e algo que torne o dano alto útil.
**O que melhorar:**
| Proposta | Detalhe | Prioridade |
|---|---|---|
| **Pisão** (E10) | Já previsto no GDD e no input map. Deixa o jogo "ativo" sem obrigar: o pulso automático continua | **Demo** |
| **Cava-Funda** (E13) | O excedente passa para a camada de baixo. Resolve o "dano inútil" e é um nó "uau" (o buraco afunda de uma vez) | **Demo** |
| **Camada Ossada** (C08) | 4ª camada da Área 1 (14 HP/14 Cobre/15% Osso), visual de terra com ossinhos (19/21/22). Dá um novo "fundo" a alcançar no meio da demo | **Demo** |
| **Maestria por camada** (To The Core) | A cada 250/1.000/5.000 camadas de um tipo quebradas, ela rende +10/+20/+30%. Aparece na Ficha do Coveiro. Mostra o Cobre e os Ossos "trabalhando" | **Demo** (barato: contador + StatSheet) |
| **Fogo-fátuo com retorno decrescente** (`wisp_decay` 0,8) | Evita a noite infinita (§3.3) | **Demo** |
| **Cobre por ponto = 1** | Números inteiros e legíveis | **Demo** |
| **Pulso com "batida"** | Contorno pulsando 1 frame antes do golpe (antecipação) e golpe no tempo da música (88 BPM ≈ 0,68 s; o intervalo mínimo de E02 cai perto disso). Opcional: o Pisão no tempo da batida dá +25% ("Pisão no compasso") | Pós-demo (testar) |
| **Eventos do turno** | 1 evento por noite a partir de 10 min, sorteado: *Lua de Sangue* (críticos ×2 por 20 s), *Chuva* (a regeneração para, buracos enchem de lama: +50% de Cobre na lama), *Procissão* (alminhas cruzam o campo em fila; tocar todas = +3 Almas) | Demo: 1 evento (Procissão); resto pós-demo |
| Variantes de ferramenta | Enxadão (linha) e Picareta (cruz): o código já existe (`tool_data.gd:16`) | Pós-demo (M2), salvo se couber como item do Mascate |

### 5.2 Tabuleiro e elementos do cemitério
**Hoje:** chão + lápide de cova (bloqueia) + caixão + rocha + fogo-fátuo. As velas, crisântemos, cerca e placa existem só como decoração **fora** da grade (`field_decor.gd:31–44`).
**Recomendação:** colocar **dentro** da grade elementos com uma regra simples cada, ligados a nós do ramo C (para crescer junto com a árvore). Regra de legibilidade: todo elemento interativo é ≥ 1 degrau mais claro que o entorno (DA §3.2) e ocupa 1 tile, com a exceção do Ossário (2×2).

| Elemento | Libera em | Efeito no jogo | Arte (DA §5) | Prioridade |
|---|---|---|---|---|
| **Lápide (3 tipos com efeito)** | Início | Hoje as 3 variantes (`lapide` colunas 0–2) são só visuais. Proposta: **foto oval** = cova normal; **cruz de pedra** = cova "abençoada" (+1 Alma); **lápide com musgo** = cova "antiga" (caixão 1,5× HP, ×2 Ossos). Mesmo sprite, regra nova | Já existem | **Demo** |
| **Vela de Finados** | C05 | Tile com vela não é cavável; tiles em raio 1 **regeneram 2× mais rápido** e rendem +25%. Cria "canteiros" para farmar | `vela` já existe (8×12) | **Demo** |
| **Cruz de madeira** | C06 | Pode ser cavada (HP 3× Barro); ao quebrar, solta **3 Ossos**; covas nascem perto de cruzes com 2× mais chance | 12×20 (DA §5) | **Demo** |
| **Ossário** (2×2) | C07 | Cada camada quebrada em volta (raio 1) enche 1%; cheio = **chuva de Ossos** (15 + nível) e esvazia | 32×32, novo | **Demo** |
| **Baú Enterrado** | F03 | Escondido sob um tile (brilho sutil); ao chegar no fundo: Cobre ×25 ou **amuleto** do Mascate | 16×16 (DA §5) | **Demo** |
| **Alminhas errantes** | S04 | Flutuam devagar pelo campo; passar o cursor = +1 Alma (e um "obrigado" em balão de 1 palavra). Uma Alma fora das covas | 8×10, reaproveita `alma_fila` do título | **Demo** |
| **Coroa de flores** | Evento | Aparece numa lápide; cavar a cova dela dá ×3 e uma pétala de ipê sobe ao HUD | 16×12 | Pós-demo |
| **Túmulo de criança com cata-vento** | Área 1 tardia | O cata-vento gira quando o cursor passa; girando, os tiles em volta dão crítico garantido | 12×16, 2–3 frames | Pós-demo |
| **Raiz** (GDD §4.8) | Área 3 | Liga 2–4 tiles com −50% de dano; quebrada = Cobre ×10 | 32×24 | Pós-demo (M2) |
| **Fantasma Travesso** | Área 2 | Tapa buracos; dá Almas | 16×16 | Pós-demo (M2) |
| **Mausoléu 3×3** | CX | Ver Raiz-mestra | 96×72 | Demo, se CX ficar |

### 5.3 Árvore de habilidades
O que falta e o que melhorar estão na §4. Resumo das prioridades:
| Proposta | Prioridade |
|---|---|
| Nova estrutura de 7 ramos, ~59 nós, encruzilhadas e Raiz-mestra única (§4.2–§4.4) | **Demo** |
| Nós de tipos At/R/D com moldura própria e estado "selado" | **Demo** |
| Zoom 2 níveis + Centralizar + Ficha do Coveiro (Tab) | **Demo** |
| Replantar (respec) após o chefe | **Demo** |
| Busca por nome e filtro por ramo (GDD §6.1) | Pós-demo (com ~120 nós) |
| Ramo Lunar e "Duas Raízes" | Pós-demo |

### 5.4 Mecânicas complementares (escolher poucas)
| Mecânica | Recomendação | Por quê | Prioridade |
|---|---|---|---|
| **Epitáfios** (cartas 3→1 por nível) | **Sim**, com 12 cartas (GDD M1) | Dá função ao XP e variedade dentro de cada noite; é o elemento roguelite que o SuperReap tem | **Demo** |
| **Loja do Mascate** (pás e amuletos) | **Sim, uma loja só**, aberta por F06, acessada por um botão na Árvore (sem cena nova: painel de pergaminho). Vende em **Ossos e Cobre**: 3 **pás** (Pá de Bico: +1 dano e área −1 lado; Pá de Jardineiro: área +1 lado e dano ×0,6; Pá Benta: ×2 em covas e ×0,8 no solo) e 6 **amuletos** com **2 slots** (ex.: Dentadura de Ouro +10% Cobre; Terço de Osso +5% crítico; Retrato Oval: +1 cova; Vela de Sete Dias: os 7 primeiros s não queimam óleo; Ferradura: baús ×2; Pé de Coelho: Epitáfio raro garantido no Nv3) | Escolha de build fora da árvore com limite (Xenosensory); sumidouro de Ossos; prepara as Relíquias do jogo completo | **Demo** |
| **Ajudantes** (Toupeira + Gato) | **Sim**, no ramo A | Já é escopo do M1; dá uso às Almas | **Demo** |
| **Chefe Caixão Fujão** | **Sim**: aos 30–40 min, com Inquietação 0,04/cova | Marco do meio da demo; dá a **Chave** e libera o Replantar e a 2ª metade | **Demo** |
| **Marcos/Desafios da demo** | **Sim**: lista de 8 ("Abrir 100 covas", "Campo Limpo 12×12", "Chefe sem Pisão", "Comprar uma Raiz-mestra", "Noite de 120 s"…) com recompensa em Almas e um selo na tela-título | Fim claro + replay (SuperReap) | **Demo** |
| Relíquias/Codex | Não na demo: os amuletos do Mascate fazem esse papel | Escopo | Pós-demo |
| Hub e construções | Não na demo (ver §5.6) | Escopo | Pós-demo (M2) |
| Prestígio (Lua Nova) | Não na demo; silhueta "Em breve" | Escopo; o Replantar cobre o replay | Pós-demo |
| Ganho offline | Não | Contraria o pilar 4 (ativo) numa demo de 1 h | Pós-demo |
| **Modo "raízes embaralhadas"** (Xenosensory) | Pós-demo, como desbloqueio do final | Replay barato | Pós-demo |

### 5.5 Progressão, duração da demo e fator replay
- **Duração:** 55–65 min até a Raiz-mestra e o "Fim da demo" (Dona Ceifa agradece e mostra as Áreas 2–5 como silhuetas no mapa da superfície). Chefe aos 30–40 min.
- **Começo pequeno:** campo 6×6 e área 1×1 (pedido do dono). O 1º turno rende ~15 Cobre e compra 1–2 nós (E01 a 8, L01 a 10). A §14.1 do GDD ("50–60 Cobre") muda para "**12–18 Cobre, 1–2 nós**".
- **Os lados 4×4 e 5×5 ficam em pontas distantes** (E06, E07; 900 e 5.000 Ossos), e 6×6 só com a Raiz-mestra da Escavação. Isso responde à ideia de "começar com 4 e deixar 5/6 em ramos distantes".
- **Papel das moedas:** Cobre = número (sempre há algo para comprar), Ossos = espaço (área, campo, elementos, loja), Almas = regras e personagens. Nenhuma moeda fica sem uso antes do fim.
- **Replay:** (1) 4 builds principais com Raiz-mestra exclusiva; (2) 6 encruzilhadas = 64 combinações; (3) Replantar após o chefe; (4) Epitáfios e amuletos variam cada noite; (5) Desafios da demo; (6) no jogo completo, Lua Nova + Duas Raízes. Meta: um jogador que goste joga a demo **2 vezes** (~2 h no total).

### 5.6 Fluxo de telas e transições
**Recomendação: sem hub/cidade na demo.** A Árvore é o "lar" e já é a tela mais bonita do jogo. O hub do GDD (§11) entra no M2 **como a superfície da Árvore** (o ipê e o cemitério em volta, com construções em ruína/restauradas), acessado subindo a câmera, e não como cena separada. Assim o fluxo continua a 1 clique e não se cria uma tela de "passagem".

**Fluxo da demo:**
```
Título ──Novo Jogo──► (Coveiro se levanta, cortina de terra) ──► TURNO 1 (sem tutorial em texto; Tião fala 1 balão)
   │ └─Continuar──► ÁRVORE
   ▼
TURNO ──óleo acaba / sol nasce──► "O ÓLEO ACABOU" (0,8 s) ──► HUD sai ──► cortina ──► RESUMO
RESUMO ──[Árvore] (em foco se dá para comprar) ──► cortina ──► ÁRVORE
       └─[Mais uma noite] ──► cortina ──► TURNO
ÁRVORE ──[Cavar ▶] (canto inferior direito, sempre visível) ──► cortina ──► TURNO
       ├─[Mascate] (após F06) ──► painel de pergaminho sobre a Árvore (sem trocar de cena)
       ├─[Tab] Ficha do Coveiro (painel lateral)
       └─[Esc] Pausa ──► Opções / Voltar ao título
TURNO ──[Esc] Pausa──► Continuar / Opções / Abandonar a noite (perde os recursos, GDD §4.5) / Voltar ao título
Chefe derrotado ──► diálogo (2–4 balões) ──► Resumo especial (Chave) ──► Árvore com N03 revelado
Raiz-mestra + "Fim da demo" ──► cena curta + lista de Desafios + "Continuar cavando" (sandbox) / Wishlist
```
- **O que acontece ao clicar em Começar** (UI/UX §9.4): Novo Jogo → o Coveiro levanta, pega pá e lanterna (anim `stand`), a cortina de terra cai e o **1º turno** começa direto. A 1ª vez tem um balão do Tião: "Mexe o mouse, a pá faz o resto". Continuar → Árvore.
- **Jogo → Árvore:** sempre pelo Resumo (é o momento de contar o butim). O botão certo "chama" (já existe, `turn_summary.gd:75–78`). Proposta extra: se o jogador tiver feito ≥ 3 turnos seguidos sem abrir a Árvore e puder comprar algo, o Resumo mostra "Há 3 raízes prontas para crescer".
- **Árvore → jogo:** "Cavar ▶" com 1 clique; atalho Espaço/Start. Proposta: na Árvore, mostrar no botão a previsão do próximo turno ("Noite 12 · 45 s de óleo").
- **Outras áreas/cenários:** a demo tem **uma área** (Paróquia), mas o campo cresce de 6×6 até 12×12 e o fundo do turno troca de "clareira pequena" para "cemitério inteiro" conforme o tamanho (o novo fundo de mata/clareira, `d50b3e1`, ajuda). No jogo completo, as áreas ficam num **mapa de lanterna** na superfície da Árvore (o portão de cada área abre com a Chave da Cripta) e a escolha de área entra no botão "Cavar ▶" (seta para trocar). Não precisa de cidade.

### 5.7 Interface, feedback e "juice"
O juice é o ponto mais forte do projeto (UI/UX §6 está quase todo implementado). O que falta:
| Proposta | Prioridade |
|---|---|
| Botão/indicador do **Pisão** e do **Clarão** no HUD (plaqueta da direita, pips de recarga, brilho quando pronto) | **Demo** |
| **Overlay de Epitáfio** (3 lápides-carta, Madame Ossada, teclas 1/2/3 já mapeadas em `project.godot`) | **Demo** |
| **Ficha do Coveiro** (Tab) com maestrias | **Demo** |
| **Prévia de compra no turno seguinte**: no Resumo, "Com Pá Larga a sua área seria 2×2" (gancho para ir à Árvore) | **Demo** |
| Barra de Inquietação **com consequência** visível: caveira treme > 80%, chefe anunciado ("A terra treme…") | **Demo** |
| Número grande no centro em golpes com muitos tiles (já previsto pelo limite de 40, `run.gd:148`) e **combo** de covas (Vala Comum) | Demo |
| Hit-stop em crítico ≥ ×5 (DA §9.1) e "camada Ossada" com som próprio | Demo |
| Modo daltônico (letra ao lado do número, DA §10.2), auto-pisão | Demo (acessibilidade do M1) |
| Gamepad: cursor por analógico com aceleração (GDD §16) | **Demo** (Steam Deck e demo da Steam) |
| PT/EN com `tr()` e CSV | **Demo** (M1) |

### 5.8 Áudio
| O que falta | Prioridade |
|---|---|
| Pisão (`stomp`: baque grave + terra, 3–4 variações) e Clarão (`flare`: chama acendendo) | **Demo** |
| Carta de Epitáfio (virar, escolher, raridade lendária com coro) e voz/murmúrio da Madame Ossada | **Demo** |
| Chefe: tema curto `mus_boss_a1` (loop 60–90 s) + SFX (afundar, emergir, dano, derrota) | **Demo** |
| `dig_bone` (camada Ossada), `bone_rain` (Ossário cheio), `chest_open`, `coin_gold`, `soul_wander` (alminha), `combo` (Vala Comum), `seal` (raiz selada) | **Demo** |
| Loja do Mascate: sininho de porta + tema curto ou variação de `mus_tree` | Demo |
| `jingle_demo_end` (fim da demo, cita `mus_title`) | **Demo** |
| Música do turno com **intensidade em camadas** (adicionar percussão quando a área ≥ 3×3 ou com Inquietação > 80%) | Pós-demo |
| Temas das Áreas 2–5 e do hub | Pós-demo |

### 5.9 Arte (o que falta produzir)
| Item | Para quê | Prioridade |
|---|---|---|
| ~40 ícones de nó 16×16 + molduras M (40×40 ×6), X (raiz em Y), At/R e estado selado | Árvore nova | **Demo** |
| Camada **Ossada** no tileset A1 (S0/S1-like do topo + rachaduras + `_lit`) | C08 | **Demo** |
| Vela no campo (versão 32×24 "dentro do tile"), **cruz de madeira** 12×20, **Ossário** 32×32 (vazio/cheio, 3 estados), **baú** 16×16 (fechado/abrindo), **moeda dourada** 8×8 (4f), **alminha errante** (reaproveitar `alma_fila`) | Tabuleiro | **Demo** |
| Cartas de Epitáfio (3 molduras) + 12 ilustrações 32×32 | Epitáfios | **Demo** |
| Chefe Caixão Fujão (idle 4, afundar 6, emergir 6, dano 1) | Chefe | **Demo** |
| Toupeira Tita e Gato Breu (16×16, idle 2 + ação 4) | Ajudantes | **Demo** |
| Madame Ossada, Dona Ceifa, Tião (retratos 48×48) e o **Mascate** (novo personagem: vendedor ambulante esqueleto com carrinho; 24×32 + retrato) | Diálogos/loja | **Demo** |
| Ícones de amuleto (6) e de pá (3) 16×16; Pisão/Clarão 12×12 para o HUD | Loja/HUD | **Demo** |
| Variação do fundo do turno por tamanho do campo (clareira 6×6 → cemitério 12×12) | Sensação de crescimento | Demo |
| Mausoléu 3×3 (CX) | Raiz-mestra | Demo (se CX ficar) |
| Hub (superfície da Árvore), Áreas 2–5, chefes 2–5 | Jogo completo | Pós-demo |

---

## 6. Roadmap sugerido

| Marco | Conteúdo | Critério de pronto | pixel-artist | godot-dev | sound-designer |
|---|---|---|---|---|---|
| **M0.5 · Economia nova** (1ª prioridade) | Campo 6×6, área por lado (1×1→), Cobre/ponto = 1, `wisp_decay`, camada Ossada, árvore de §4.4 só com os nós **P e D** (~35), Ficha do Coveiro, zoom/Centralizar, estado "selado" (com placeholders) | Simulação em Godot (`tests/sim_*`) e playtest interno: 1º nó aos 0:30, área 3×3 por volta de 15 min, nenhum trecho de 5 turnos sem compra, árvore **não** maxável em 60 min | Ícones dos nós P/D novos; Ossada no tileset | `area_side` em `ToolData`; `kind`/`exclusive_group`/`requires` em `SkillNodeData`; novos `.tres`; sim de 60 min em `tests/` | `dig_bone` |
| **M0.6 · Ativos e regras** | Pisão, Clarão, Cava-Funda, encruzilhadas, Raiz-mestra única, Replantar | Os 4 builds da §4.5 jogáveis do começo ao fim; Pisão opcional (dá para jogar sem clicar) | Molduras At/R/X/M e selado; ícones Pisão/Clarão no HUD | Flags de regra no `RunState`; HUD do ativo; `respec()` | `stomp`, `flare`, `seal` |
| **M0.7 · Tabuleiro vivo** | Lápides com efeito, velas, cruzes, ossário, baú, alminhas, moeda dourada; 1 evento (Procissão) | Em 30 s de turno aos 20 min, o jogador vê ≥ 3 tipos de elemento além do solo e sabe o que cada um faz sem ler | Sprites da §5.9 (tabuleiro) | `FieldModel.Kind` novos + regras; spawn por nó | `bone_rain`, `chest_open`, `coin_gold`, `soul_wander` |
| **M1a · Noite completa** | Epitáfios (12), Madame Ossada, overlay; Loja do Mascate (3 pás, 6 amuletos, 2 slots); ajudantes Tita e Gato | Cada noite oferece ≥ 2 decisões (carta, amuleto); Almas sempre com uso | Cartas + 12 ilustrações; Mascate; amuletos; ajudantes | Epitáfios como `.tres` + fila; loja em painel; ajudantes | Cartas, Ossada falando, loja |
| **M1b · Chefe e fim da demo** | Caixão Fujão, Chave, diálogos, Desafios da demo, cena de fim da demo, "Continuar cavando" | Chefe aos 30–40 min (mediana de 5 testadores); fim da demo a 55–65 min | Chefe; retratos Dona Ceifa/Tião | Chefe; diálogo em balão; desafios; Inquietação 0,04 | `mus_boss_a1`, SFX do chefe, `jingle_demo_end` |
| **M1c · Demo Steam** | Gamepad, PT/EN, daltônico, auto-pisão, "Abandonar a noite"/"Voltar ao título", polimento | Critério do GDD M1: playtest com 5+ pessoas, **50–70 min**, ≥ 2 de 5 querem jogar de novo com outra build | Ajustes finais, cápsula da Steam | Input de gamepad, `tr()` + CSV, opções | Mixagem final |
| M2 · Conteúdo | Hub na superfície da Árvore, Áreas 2–4, ferramentas, Cão e Morcegos, Lua Nova + Lunar, Relíquias | GDD §19 M2 | — | — | — |

Ordem recomendada: **M0.5 → M0.6** em sequência (a economia muda tudo); M0.7 e a arte do M1a em paralelo a partir do M0.6; título (em implementação) termina em paralelo sem conflito.

---

## 7. Decisões para o designer-chefe

1. **"Área de 1 tile" é a área da pá, o campo ou os dois?** Proposta: **os dois começam pequenos** (pá 1×1, campo 6×6), com lados 4×4/5×5 da pá em pontas distantes. Confirmar.
2. **Trocar raio por lado** (permitir 2×2 e 4×4)? Muda `ToolData.cells()` e a leitura do contorno. Proposta: sim.
3. **Cobre por ponto = 1** (dobrar todos os números de Cobre)? Muda a §14.1 do GDD para "1º turno 12–18 Cobre".
4. **Raiz-mestra única + encruzilhadas 1-de-2:** aceitar como regra central da árvore? Isso substitui a ideia de "maxar a árvore" como objetivo.
5. **Replantar (respec 100%) após o chefe:** ok? Ou cobrar (ex.: devolver 80%)?
6. **Uma loja só na demo (Mascate) com amuletos em 2 slots:** aprovar, e decidir se os amuletos viram as Relíquias do jogo completo (recomendado).
7. **Hub fora da demo** e, no jogo completo, como superfície da Árvore em vez de cena separada: aprovar a mudança no GDD §11/§15.1.
8. **Cava-Funda** (o excedente passa) como nó de regra: aprovar a exceção à §4.3.
9. **Fogo-fátuo com retorno decrescente (0,8):** aprovar como correção do risco de noite infinita.
10. **Elementos de tabuleiro da demo:** confirmar os 6 de prioridade "Demo" da §5.2 (lápides com efeito, vela, cruz, ossário, baú, alminhas) ou cortar para 4.
11. **Duração-alvo:** 55–65 min até a Raiz-mestra, com chefe aos 30–40, substituindo o "40–50 min" do M1 no GDD §19?

---

## Apêndice A — Método da simulação

- **Modelo:** reimplementação em Python (NumPy) das regras de `run_state.gd`/`field_model.gd`: camadas por tile com HP e excedente perdido, Cobre por ponto, Osso e XP só na quebra, covas (lápide bloqueando, caixão 2× HP, 3 s aberta, reaparecimento com folga de 1 tile), rochas (0–2, HP 60, dreno 0,5 s), fogos-fátuos (12 ± 3 s, 5 s de vida), regeneração só de Buraco, Campo Limpo, amanhecer aos 300 s e bônus de óleo. Mesma ordem do pulso (GDD §18.3).
- **Jogador:** escolhe a cada golpe o centro com maior valor esperado (Cobre/ponto × dano útil esperado com crítico, + peso para caixão/cova, − rocha); 25% dos golpes ficam no lugar anterior ("em trânsito"); persegue 90% dos fogos-fátuos; ~10–12 s entre turnos + 0,6 s por compra. Políticas de compra: "mais barato primeiro" (hoje) ou "foco em um ramo" (custos do ramo pesam 0,3×; as outras Raízes-mestras ficam bloqueadas).
- **Diferença para `tests/sim_first_turn.gd`:** o teste do repo usa estratégias por blocos (humano 75%) e acha 50–60 Cobre no 1º turno; o cursor guloso, que é o teto prático, acha ~73. A conclusão (~8 min para maxar) é robusta às duas: com 50–60% de golpes desperdiçados ainda dá 11–13 min.
- **Limites:** a simulação da proposta modela os nós P e D e aproxima alguns At/R como multiplicadores (Pisão ≈ +15% de dano médio; pontas como multiplicadores). Não modela Epitáfios, loja, ajudantes nem elementos de tabuleiro, que somam renda e são **sumidouros** de Ossos e Almas. Por isso os Ossos "sobram" no fim da simulação.
- **Arquivos:** os scripts ficaram no scratchpad da sessão de análise (fora do repositório, por instrução). Para a equipe, a recomendação é portar a lógica de campanha para `tests/sim_campaign.gd` (godot-dev, M0.5), reaproveitando o `RunState` real.
