# Manifesto de Áudio — Dig Dig Graves

Contrato entre `sound-designer` e `godot-dev`. Cada som é referenciado pelo **id**. Música: `assets/music/<id>.ogg` (estéreo). SFX: `assets/sfx/<id>_<n>.ogg` (mono, n = variação). Todos OGG Vorbis q5, 44,1 kHz.
Fonte: tudo sintetizado em `audio_src/` (`music.py`, `sfx.py`, núcleo em `dsp.py`; medição em `verify.py`). Ver `assets/AUDIO_CREDITS.md`.

## Regras de reprodução (GDD §17, UI/UX §8)
- SFX repetitivos (golpes, pickups, ticks, UI): sortear uma variação a cada disparo e aplicar pitch aleatório ±6%; máx. 6 vozes simultâneas por id.
- Loops (`mus_title`, `mus_tree`, `mus_area1`, `mus_area2`, `mus_area3`, `mus_area4`, `mus_area5`, `mus_boss`, `mus_shop`, `amb_night`, `amb_souls_choir`): o arquivo inteiro é o loop — ligar `loop = true`, `loop_offset = 0`. A cauda de reverb já está "enrolada" no início; não precisa de crossfade no motor.
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
| mus_boss | mus_boss.ogg | 74,667 s | sim, arquivo inteiro (0 → fim) | Tema de chefe (genérico, todos os estágios): toca a **Noite do Chefe** inteira no lugar do `mus_areaN` (crossfade ~1 s). Para quando o chefe morre (fade-out 0,3 s → `jingle_boss_win`) ou quando o óleo acaba com ele vivo (fade-out normal para o Resumo). | Ré menor, 90 BPM, 4/4, 28 compassos. Galope de violão (3+3+2), surdo grave, órgão com pedal, bII (Mi♭) frígio para tensão. M em Ré m (Lá–Sol–Fá pontuado–Ré, resposta Mi–Fá–Sol–Lá–Ré) na caixinha; assovio na parte B; o órgão repete M no grave; C = Sol–Mi–Dó♯ → Ré. Virada de surdo no fim volta à intro. −14 LUFS. |
| mus_area2 | mus_area2.ogg | 113,684 s | sim, arquivo inteiro (0 → fim) | Música do turno no estágio 2 (Campo dos Indigentes) | Mi menor, 76 BPM, 4/4, 36 compassos. Violão dedilhado, assovio (melodia), sanfona discreta (acordes; numa passagem leva a melodia uma oitava abaixo), névoa (ruído filtrado passeando), coro bem distante. M em Mi m: Si–Lá–Sol pontuado–Mi, resposta Fá♯–Sol–Lá–Si–Mi; C = Lá–Fá♯–Ré♯ → Mi. Parte B em Sol maior. −14 LUFS. |
| mus_area3 | mus_area3.ogg | 123,429 s | sim, arquivo inteiro (0 → fim) | Música do turno no estágio 3 (Catacumbas de Pedra) | Dó menor, 70 BPM, 4/4, 36 compassos. Órgão em primeiro plano (M: Sol–Fá–Mi♭ pontuado–Dó), violão grave e lento, gotas com eco (o eco e o reverb são circulares: a costura é limpa), zumbido de Dó grave, coro de monges "uuh" e sino na parte maior (Mi♭). C = Fá–Ré–Si → Dó. −14 LUFS. |
| mus_area4 | mus_area4.ogg | 99,000 s | sim, arquivo inteiro (0 → fim) | Música do turno no estágio 4 (Necrópole dos Barões) | Sol menor, valsa de salão lenta, 80 BPM, 3/4, 44 compassos. Cravo no acompanhamento (baixo + 2 acordes), piano de salão velho (levemente desafinado, apojaturas) na melodia, órgão solene, sinos. M em 3/4: Ré–Dó–Si♭ pontuado / Sol – Lá / Si♭–Dó–Ré / Sol (oitava); C = Dó–Lá–Fá♯ → Sol. Uma parte com o cravo solando. −14 LUFS. |
| mus_area5 | mus_area5.ogg | 123,429 s | sim, arquivo inteiro (0 → fim) | Música do turno no estágio 5 (Jardim das Almas) | Lá menor → **Lá maior** na última parte; 70 BPM, 4/4, 36 compassos, sem percussão. Caixinha (melodia, cita o `mus_title`), coro "uuh/éh/aah", harpa de violão, vidro (senoides), sinos. A parte final toca M em maior (Mi–Ré–Dó♯–Lá) e volta ao menor na costura. −14 LUFS. |
| mus_shop | mus_shop.ogg | 42,667 s | sim, arquivo inteiro (0 → fim) | Loja do Mascate: enquanto o painel/tela da loja estiver aberto (crossfade ~0,5 s com a música do hub; ao fechar, volta a do hub) | Xote simpático em Dó maior, 90 BPM, 4/4, 16 compassos. Sanfona na melodia (M em maior: Sol–Fá–Mi pontuado–Dó, resposta Ré–Mi–Fá–Sol–Dó), violão, zabumba (surdo + bacalhau), triângulo, caixinha como "quinquilharias" do carrinho. −14 LUFS. |
| mus_ending | mus_ending.ogg | 78,667 s | **não** | Cena final (Dona Ceifa deita e entrega a foice) até o começo dos créditos | Lá menor → Lá maior, 72 BPM com ritardando no fim. Cada frase passa por um instrumento dos estágios: violão sozinho canta M (citação do `mus_title`) → caixinha + sanfona + órgão → assovio com M em **maior**, coro e sino → cravo na coda → acorde final de Lá maior suspenso (sino, coro, caixinha subindo) com fade de 4 s embutido. Começa direto (não precisa de fade). −14 LUFS. |
| jingle_boss_win | jingle_boss_win.ogg | 5,6 s | não | Vitória sobre o chefe: ~0,3 s depois do `boss_defeat`, com a `mus_boss` em fade-out | M em Ré menor que vira Ré **maior** na resposta (Fá → Fá♯), surdo, sino, coro "aah", caixinha subindo. −15 LUFS (igual ao `jingle_summary`). Se o Resumo especial vier logo depois, não tocar o `jingle_summary` por cima (ou esperar o fim deste). |
| stinger_boss_appear | stinger_boss_appear.ogg | 2,3 s | não | O chefe surge (1ª aparição na noite; junto com `boss_emerge`) | Surdo + gongo grave, órgão com Ré–Mi♭–Lá (bII), cabeça de M descendo rápido na caixinha, sino grave. Pico −5 dBTP (abaixo do `grave_open`). Ducking da música ~4 dB por 2 s, como no `stinger_grave`. |
| stinger_stage_unlock | stinger_stage_unlock.ogg | 2,3 s | não | Novo estágio liberado (quando o estágio aparece/destrava no seletor de estágios ou a Chave da Cripta é usada) | Sino + resposta de M em Lá maior (Si–Dó♯–Ré–Mi–Lá) na caixinha + coro "aah" + violão rolado. Pico −5 dBTP. |

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
| stomp | stomp_1..4.ogg | 0,40–0,48 s | não | **Pisão** ativado (clique/tecla/auto-pisão), no frame do impacto | Baque subgrave + terra explodindo + farelos + rumor. Pico −4 dBFS (abaixo só do `grave_open`). Pitch ±6%; máx. 3 vozes. Bus SFX. |
| flare | flare_1..3.ogg | 0,85–0,88 s | não | **Clarão** ativado | Fósforo riscando + chama "fuump" + estalos + brilho tonal. Pico −6 dBFS. Bus SFX. |
| dig_bone | dig_bone_1..4.ogg | 0,13–0,18 s | não | Golpe na camada **Ossada** | "Toc-tac" oco de ossos + chocalhar miúdo + terra. Pico −7 dBFS. Regras de golpe (variação + ±6%, máx. 6 vozes). |
| dig_mud | dig_mud_1..4.ogg | 0,30–0,42 s | não | Golpe em **lama** (estágio 2) | Baque mole + "chlop" + sucção subindo + bolhas (o barro desce; a lama sobe). Pico −7 dBFS. |
| dig_stone | dig_stone_1..4.ogg | 0,11–0,15 s | não | Golpe em **pedra das catacumbas** (estágio 3) | "Toc" seco e opaco (sem o "tinc" metálico do `dig_rock`) + areia + lascas. Pico −7 dBFS. |
| dig_marble | dig_marble_1..4.ogg | 0,31–0,36 s | não | Golpe em **mármore** (estágio 4) | "Clank" polido e brilhante com ressonância. Pico −8 dBFS. |
| dig_mist | dig_mist_1..4.ogg | 0,42 s | não | Golpe em tile de **névoa** (estágio 5) | Golpe macio + sopro "fff" descendo + tom de vidro que se desfaz (Lá m pentatônica). Pico −9 dBFS. |
| boss_sink | boss_sink_1..2.ogg | 0,90 s | não | Chefe afunda/some (Caixão Fujão a cada 4 s; serve a qualquer chefe que se esconda) | Rangido de madeira + terra escorrendo + "glup" grave em ~0,55 s. Pico −6 dBFS. Bus SFX. |
| boss_emerge | boss_emerge_1..2.ogg | 0,96–1,02 s | não | Chefe reaparece/emerge (na 1ª aparição, junto com `stinger_boss_appear`) | Rumor crescendo + rangido subindo + explosão de terra em ~0,6 s (sincronizar o pulo do sprite com esse ponto). Pico −5 dBFS. |
| boss_hit | boss_hit_1..3.ogg | 0,26–0,29 s | não | Cada golpe que acerta o chefe (no lugar do `dig_*` do tile) | Madeira grossa e oca (mais grave que `dig_coffin`) + caixão chacoalhando. Pico −6 dBFS. Pitch ±6%; máx. 4 vozes. |
| boss_defeat | boss_defeat_1.ogg | 2,51 s | não | HP do chefe chega a 0 | Estalo grande + lascas + desabamento + terra assentando + alma subindo + sino, com capela. Pico −3,5 dBFS (como a cova aberta). Seguido do `jingle_boss_win` ~0,3 s depois. |
| card_flip | card_flip_1..3.ogg | 0,09–0,10 s | não | Epitáfios: cada carta-lápide virando na apresentação (80–120 ms entre as 3) | Sopro curto + toque de pedra fina. Pico −15 dBFS. Sortear variação + ±6%. Bus UI. |
| card_pick | card_pick_1..2.ogg | 0,58–0,60 s | não | Escolher uma carta (comum/rara) | Toque + arpejo de sininhos (Lá maior) + faíscas. Pico −11 dBFS. Bus UI. |
| card_legendary | card_legendary_1.ogg | 1,99 s | não | Carta **lendária** virando (no lugar do `card_flip` dela); ao escolher, `card_pick` normal | Sino + coro "aah" em Lá maior + chuva de faíscas, com capela. Pico −8 dBFS. Ducking leve da música (~3 dB) opcional. Bus UI. |
| shop_bell | shop_bell_1..2.ogg | 0,67–0,69 s | não | Abrir a loja do Mascate (sininho da porta/carrinho), junto com a troca para `mus_shop` | 4–5 batidas de sininho na mola, perdendo força. Pico −12 dBFS. Bus UI. |
| shop_buy | shop_buy_1..3.ogg | 0,61–0,65 s | não | Compra concluída na loja | Moedas no balcão de madeira + "tlim" da venda. Pico −10 dBFS. Bus UI. |
| shop_deny | shop_deny_1..2.ogg | 0,19 s | não | Sem saldo / item indisponível (serve também a clique em nó selado) | Dois "bonc" de madeira abafados descendo uma terça menor. Pico −15 dBFS. Bus UI. |
| coin_gold | coin_gold_1..3.ogg | 0,44–0,49 s | não | Moeda dourada coletada no tabuleiro | Mais grave, pesada e brilhante que o `pickup_copper`; as variações sobem de altura (1→3). Pico −9 dBFS. |
| chest_open | chest_open_1..2.ogg | 1,18–1,20 s | não | Baú enterrado aberto | Trinco + dobradiça rangendo (aguda) + tampa batendo em ~0,62 s + brilho do tesouro. Pico −6 dBFS. |
| bone_rain | bone_rain_1..2.ogg | 1,33–1,35 s | não | Ossário cheio esvazia (chuva de ossos) | 22–31 toques de osso caindo e chacoalhando, rareando. Pico −7 dBFS. |
| soul_wander | soul_wander_1..2.ogg | 1,60–1,65 s | não (one-shot recorrente) | Alminha errante no campo: disparar a cada 3–6 s (aleatório) enquanto ela estiver na tela; pan pela posição; máx. 2 vozes | "Uuu" baixinho e curioso (1 sobe, 2 desce) + brilho, com capela. Pico −20 dBFS (fica por baixo de tudo). Bus SFX ou Ambience. |
| tombstone_effect | tombstone_effect_1..3.ogg | 0,57 s | não | Lápide com efeito ativando no campo | Pedra arrastando curtinho + sininho mágico (Mi/Sol/Lá) + brilho. Pico −10 dBFS. |
| seal | seal_1..2.ogg | 0,88–0,89 s | não | Raiz selada: ao comprar um lado de uma encruzilhada (o outro sela) ou ao escolher a Raiz-mestra | Raízes se atando + trava "clunc" em ~0,22 s + sino grave misterioso. Pico −10 dBFS. Bus UI. |
| respec | respec_1..2.ogg | 1,83 s | não | Confirmar **Replantar** (respec) na Árvore | Terra revolvendo, raízes recolhendo (rangido desacelerando) e arpejo de sininhos "de volta ao início" em ~1,2 s. Pico −8 dBFS. Bus UI. |
| milestone | milestone_1.ogg | 0,73 s | não | Marco/desafio alcançado (aviso da Dona Ceifa) | Toque de madeira + três sinos subindo (Mi–Lá–Dó♯). Pico −10 dBFS. Bus UI. |
| helper_mole | helper_mole_1..3.ogg | 0,25–0,26 s | não | Toupeira Tita cavando (cada ação dela) | 3–4 arranhões rápidos + torrões. Pico −13 dBFS, RMS −35 (bem abaixo do golpe do jogador). Pitch ±6%; máx. 2 vozes. |
| helper_cat | helper_cat_1..2.ogg | 0,42 / 0,28 s | não | Gato Breu age (ex.: acha algo); cooldown ≥ 4 s para não cansar | 1 = "miau", 2 = "mrrp" (trinado). Pico −20 dBFS. Pitch ±6%. |
| dialog_blip | dialog_blip_1..3.ogg | 0,06 s | não | Balão de diálogo, voz genérica (personagens sem voz própria, ex.: Seu Damião): 1 blip a cada 2–3 caracteres revelados | Sílaba curta "a/é/ó" (vogal sintetizada). Pico −19 dBFS. Sortear variação + ±6%; 1 voz por falante (cortar o anterior). Bus UI. |
| dialog_blip_ossada | dialog_blip_ossada_1..3.ogg | 0,06 s | não | Voz da **Madame Ossada** (mesma regra do `dialog_blip`) | Voz média "ó/a/u" + toque oco de osso. Pico −19 dBFS. |
| dialog_blip_ceifa | dialog_blip_ceifa_1..3.ogg | 0,08 s | não | Voz da **Dona Ceifa** | Grave, soprada e cansada. Pico −19 dBFS. |
| dialog_blip_tiao | dialog_blip_tiao_1..3.ogg | 0,04 s | não | Voz do **Tião, o Corvo** | Aguda, anasalada e áspera (grasnadinho). Pico −19 dBFS. |
| dialog_blip_mascate | dialog_blip_mascate_1..3.ogg | 0,06 s | não | Voz do **Mascate** | Média, anasalada, subindo (jeito de vendedor). Pico −19 dBFS. |
| unrest_warning | unrest_warning_1..2.ogg | 1,59 s | não | "A terra treme": aviso de Inquietação alta (ex.: ao cruzar 90%) ou evento que sacode o campo; junto com o tremor de tela | Rumor grave tremido + 3 baques subgraves + pedrinhas chacoalhando. Pico −6 dBFS. Bus SFX. |
| build_complete | build_complete_1..2.ogg | 1,52–1,54 s | não | Construção restaurada no hub | 3 marteladas, a peça assenta, acorde de sinos em Lá maior (1 sobe, 2 desce) + faíscas, com capela. Pico −7 dBFS. |

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

