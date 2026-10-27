# Dig Dig Graves — UI, UX e Animação

> Versão 1.0 · 26/10/2026 · Complementa o [01_GDD.md](01_GDD.md) (§15–16) e a [02_DIRECAO_DE_ARTE.md](02_DIRECAO_DE_ARTE.md) (§9–10).
> Motivo: o primeiro build jogável tinha texto ilegível, HUD solto no vazio, cena sem ambientação e nenhuma animação de interface. Este documento é a fonte da verdade para **como a interface se parece, se move e soa**. Nada na tela fica parado sem motivo.

---

## 1. Princípios

1. **Legível primeiro.** Todo texto em fonte pixel, sem suavização, sobre fundo de contraste garantido (painel ou contorno). Se precisa apertar os olhos, está errado.
2. **Tudo responde.** Cada interação tem retorno visual em ≤ 1 frame e sonoro: hover, clique, ganho de recurso, compra, abertura de painel.
3. **Aconchego vivo.** O mundo respira: velas tremulam, névoa passa, pétalas caem, vaga-lumes e fogos-fátuos flutuam. Movimento ambiente é lento e de baixo contraste para não competir com o gameplay.
4. **Diorama de brinquedo.** O campo é um bloco de terra iso apoiado no cenário, não um losango flutuando no preto.
5. **Pixel-perfect.** Animações de UI movem em pixels inteiros; escala por tween só em múltiplos que não criem mixels visíveis por mais de ~150 ms (pops rápidos são aceitos; nada fica escalado em repouso).
6. **Acessível.** A opção "reduzir movimento" corta escalas, tremores e partículas ambientes para 25%; "reduzir flashes" remove flashes.

## 2. Tipografia

| Uso | Fonte | Tamanho nativo | Cor |
|---|---|---|---|
| Números do HUD, títulos, botões | **m6x11** (Daniel Linssen) | 11 px de altura | 22 com contorno 01 de 1 px sobre o mundo; 22 sobre madeira |
| Texto corrido, descrições, rótulos | **m5x7** (Daniel Linssen) | 7 px | 01/18 sobre pergaminho; 22 sobre madeira |
| Números flutuantes | m6x11 | 11 px | Normal 22, crítico 26, Osso 21, Alma 30, perda de óleo 32 — sempre com contorno 01 |

- Fallback, se a licença/obtenção da m5x7/m6x11 falhar: fontes pixel OFL do Google Fonts com acentos PT-BR (ex.: *Pixelify Sans* para títulos e *Tiny5* para corpo), sempre no tamanho de grade nativo.
- Renderização: antialiasing desligado, hinting off, subpixel off, tamanho = múltiplo do tamanho nativo da fonte. Nenhuma fonte vetorial "lisa".
- Texto nunca direto sobre o campo ou o fundo sem contorno 01 de 1 px.
- Acentos e ç obrigatórios (PT-BR). Testar "ÇÃÕÉÊÍÓÚ ção ções".

## 3. Kit de UI (peças de arte)

| Peça | Descrição | Estados |
|---|---|---|
| Botão grande | Placa de madeira de caixão 9-slice (19/20, contorno 01, pregos 26), texto m6x11 | normal · hover (1 degrau mais claro + borda 26) · pressionado (desce 1 px, sombra some) · desabilitado (05/06, texto 05) |
| Botão pequeno/ícone | 20×20, mesmo material | idem |
| Plaqueta de HUD | Tábua de madeira 9-slice, cantos arredondados, 1 prego por ponta | — |
| Painel de pergaminho | Já existe (`panel_parchment`) | — |
| Tooltip | Pergaminho pequeno com "rabicho" apontando para o alvo | — |
| Selo/medalha de nível | Disco 24×24 de cobre com número m6x11 | normal · subindo (brilho varrendo) |
| Barras | Moldura existente + preenchimentos; ponta do preenchimento com 1 px de brilho 23 | óleo normal/alerta · XP · Inquietação |

## 4. HUD do Turno (640×360) — redesenho

