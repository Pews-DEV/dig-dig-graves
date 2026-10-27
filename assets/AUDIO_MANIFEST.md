# Manifesto de Áudio — Dig Dig Graves

Contrato entre `sound-designer` e `godot-dev`. Cada som é referenciado pelo **id**. Música: `assets/music/<id>.ogg` (estéreo). SFX: `assets/sfx/<id>_<n>.ogg` (mono, n = variação). Todos OGG Vorbis q5, 44,1 kHz.
Fonte: tudo sintetizado em `audio_src/` (`music.py`, `sfx.py`, núcleo em `dsp.py`; medição em `verify.py`). Ver `assets/AUDIO_CREDITS.md`.

## Regras de reprodução (GDD §17, UI/UX §8)
- SFX repetitivos (golpes, pickups, ticks, UI): sortear uma variação a cada disparo e aplicar pitch aleatório ±6%; máx. 6 vozes simultâneas por id.
- Loops (`mus_title`, `mus_tree`, `mus_area1`, `amb_night`, `amb_souls_choir`): o arquivo inteiro é o loop — ligar `loop = true`, `loop_offset = 0`. A cauda de reverb já está "enrolada" no início; não precisa de crossfade no motor.
- Buses sugeridos: Music (músicas, jingle, stingers), SFX (inclui `logo_land`, `logo_thunk`, `logo_drip`), UI (`ui_*`, `node_*`, `root_grow`, `level_up`, `screen_transition`), Ambience (`amb_night`, `amb_souls_choir`).
- Níveis já vêm mixados entre si (golpe < quebra de camada < cova aberta; UI bem abaixo do gameplay). Tocar com volume 0 dB no player e ajustar só pelos buses.

## Música (`assets/music/`)

| id | arquivo(s) | duração | loop (sim/não, ponto) | uso no jogo | observações |
|---|---|---|---|---|---|
| mus_title | mus_title.ogg | 108,000 s | sim, arquivo inteiro (0 → fim) | **Tema principal** — tela-título (UI/UX §9.5). Começa em t = 0 da abertura, junto com o fade do preto (0,6 s, feito pelo jogo), e segue em loop enquanto o menu estiver aberto; na volta ao título vindo do jogo, entra direto (mesmo fade). Ao começar/continuar, fade-out ~0,4 s junto com `screen_transition`. | Lá menor, 80 BPM, 4/4, 36 compassos. Forma: intro rala de 4 compassos (órgão + violão rolado, a caixinha anuncia o motivo ao longe; RMS ~10 dB abaixo do corpo, casa com o fade-in) → A (caixinha) → A (assovio + contracanto) → B **maior** (Fá–Sol–Dó; assovio, sino de capela e coro "aah" bem baixos) → A final (caixinha + assovio uma oitava abaixo, rarefaz e volta à intro). **Motivo compartilhado "M"**: grau 5 pontuado descendo até o 3 e caindo no 1 (ritmo 1,5 + 0,5 + 1 tempo: Mi–Ré–Dó–Lá), respondido pela subida 2-3-4-5 até a oitava (Si–Dó–Ré–Mi–Lá). `mus_tree` abre com a metade de cima de M (Mi–Ré–Dó pontuado + resposta Si–Dó–Mi); `mus_area1` abre com M em arpejo (Lá–Fá–Ré pontuado, em Ré m) + resposta Mi–Fá–Sol–Lá–Ré. **Cadência "C"** também compartilhada: arpejo descendente do V7 até a sensível (Fá–Ré–Si–Sol♯ → Lá), o Ré–Si–Sol♯–Lá de `mus_tree` e o Dó♯–Mi–Ré de `mus_area1`. −14 LUFS. |
| mus_tree | mus_tree.ogg | 116,757 s | sim, arquivo inteiro (0 → fim) | Tema da Árvore de Raízes / hub | Valsa em Lá menor, 74 BPM, 3/4, 48 compassos. Forma: A (violão + órgão) → A (caixinha) → B (caixinha) → C (assovio, maior) → A (assovio) → B (caixinha, termina em E7 para voltar ao início). −14 LUFS. |
| mus_area1 | mus_area1.ogg | 120,000 s | sim, arquivo inteiro (0 → fim) | Música do turno na Área 1 (Cemitério da Paróquia) | Ré menor, 88 BPM, 4/4, 44 compassos. Violão com baixo alternado, escovinha em 2 e 4, chocalho/bloco de madeira leves. Forma: intro → A (caixinha) → A (assovio) → B (maior) → A (caixinha + assovio grave) → ponte (volta para a intro). −14 LUFS. |
| jingle_summary | jingle_summary.ogg | 7,0 s | não | Abertura da tela de Resumo do Turno | Lá m → Fá → Sol → Lá **maior** (resolução). Tocar com fade-out da música do turno (~0,3 s) antes. −15 LUFS. |
| stinger_grave | stinger_grave.ogg | 2,4 s | não | Cova aberta | Sino de capela (Lá) + coro "aah" em Lá maior. Toca junto com `grave_open`; pode-se baixar a música ~4 dB por 2 s (ducking). |
| stinger_level | stinger_level.ogg | 1,25 s | não | Subiu de nível | Caixinha ascendente (arpejo de Lá maior). Toca junto com `level_up`. |

