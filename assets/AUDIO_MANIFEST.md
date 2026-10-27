# Manifesto de Áudio — Dig Dig Graves

Contrato entre `sound-designer` e `godot-dev`. Cada som é referenciado pelo **id**. Música: `assets/music/<id>.ogg` (estéreo). SFX: `assets/sfx/<id>_<n>.ogg` (mono, n = variação). Todos OGG Vorbis q5, 44,1 kHz.
Fonte: tudo sintetizado em `audio_src/` (`music.py`, `sfx.py`, núcleo em `dsp.py`; medição em `verify.py`). Ver `assets/AUDIO_CREDITS.md`.

## Regras de reprodução (GDD §17, UI/UX §8)
- SFX repetitivos (golpes, pickups, ticks, UI): sortear uma variação a cada disparo e aplicar pitch aleatório ±6%; máx. 6 vozes simultâneas por id.
- Loops (`mus_tree`, `mus_area1`, `amb_night`): o arquivo inteiro é o loop — ligar `loop = true`, `loop_offset = 0`. A cauda de reverb já está "enrolada" no início; não precisa de crossfade no motor.
- Buses sugeridos: Music (músicas, jingle, stingers), SFX, UI (`ui_*`, `node_*`, `root_grow`, `level_up`, `screen_transition`), Ambience (`amb_night`).
- Níveis já vêm mixados entre si (golpe < quebra de camada < cova aberta; UI bem abaixo do gameplay). Tocar com volume 0 dB no player e ajustar só pelos buses.

## Música (`assets/music/`)

| id | arquivo(s) | duração | loop (sim/não, ponto) | uso no jogo | observações |
|---|---|---|---|---|---|
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

## Medições (do OGG final, `python audio_src/verify.py`)

| id | LUFS-I | true peak (dBTP) | RMS máx 50 ms (dBFS) | silêncio inicial | costura do loop |
|---|---|---|---|---|---|
| mus_tree | −14,0 | −3,2 | −12,7 | 0 ms | salto na costura dentro do normal (percentil 33 dos saltos entre amostras) |
| mus_area1 | −14,0 | −2,2 | −12,6 | 0 ms | percentil 18 — sem clique |
| jingle_summary | −15,0 | −4,6 | −14,7 | 0 ms | — |
| stinger_grave | −13,7 | −2,1 | −12,7 | 0 ms | — |
| stinger_level | −13,5 | −4,5 | −14,8 | 0 ms | — |
| amb_night | −30,1 | −16,2 | −28,0 | 0 ms | percentil 90 (ruído de grilo; sem clique) |
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