```
┌──────────────────────────────────────────────────────────────────────┐
│ ╔══════════════════════╗        ╔═(Nv 4)═══════╗        ╔══════════╗ │
│ ║ ◉ 1.234  🦴 56  ✦ 3 ║        ║ ███████░░░ XP ║        ║ ☠ ▓▓▓░░ ║ │
│ ╚══════════════════════╝        ╚══════════════╝        ╚══════════╝ │
│                         (céu, lua, muro, ipê)                        │
│                      ◇◇◇ campo em bloco de terra ◇◇◇                 │
│                                                                      │
│               ╔══════════════════════════════════╗     ╔═══════════╗ │
│               ║ 🏮  ██████████████░░░░░░   12 s  ║     ║ PISÃO ■■□ ║ │
│               ╚══════════════════════════════════╝     ╚═══════════╝ │
└──────────────────────────────────────────────────────────────────────┘
```
- Margem de 6 px da borda; tudo em plaquetas de madeira. Nada flutua no vazio.
- **Recursos (topo esquerdo):** ícone 16 + número m6x11. Ao ganhar: número dá *pop* (deslocamento −2 px e volta, 120 ms) e pisca 26 por 1 frame; moedas/ossos/almas voam do tile até o ícone (curva, 400–600 ms, Direção de Arte §9.2) e o ícone "engole" com squash.
- **Nível (topo centro):** medalha de cobre com o número + barra de XP. Subir de nível: medalha pula (−4 px, 200 ms, ease-out-back), brilho varre a barra, texto "NÍVEL 5!" sobe e some.
- **Inquietação (topo direito):** ícone de caveirinha + barra 30/23. Acima de 80% a barra pulsa (1 Hz) e a caveira treme 1 px.
- **Lanterna (base centro, a barra mais importante):** lanterna 24×24 com chama animada (3 frames) + barra larga + segundos em m6x11. Abaixo de 25%: barra alterna 31/32 a 2 Hz, a chama treme, os segundos ficam 32 e um tique sonoro toca por segundo nos últimos 3 s.
- **Entrada/saída:** no início do turno as plaquetas de cima descem de −28 px e as de baixo sobem de +28 px (250 ms, ease-out-back, 40 ms de defasagem entre elas). No fim, o inverso.

## 5. Cena do Turno — ambientação

Camadas, de trás para frente:
1. **Céu** 02→03→04 com faixas em dithering xadrez nas transições; estrelas de 1 px que cintilam (2 frames, aleatório, lento).
2. **Lua cheia grande** (alto à esquerda, coerente com a luz NO) com halo em xadrez; nuvens finas passando devagar na frente (parallax, ~2 px/s).
3. **Fundo distante:** silhueta do muro caiado com portão, cruzes e o ipê-roxo, em tons 03/04 (decoração, luma ≤ 105).
4. **O campo como diorama:** o losango jogável fica sobre um **bloco de terra iso** — as duas faces visíveis (frente-esquerda e frente-direita) mostram os estratos do solo (grama 10/11 no topo, terra 14/15, barro 13, pedrinhas 06), sombreadas pela luz NO (face esquerda mais clara). Altura de ~24 px.
5. **Borda do campo:** cerquinha de ferro baixa em trechos, velas, crisântemos e tufos nas quinas; nada invade a grade jogável.
6. **Névoa** baixa em faixas de xadrez 04/05 atravessando devagar na frente do bloco.
7. **Vinheta** escura nos cantos (sprite dither, não shader de alfa).
- **Enquadramento:** a grade jogável fica centralizada no espaço livre entre as plaquetas de cima e de baixo do HUD, e **o HUD nunca cobre a grade**. Nos campos grandes (15×15 a 18×18), o bloco de terra e a decoração de borda podem ficar por trás das plaquetas de baixo; a altura visível do bloco pode encolher, nunca a grade. Sem zoom fracionário.
- Ambientes animados: chamas das velas (já existem), tufos de grama balançando com brisa (2 frames, ondas que atravessam o campo), fogos-fátuos ambientes fora da grade (só decorativos, mais escuros que os coletáveis).