## SFX (`assets/sfx/`)

| id | arquivo(s) | duração | loop (sim/não, ponto) | uso no jogo | observações |
|---|---|---|---|---|---|
| dig_grass | dig_grass_1..4.ogg | 0,11–0,14 s | não | Golpe em camada de grama | Farfalhar + baque leve. Pico −8 dBFS. |
| dig_dirt | dig_dirt_1..4.ogg | 0,11–0,13 s | não | Golpe em terra | "Tuf" grave. Pico −7 dBFS. |
| dig_clay | dig_clay_1..4.ogg | 0,15–0,21 s | não | Golpe em barro | "Chlap" úmido com bolhinhas. Pico −7 dBFS. |
| dig_coffin | dig_coffin_1..4.ogg | 0,27–0,30 s | não | Golpe em tampa de caixão | Madeira oca com ressonância grave. Pico −6 dBFS. |
| dig_rock | dig_rock_1..4.ogg | 0,21–0,23 s | não | Golpe em rocha/pedra | "Tinc" metálico. Pico −7 a −9 dBFS. |
| layer_break | layer_break_1..3.ogg | 0,39–0,43 s | não | Camada do tile quebrou | Baque + estalo + torrões caindo. Pico −4,6 dBFS. |
| pickup_copper | pickup_copper_1..4.ogg | 0,31–0,34 s | não | Cobre chega ao HUD | Moedinha (2 toques); as 4 variações sobem de altura (1→4) — pode-se usar em sequência para "chuva" de moedas. |
| pickup_bone | pickup_bone_1..4.ogg | 0,19–0,20 s | não | Osso chega ao HUD | "Tic-toc" de xilofone de madeira. |
| pickup_soul | pickup_soul_1..3.ogg | 0,68–0,72 s | não | Alma chega ao HUD | Brilho etéreo subindo + faíscas. |
| wisp_collect | wisp_collect_1..3.ogg | 0,46–0,54 s | não | Fogo-fátuo coletado | Chama "fuuf" + sininho + faíscas. |
| oil_tick | oil_tick_1..2.ogg | 0,04–0,06 s | não | 1 tique por segundo nos últimos 3 s de óleo | Alternar 1/2 (tic/tac). Sem pitch aleatório aqui (é relógio). |
| oil_out | oil_out_1..2.ogg | 0,76–0,78 s | não | Óleo acabou / lanterna apaga (fim do turno) | Sopro + chama morrendo. |
| grave_open | grave_open_1..2.ogg | 1,09–1,11 s | não | Cova aberta (junto com `stinger_grave`) | Tampa rangendo (energia em 100–700 Hz, deixa livre a faixa do sino/coro) + baque grave da tampa em ~0,85 s. Pico −3 dBFS (o mais alto dos SFX). |
| ui_hover | ui_hover_1..3.ogg | 0,02 s | não | Hover em botão/medalhão | Tique de madeira bem suave. Pico −20 dBFS. |
| ui_click | ui_click_1..3.ogg | 0,05 s | não | Clique em botão | "Toc" de madeira. Pico −13 dBFS. |
| ui_panel_open | ui_panel_open_1..2.ogg | 0,20 s | não | Abrir painel/pergaminho | Papel deslizando + toque de madeira no fim. |
| ui_panel_close | ui_panel_close_1..2.ogg | 0,12 s | não | Fechar painel | Versão curta, termina em toque mais grave. |
| ui_count_tick | ui_count_tick_1..3.ogg | 0,02 s | não | Contadores animados (Resumo, recursos) | Curtíssimo, limpo a 20/s. Pico −18 dBFS. Pode-se subir o pitch levemente ao longo da contagem. |
| node_buy | node_buy_1..3.ogg | 0,41 s | não | Compra de nó da Árvore | "Pop" + 3 moedas. Ao segurar para comprar, subir o pitch a cada repetição (UI/UX §7.3). |
| root_grow | root_grow_1..3.ogg | 0,39 s | não | Raiz crescendo até o filho (350 ms) | Estalos orgânicos acelerando + terra + rangido grave. |
| node_reveal | node_reveal_1..2.ogg | 0,50–0,53 s | não | Novo nó revelado (brota do chão) | Terra subindo + "plop" + brilhinho em ~0,2 s. |
| level_up | level_up_1.ogg | 0,63 s | não | Subiu de nível (junto com `stinger_level`) | Três sininhos ascendentes (Lá maior), complementa o stinger. |
| screen_transition | screen_transition_1..2.ogg | 0,34–0,36 s | não | Transição "cortina de terra" (450 ms) | Pá raspando + arremesso + terra caindo. |
| amb_night | amb_night_1.ogg | 48,0 s | sim, arquivo inteiro (0 → fim) | Ambiente noturno (Árvore/hub e turno) | **Estéreo.** Grilos, vento leve e folhas; sem eventos marcantes. −30 LUFS (bem baixo). |
| logo_land | logo_land_1..4.ogg | 0,09–0,12 s | não | Tela-título, abertura passo 3: pouso de cada letra do logo (12 disparos, 40 ms entre eles, um por letra no frame do squash) | "Toc" de pedra abafado + poeirinha. Sortear variação + pitch ±6% a cada letra. Pico −17 dBFS; as 12 sobrepostas somam pico −16,8 / RMS −29 (não empilham). Bus SFX. |
| logo_thunk | logo_thunk_1..2.ogg | 1,35 s | não | Tela-título, fim do passo 3: a pá crava no 2º G (mesmo frame do tremor de 1 px), ~60–100 ms depois do pouso da última letra | "Tunc" de cabo de madeira + lâmina entrando na terra + torrões, com reverb de capela já embutido. Pico −6 dBFS (o som mais forte da tela). Uma variação basta por abertura (sortear 1/2). Bus SFX. |
| logo_drip | logo_drip_1..3.ogg | 0,06–0,07 s | não | Tela-título: a terrinha que cai logo após o `logo_thunk` (~0,25 s depois) e cada gota do logo ocioso, no frame em que a gota some (toca no impacto; a pá balança em seguida) | Tique minúsculo + "puf" de terra. Bem baixinho: pico −20 dBFS, RMS −40. Pitch ±6%. Bus SFX. |
| amb_souls_choir | amb_souls_choir_1.ogg | 32,0 s | sim, arquivo inteiro (0 → fim) | Tela-título: coro das almas na fila. Começa em t = 0 com o fade junto com `amb_night` (ou entra com fade de ~2 s durante a descida da câmera) e fica em loop por baixo enquanto o título estiver aberto | **Estéreo.** Vozes longas "uuh → aah" em Lá menor pentatônica (casa com `mus_title`), filtradas e quase só reverb (distante), levemente à esquerda (lado da vila/portão). "Vai e volta": 2 ondas de intensidade por loop (~13 dB entre vale e crista). −35 LUFS (abaixo do `amb_night`). Bus Ambience. |
| ui_wisp_slide | ui_wisp_slide_1..3.ogg | 0,26 s | não | Menu do título: o fogo-fátuo desliza até o botão em foco (toda mudança de foco por mouse, teclado ou gamepad); também no painel "Enterrar/Voltar" | Sopro que sobe + sininho de vidro. Substitui o `ui_hover` no menu do título (não tocar os dois). Pico −23 dBFS, RMS −30,5 (entre `ui_hover` e `ui_click`). Sortear variação + pitch ±6%. Bus UI. |
| ui_bury | ui_bury_1..2.ogg | 1,40 s | não | Confirmação "Enterrar o progresso atual?": ao apertar **Enterrar** (no lugar do `ui_click`) | Pá raspando + terra jogada e caindo + sino grave (Lá 110 Hz) com capela. Pico −9 dBFS. Em seguida vem a saída normal do Novo Jogo (`screen_transition`). Bus UI. |