### Jogo completo — onde cada som entra (leva 3)
| Momento | Música | SFX |
|---|---|---|
| Turno no estágio N | `mus_area1` … `mus_area5` (loop) + `amb_night` | golpe pelo material do tile: `dig_grass/dirt/clay/coffin/rock` (est. 1), `dig_mud` (2), `dig_stone` (3), `dig_marble` (4), `dig_mist` (5); camada Ossada = `dig_bone` |
| Ativos | — | `stomp` (Pisão), `flare` (Clarão) |
| Tabuleiro vivo | — | `tombstone_effect`, `chest_open`, `coin_gold`, `bone_rain`, `soul_wander` (recorrente), ajudantes `helper_mole` / `helper_cat` |
| Inquietação alta | — | `unrest_warning` (+ tremor de tela) |
| Noite do Chefe | `mus_boss` no lugar do `mus_areaN` (crossfade ~1 s) | 1ª aparição: `stinger_boss_appear` + `boss_emerge`; depois `boss_sink` / `boss_emerge` a cada salto; golpe nele = `boss_hit` |
| Chefe derrotado | fade-out da `mus_boss` (0,3 s) → `jingle_boss_win` | `boss_defeat` (o jingle entra ~0,3 s depois) |
| Novo estágio liberado | `stinger_stage_unlock` | — |
| Epitáfios | (música da noite segue; ducking leve opcional na lendária) | `card_flip` ×3 (ou `card_legendary` na lendária), `card_pick` ao escolher; fala da Ossada = `dialog_blip_ossada` |
| Diálogos em balão | — | `dialog_blip_<personagem>` (ossada, ceifa, tiao, mascate) ou `dialog_blip` genérico |
| Hub / Árvore | `mus_tree` | `build_complete` (construção restaurada), `seal` (raiz selada), `respec` (Replantar), `milestone` (marco) |
| Loja do Mascate | `mus_shop` enquanto aberta (crossfade ~0,5 s com a do hub) | `shop_bell` ao abrir, `shop_buy`, `shop_deny` |
| Final | `mus_ending` (sem loop, 78,7 s) → créditos | — |

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
| mus_boss | −14,0 | −1,4 | −10,4 | 0 ms | percentil 21,5 — sem clique (ΔRMS −10,8 dB: o loop começa no surdo do tempo 1) |
| mus_area2 | −14,0 | −3,5 | −12,1 | 0 ms | percentil 42,6, ΔRMS −3,9 dB — sem clique |
| mus_area3 | −14,0 | −1,5 | −10,3 | 0 ms | percentil 22,4, ΔRMS −1,7 dB — sem clique |
| mus_area4 | −14,2 | −2,0 | −9,3 | 0 ms | percentil 23,2 — sem clique (ΔRMS −8,4 dB: ataque do cravo no tempo 1) |
| mus_area5 | −14,0 | −1,4 | −10,7 | 0 ms | percentil 44,9, ΔRMS −2,3 dB — sem clique |
| mus_shop | −14,0 | −2,6 | −11,9 | 0 ms | percentil 16,0 — sem clique (ΔRMS −17,4 dB: zabumba + violão no tempo 1) |
| mus_ending | −14,0 | −1,6 | −11,4 | 4,7 ms | — (sem loop) |
| jingle_boss_win | −14,9 | −3,0 | −13,1 | 0 ms | — |
| stinger_boss_appear | −18,5 | −5,0 | −13,0 | 0 ms | — |
| stinger_stage_unlock | −16,4 | −5,0 | −16,3 | 0 ms | — |
| stomp | ≈ −24 (var. 2 curta*) | −3,9 a −4,2 | −10,7 a −11,7 | 0 ms | — |
| boss_defeat | −25,9 | −3,5 | −11,3 | 0 ms | — |
| boss_emerge | −24,9 / −26,4 | −4,8 / −5,0 | −13,2 / −14,3 | 0 ms | — |
| boss_sink | −21,7 / −22,4 | −6,0 / −6,1 | −13,5 / −13,9 | 0 ms | — |
| unrest_warning | −22,0 / −23,2 | −5,9 / −6,0 | −11,6 / −12,6 | 0 ms | — |
| boss_hit | curto* | −5,9 a −6,1 | −17,9 a −18,0 | 0 ms | — |
| chest_open | −23,7 / −23,8 | −6,0 | −17,0 / −17,2 | 0 ms | — |
| flare | −25,6 a −29,8 | −5,5 a −6,5 | −15,6 a −20,0 | 0 ms | — |
| dig_mud | curto* (var. 2: −28,5) | −6,8 a −7,2 | −18,8 a −19,9 | 0 ms | — |
| dig_marble | curto* | −7,1 a −8,4 | −19,0 a −22,0 | 0 ms | — |
| dig_stone | curto* | −7,0 a −7,6 | −22,4 a −23,1 | 0 ms | — |
| dig_bone | curto* | −7,1 a −7,5 | −23,5 a −25,1 | 0 ms | — |
| dig_mist | −24,3 a −28,5 | −8,9 a −10,5 | −20,0 a −23,6 | 0 ms | — |
| bone_rain | −25,9 / −27,4 | −7,0 / −7,1 | −19,1 / −20,4 | 0 ms | — |
| build_complete | −24,5 / −25,1 | −7,2 / −7,4 | −19,9 / −20,0 | 0 ms | — |
| card_legendary | −23,0 | −7,9 | −17,7 | 0 ms | — |
| respec | −23,7 / −23,8 | −8,0 / −8,2 | −16,8 / −16,9 | 0 ms | — |
| coin_gold | −24,0 a −24,2 | −8,4 a −9,0 | −19,0 a −19,2 | 0 ms | — |
| shop_buy | −24,5 a −27,0 | −9,4 a −9,8 | −21,9 a −22,7 | 0 ms | — |
| milestone | −21,5 | −9,9 | −18,0 | 0 ms | — |
| tombstone_effect | −23,9 a −24,5 | −9,8 a −10,4 | −18,9 a −19,2 | 0 ms | — |
| seal | −33,0 / −34,1 | −9,8 / −10,2 | −24,1 / −24,8 | 0 ms | — |
| card_pick | −26,3 / −26,4 | −10,7 / −11,0 | −20,1 / −20,4 | 0 ms | — |
| shop_bell | −25,7 / −27,2 | −12,2 / −12,5 | −21,0 / −21,3 | 0 ms | — |
| helper_mole | curto* | −13,2 a −13,6 | −34,7 a −35,9 | 0 ms | — |
| card_flip | curto* | −14,3 a −14,8 | −29,4 a −30,8 | 0,5 ms | — |
| shop_deny | curto* | −14,9 / −15,3 | −27,8 / −27,9 | 0 ms | — |
| dialog_blip (todos os 5 ids) | curto* | −18,7 a −19,5 | −30,3 a −36,2 | ≤ 0,3 ms | — |
| helper_cat | −28,5 / curto* | −19,9 / −20,0 | −23,3 / −25,3 | 0,6 ms | — |
| soul_wander | −30,3 / −30,5 | −19,9 / −20,0 | −26,8 / −27,2 | 2,2 ms | — |

\* "curto": abaixo de 400 ms o LUFS integrado (BS.1770) não é definido; use pico e RMS de 50 ms para comparar.