### 5.1 Cursor e área
- **Pá:** sprite 24×24 (substitui o 16×16), leitura clara a 1×: lâmina larga de metal com reflexo do luar, cabo de madeira com fita, e um brilho âmbar da lanterna. Golpe pose a pose com antecipação, impacto (squash + 2 torrões saindo da lâmina) e volta.
- **Contorno da área:** só o **perímetro externo** em degraus iso (não a grade interna), 1 px em 25, com pulso para 26 no golpe e cantoneiras de 3 px nas 4 pontas do losango. Interior: nenhum traço (a luz da lanterna já mostra a área).

## 6. Catálogo de animações de interface ("juice")

Implementar como um sistema central de tweens (presets reutilizáveis); valores abaixo são o padrão.

| Evento | Animação | Duração / curva | Som |
|---|---|---|---|
| Hover em botão | sobe 1 px + borda 26 | 80 ms, ease-out | tique de madeira suave |
| Clique em botão | desce 1 px (squash) e volta com overshoot | 60 + 120 ms, back-out | "toc" |
| Abrir painel | escala 0,9→1,0 + fade + desliza 6 px | 180 ms, back-out | papel/madeira |
| Fechar painel | 1,0→0,95 + fade | 120 ms, ease-in | — |
| Transição de tela | **cortina de terra**: torrões em xadrez caem de cima cobrindo a tela e escorrem para baixo revelando a próxima | 450 ms total | pá na terra |
| Contador (resumo, recursos) | conta de 0 até o valor, ticks sonoros | ease-out, máx. 1,2 s | tique por incremento (limitado a 20/s) |
| Lista do Resumo | linhas entram uma a uma vindo de −8 px | 120 ms de defasagem | tique |
| Tooltip | aparece após 150 ms, desliza 4 px para cima | 120 ms | — |
| Ganho de recurso | ícone voa ao HUD + pop do número | 400–600 ms | moeda/osso/alma |
| Nível | medalha pula + varredura de brilho + texto | 600 ms | sininho |
| Botão "chamando" (ex.: Cavar quando não há mais nada para comprar) | balanço ±1 px a cada 2 s | 300 ms | — |

## 7. Árvore de Raízes — versão aconchegante

Objetivo: a tela onde o jogador passa o tempo entre turnos deve ser **gostosa de olhar parada** e **recompensadora de clicar**.

### 7.1 Cena
- **Câmera:** arrastar com inércia; foco inicial no N00; rola suavemente até o nó comprado ou revelado. Limites para não se perder.
- **Superfície (topo):** céu com lua e estrelas cintilando; ipê-roxo com a copa balançando (2–3 frames lentos) e **pétalas caindo** (partículas 2–3 px em 04/05/08, zigue-zague) que pousam na grama; vaga-lumes (1 px 26/23 piscando) na grama.
- **Subsolo:** estratos com **partículas de poeira** subindo devagar; **bichinhos** ocasionais (minhoca atravessando um estrato, besourinho), raros e lentos; raízes finas decorativas de fundo em 13/14.
- **Luz:** um leve halo âmbar (xadrez) em volta dos nós comprados, como se as raízes brilhassem.

### 7.2 Raízes (conexões)
- Não compradas: 18/19, paradas.
- Compradas: 17/20 com **seiva luminosa** — pontos de 1–2 px em 26/23 viajando da raiz-mãe para os filhos (1 a cada ~1,5 s por conexão).
- Ao revelar filhos: a raiz **cresce** da origem até o filho (desenho progressivo, 350 ms, ease-out) soltando terrinha.

### 7.3 Medalhões
- Tamanho **32×32** (ícone 16×16 centralizado com moldura mais rica, raízes abraçando a borda), para ler bem na tela.
- Estados animados:
  - **Disponível e comprável:** respira (halo pulsando, 1,2 s) e um brilhinho 23 cintila na moldura.
  - **Disponível sem dinheiro:** parado, custo em 32.
  - **Oculto:** silhueta com "?" que oscila levemente.
  - **Comprado parcial:** pips de nível abaixo; o último pip preenchido brilha.
  - **Máximo:** moldura dourada com estrela cintilando (loop lento).