### Tela-título — onde cada som entra (UI/UX §9.3–§9.5)
| Momento | Sons |
|---|---|
| t = 0: preto → céu (fade 0,6 s) | `mus_title` (do início), `amb_night`, `amb_souls_choir` — todos sob o mesmo fade-in |
| 0,6–2,6 s: câmera desce | só a cama acima (nenhum SFX) |
| Letras caindo (40 ms entre letras) | `logo_land` × 12, um no pouso de cada letra |
| Pá crava no G | `logo_thunk`; ~0,25 s depois `logo_drip` (terrinha caindo) |
| Menu entra (botões sobem, 60 ms) | sem som por botão (evita metralhada); opcional: um único `ui_panel_open` |
| Foco muda (cursor fogo-fátuo desliza) | `ui_wisp_slide` |
| Clique em Continuar / Novo Jogo (sem save) / Opções / Créditos / Sair / Voltar | `ui_click` |
| Abrir/fechar painel de lápide, Opções e Créditos | `ui_panel_open` / `ui_panel_close` |
| "Enterrar" confirmado | `ui_bury` |
| Logo ocioso: cada gota | `logo_drip` |
| Começar/continuar: Coveiro levanta → cortina de terra | `screen_transition`; `mus_title` e `amb_souls_choir` com fade-out ~0,4 s; `amb_night` pode continuar |
| Volta ao título vindo do jogo | `mus_title` + ambientes direto (sem `logo_*`, logo já montado) |
| Hover de mouse fora do menu (ex.: nada focável) | `ui_hover` não é usado no título (o `ui_wisp_slide` cumpre o papel) |