- **Hover:** sobe 2 px, pop rápido (1,0→1,1→1,0 em 140 ms), tooltip/painel atualiza.
- **Compra:** squash no clique → explosão de pétalas e faíscas → pip enche com brilho → número de custo "voa" para o contador de Cobre (que diminui com contador animado) → som de raiz crescendo. Segurar para comprar repete com pops menores e pitch subindo levemente.
- **Novo nó revelado:** brota do chão (escala 0→1,15→1 + terrinha), com "!" piscando até o primeiro hover.

### 7.4 Painel de descrição
Pergaminho desliza de baixo (180 ms). Nome em m6x11, efeito em m5x7, linha "antes → depois" com a seta animada (anda 1 px em loop) e o valor novo em 26. Custo com ícone. Ao comprar, o painel dá um *pop* e o "antes" atualiza com contador.

### 7.5 Som
Ambiente noturno (grilos, vento leve, folhas), raiz crescendo, pop de nó, moedas, e a música do hub/árvore (§8).

## 8. Áudio — direção resumida (detalha GDD §17)

- **Estilo:** "seresta assombrada" lo-fi: violão de nylon dedilhado, caixinha de música, órgão de igreja suave, assovio, um pouco de reverb de capela. Andamento calmo (70–90 BPM), tonalidade menor com momentos maiores (aconchego).
- **Faixas (MVP):** tema da Árvore/Hub (loop ~2 min), tema da Área 1 (loop ~2 min, um pouco mais de pulso), jingle de Resumo do Turno (5–8 s), stinger de Cova Aberta (sino + coro curto, ~2 s), stinger de nível (~1 s).
- **SFX MVP:** golpe por material (grama, terra, barro, caixão, rocha) com 3–4 variações; quebra de camada; moeda/osso/alma coletados; fogo-fátuo; óleo acabando (tique + chama); UI (hover, clique, abrir/fechar painel, contador, compra de nó, raiz crescendo, revelar nó); ambiente noturno em loop (grilos, vento).
- **Mixagem:** buses Master/Music/SFX/UI/Ambience; música −14 LUFS aprox., SFX nunca estourando; variação de pitch ±6% e limite de 6 vozes por SFX repetitivo (GDD §17). Formato OGG Vorbis; loops com pontos de loop sem clique.

## 9. Tela-título e menu principal

Primeira impressão do jogo e a imagem da página da Steam: tem que contar a premissa sem texto. **As almas fazem fila esperando cova, e o coveiro descansa ao lado da lanterna antes do turno.**

### 9.1 Composição (640×360; o mundo tem 640×600 para a câmera descer do céu)
De trás para frente:
1. **Céu** com lua cheia grande (alto à esquerda, luz NO), estrelas cintilando e nuvens finas em parallax.
2. **Vila do Bom Descanso** ao longe, numa colina: casinhas e a torre da igreja em 03/04, com **janelas acesas** em 25/26 (emissivas) que acendem e apagam de vez em quando.
3. **A fila das almas:** uma fileira de alminhas de 8×10 (30/23) andando devagar por uma trilha sinuosa da vila até o portão do cemitério. Elas aparecem, andam e somem no portão, em loop. É a premissa do jogo numa imagem.
4. **Muro caiado com o portão de ferro** em arabescos, cruzes e lápides entre o muro e o primeiro plano.
5. **Primeiro plano:**
   - à direita, o **ipê-roxo** grande com pétalas caindo;
   - à esquerda, um **monte de terra recém-cavada** com o **Coveiro sentado** (chapéu de palha furado, idle respirando, às vezes coça a cabeça ou boceja), a **lanterna** no chão iluminando o lugar e a **pá** cravada no monte;
   - **Tião, o Corvo**, numa lápide perto dele (pisca, inclina a cabeça, de vez em quando dá um pulinho e grasna).
6. **Névoa** baixa atravessando, **vaga-lumes** e a vinheta.

### 9.2 Logo
"DIG DIG GRAVES" em **letras de pedra** (07/08 com sombra 05/06 e contorno 01), com **terra (15/16) escorrendo** do topo das letras e uma **pá cravada no segundo "G"** de GRAVES. Abaixo, o subtítulo pequeno em m5x7: "Cava Cava Covas". Ocupa ~1/3 da largura e fica no terço superior, sobre o céu.

### 9.3 Sequência de abertura (pular com qualquer tecla ou clique)
1. Tela preta → fade para o céu com a lua (0,6 s).
2. A câmera **desce** do céu até o enquadramento final (2,0 s, ease-in-out), com parallax entre as camadas.
3. As **letras do logo caem** uma a uma (40 ms entre letras, cada uma com squash ao pousar e uma nuvem de poeira), e por último a **pá crava no G** com um "tunc", tremor de 1 px e terrinha caindo.
4. O menu entra (os botões sobem escalonados, 60 ms).
Na volta ao título vindo do jogo, entra direto no enquadramento final, com o logo já montado.
- **Logo ocioso:** a terra goteja de vez em quando (1 gota que cai e some) e a pá balança 1 px depois de cada gota.

### 9.4 Menu
- Botões grandes de madeira (kit de UI), empilhados à direita do centro, sem cobrir o Coveiro nem o logo: **Continuar** (só existe com save; vira o botão em foco), **Novo Jogo**, **Opções**, **Créditos**, **Sair**.
- **Cursor de seleção:** um fogo-fátuo que flutua ao lado do botão em foco e desliza até o próximo quando o foco muda. Funciona igual com mouse, teclado e gamepad.
- O botão em foco ganha um leve calor da lanterna (borda 26), e a descrição em m5x7 aparece embaixo (ex.: "Noite 7 · 1.234 ◉").
- **Novo Jogo com save existente** abre a confirmação num painel de pedra em forma de lápide (9-slice em 06/07/08): "Enterrar o progresso atual?", com os botões "Enterrar", em cor de perigo 31/32, e "Voltar". O foco começa em "Voltar".
- **Ao começar ou continuar:** o Coveiro se levanta, pega a pá e a lanterna, e a cortina de terra leva ao jogo (Continuar vai para a Árvore; Novo Jogo, para o 1º turno).
- **Opções** reaproveita o menu de opções do jogo. **Créditos** é um pergaminho rolando devagar, com equipe, fontes (m5x7/m6x11 de Daniel Linssen) e as ferramentas usadas.
- **Rodapé:** versão em m5x7 05 no canto inferior direito.
- **Pausa no jogo:** ganha "Voltar ao título".

### 9.5 Som
Música própria `mus_title`, o tema principal do jogo e a melodia que as outras faixas citam. Ela começa já no fade. O pouso de cada letra tem um som leve; a pá no G tem um "tunc" com reverb. O ambiente noturno fica por baixo. As alminhas na fila têm um coro baixinho e distante que vai e volta.

### 9.6 Contrato de produção (ids, caminhos e enquadramento)
Coordenadas em pixels da tela **no enquadramento final** (640×360). Na abertura, a câmera começa 240 px acima: cada camada é desenhada deslocada para baixo em `240 × (1 − p) × fator` (p = progresso 0→1 da descida, ease-in-out), com o **fator de parallax** abaixo. O valor exato de cada posição é o que o `pixel-artist` registrar no `assets/MANIFEST.md`; os números daqui são o alvo.

**Layout-alvo do enquadramento final**
| Elemento | Região-alvo | Observação |
|---|---|---|
| Lua | centro ≈ (96, 64), r ≈ 26–30 | Alto à esquerda |
| Logo | x ≈ 214–426, y ≈ 18–104 (≈ 1/3 da largura, centralizado) | 2 linhas: "DIG DIG" / "GRAVES" |
| Vila na colina | horizonte em y ≈ 190–230 | Janelas acesas 25/26 |
| Muro + portão | base do muro em y ≈ 262; portão em x ≈ 250–300 | As almas somem no portão |
| Botões do menu | coluna x ≈ 372–476, a partir de y ≈ 168, passo 28 | `btn_grande` em 9-slice, largura 104 |
| Monte + Coveiro | monte em x ≈ 40–150, chão em y ≈ 334 | À esquerda |
| Tião | lápide perto do monte, x ≈ 150–175 | — |
| Ipê-roxo | x ≈ 520–640, sai da borda direita | Copa com pétalas |
| Versão | canto inferior direito, m5x7 em 05 | — |