## Medições (do OGG final, `python audio_src/verify.py`)

| id | LUFS-I | true peak (dBTP) | RMS máx 50 ms (dBFS) | silêncio inicial | costura do loop |
|---|---|---|---|---|---|
| mus_title | −14,0 | −2,8 | −12,1 | 0 ms | percentil 7,7, ΔRMS −0,1 dB — sem clique |
| mus_tree | −14,0 | −3,2 | −12,7 | 0 ms | salto na costura dentro do normal (percentil 33 dos saltos entre amostras) |
| mus_area1 | −14,0 | −2,2 | −12,6 | 0 ms | percentil 18 — sem clique |
| jingle_summary | −15,0 | −4,6 | −14,7 | 0 ms | — |
| stinger_grave | −13,7 | −2,1 | −12,7 | 0 ms | — |
| stinger_level | −13,5 | −4,5 | −14,8 | 0 ms | — |
| amb_night | −30,1 | −16,2 | −28,0 | 0 ms | percentil 90 (ruído de grilo; sem clique) |
| amb_souls_choir | −35,0 | −18,4 | −29,9 | 0 ms | percentil 65,5, ΔRMS −0,4 dB — sem clique |
| logo_thunk | −30,0 / −30,2 | −6,0 / −6,1 | −15,0 / −15,1 | 0 ms | — |
| ui_bury | −27,7 / −28,0 | −9,1 / −9,2 | −15,5 / −16,0 | 0 ms | — |
| logo_land | curto* | −16,9 a −17,1 | −31,4 a −32,3 | 0 ms | — |
| ui_wisp_slide | curto* | −22,8 a −23,3 | −30,5 a −30,6 | 0 ms | — |
| logo_drip | curto* | −20,2 a −20,8 | −39,9 a −40,4 | 0 ms | — |
| grave_open | −17,2 / −18,3 | −3,0 | −11,0 | 0 ms | — |
| layer_break | ≈ −26 | −4,6 a −5,0 | −15,1 a −15,7 | 0 ms | — |
| dig_coffin | curto* | −5,9 a −6,2 | −16,2 a −16,6 | 0 ms | — |
| dig_dirt | curto* | −7,0 a −7,1 | −17,9 a −18,5 | 0 ms | — |
| dig_clay | curto* | −6,3 a −7,0 | −18,8 a −20,6 | 0 ms | — |
| dig_rock | curto* | −7,1 a −8,8 | −22,0 a −25,2 | 0 ms | — |
| dig_grass | curto* | −8,0 a −9,0 | −23,8 a −26,6 | 0 ms | — |
| oil_out | −23,5 / −24,7 | −4,9 | −15,7 a −16,1 | 0 ms | — |
| wisp_collect | −22 a −26 | −6,6 a −7,1 | −16,3 a −17,0 | 0 ms | — |
| level_up | −22,1 | −7,1 | −15,7 | 0 ms | — |
| node_buy | −22 a −24 | −7,0 a −8,3 | −19,8 a −20,2 | 0 ms | — |
| node_reveal | −23,2 / −23,5 | −8,6 / −9,4 | −19,5 | 0 ms | — |
| screen_transition | curto* | −8,3 / −8,4 | −20,1 / −20,6 | 0 ms | — |
| root_grow | curto* | −8,9 a −9,7 | −21,2 a −23,6 | 0 ms | — |
| pickup_soul | −27 a −29 | −9,9 a −10,1 | −18,2 a −19,8 | 0 ms | — |
| pickup_bone | curto* | −9,9 a −10,4 | −21,8 a −22,1 | 0 ms | — |
| pickup_copper | curto* | −10,4 a −10,9 | −21,6 a −22,7 | 0 ms | — |
| oil_tick | curto* | −8,5 / −9,1 | −26,3 / −29,9 | 0 ms | — |
| ui_panel_open | curto* | −14,1 / −14,9 | −26,7 / −27,0 | 0 ms | — |
| ui_click | curto* | −13,1 a −13,4 | −29,6 a −30,1 | 0 ms | — |
| ui_panel_close | curto* | −16,1 / −16,4 | −30,1 / −31,1 | 0 ms | — |
| ui_count_tick | curto* | −18,0 a −18,7 | −33,3 a −33,8 | 0 ms | — |
| ui_hover | curto* | −19,9 a −20,4 | −34,3 a −35,3 | 0 ms | — |

\* "curto": abaixo de 400 ms o LUFS integrado (BS.1770) não é definido; use pico e RMS de 50 ms para comparar.