**Camadas (pixel-artist "cenário e logo") — `assets/sprites/bg/title/` e `assets/ui/title/`**
| id | Tamanho | Fator | Conteúdo |
|---|---|---|---|
| `title_sky` | 640×600 (desenhado em y = −240 no final) | 0,25 | Céu 02→03→04 em dither, lua cheia grande, estrelas fixas. Estrelas que cintilam e nuvens reaproveitam `bg_a1_stars` e `bg_a1_clouds` |
| `title_village` | 640×H | 0,5 | Colina com casinhas, torre da igreja e a trilha sinuosa até o portão; janelas apagadas na base |
| `title_windows` | célula pequena, 2 frames | 0,5 | Janela apagada/acesa; posições das janelas listadas no manifesto |
| `title_wall` | 640×H | 0,8 | Muro caiado, portão de ferro com arabescos, cruzes e lápides |
| `title_fg` | 640×H | 1,0 | Chão do primeiro plano, monte de terra recém-cavada (sem pá), lápide do Tião, ipê-roxo (tronco e copa; copa com 2–3 frames de idle opcional) |
| `title_logo` | atlas de letras | 1,0 (fixo na tela) | 12 letras separadas (D I G D I G G R A V E S) com terra escorrendo, posição final de cada letra no manifesto; `title_logo_shovel` (pá que crava no 2º G de GRAVES); `title_logo_drip` (gota, 3–4 frames) |
| `panel_stone` | 9-slice | — | Painel de pedra em lápide (06/07/08, contorno 01, topo arredondado) para a confirmação |
| `btn_perigo` | 4 estados, como `btn_grande` | — | Botão de perigo 31/32 ("Enterrar") |
| `scroll_ends` | — | — | Rolos de pergaminho (topo/base) para os Créditos, em volta de `panel_parchment` |

O manifesto também registra a **trilha das almas** (polilinha em coordenadas de tela, da vila até o portão), o ponto do monte onde o Coveiro senta, o ponto da lápide do Tião e onde ficam a pá cravada e a lanterna no chão.
Reaproveitados: `fogo_fatuo` (cursor do menu), `fx_tree_petals` (pétalas), `fx_tree_firefly` (vaga-lumes), `nevoa_a1`, `vinheta`, `dust` (pouso das letras), `torroes` (terrinha da pá).

**Personagens (pixel-artist "personagens") — `assets/sprites/chars/title/`**
| id | Frame | Pivô | Tags |
|---|---|---|---|
| `coveiro_title` | 32×32 | base (16, 31) | `idle` (respirar, 6 fps, loop) · `scratch` (coçar a cabeça) · `yawn` (bocejo) · `stand` (levanta, pega a pá e a lanterna, segura o último frame) |
| `pa_cravada` | — | base | Pá cravada no monte; some quando o `stand` a pega |
| `lanterna_chao` | — | base | `idle` 3 frames, 8 fps; halo em xadrez em sprite separado (`lanterna_chao_halo`); some no `stand` |
| `tiao` | 16×16 | base (8, 15) | `idle` (piscar) · `tilt` (inclina a cabeça) · `hop` (pulinho) · `caw` (grasna); moeda de cobre no bico |
| `alma_fila` | 8×10 (+ folga) | base | `walk` (flutua andando, 4 frames, 6–8 fps, loop) · `vanish` (some em xadrez no portão, 3 frames) |

**Som (sound-designer)**: `mus_title` (tema principal, loop), `logo_land` (3–4 variações), `logo_thunk` (pá no G, com reverb), `logo_drip`, `amb_souls_choir` (coro distante em loop, vai e volta), `ui_wisp_slide` (cursor deslizando), `ui_bury` (confirmar "Enterrar").

**Montagem (godot-dev)**: `scenes/title/` (cena `title_screen.tscn`). O `boot` passa a abrir o título. Enquanto um asset não estiver no manifesto, usa placeholder (ou silêncio).
