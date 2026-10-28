# Dig Dig Graves — UI, UX e Animação

> Versão 2.0 · 27/10/2026 (Parte 2: telas do v1.0, §10–§20) · Complementa o [01_GDD.md](01_GDD.md) (§15–16) e a [02_DIRECAO_DE_ARTE.md](02_DIRECAO_DE_ARTE.md) (§9–10).
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

> **Revisão 1.1 (fundo):** o céu com lua, nuvens, vila e muro distante saiu do Turno. O fundo do Turno agora é uma **clareira de cemitério dentro de uma mata escura, à noite**, vista no mesmo ângulo iso do diorama: um chão grande e calmo, com poucos elementos bem desenhados nas bordas. O fundo não compete com o diorama: é escuro, de baixo contraste e quase sem animação. O céu, a lua e a vila continuam na tela-título (§9).

Camadas, de trás para frente:
1. **Chão da clareira** (`bg_a1_chao`): cor-base escura e lisa (grama-funda 09 / sombra 02–03), com textura mínima (poucos tufos 1–2 px em 10, manchas de terra 13/14, folhas caídas), trilhas de terra batida que somem embaixo do diorama. Sem céu e sem horizonte: o chão ocupa a tela inteira.
2. **Elementos do cemitério no chão** (`bg_a1_props`): poucos e espaçados, sempre fora do miolo da tela. Uma **cerquinha de ferro baixa** em diagonal iso cortando um canto, 4–6 **lápides e cruzes** tortas de tipos variados, um túmulo com cercadinho, um ou dois grupos de velas (as únicas luzes quentes do fundo, em halo xadrez discreto), arbustos e crisântemos murchos. Todos em tons de decoração (luma ≤ 105 da DA §3.2, exceto as chamas; lápides em 03–05, sem 06) e sombra projetada sólida 01/02.
3. **Mata escura** (`bg_a1_mata`): moldura de copas e troncos nas bordas e nos cantos (topo e laterais, mais densa nos cantos de cima), em 01/02/09 com recorte de luar 03/04/10 só no lado NO de cada copa. Silhuetas bem desenhadas (folhagem em cachos, troncos tortos, 1–2 árvores secas com galhos), não um borrão. Balanço lento opcional nas copas (2 frames).
4. **O campo como diorama:** o losango jogável fica sobre um **bloco de terra iso** — as duas faces visíveis (frente-esquerda e frente-direita) mostram os estratos do solo (grama 10/11 no topo, terra 14/15, barro 13, pedrinhas 06), sombreadas pela luz NO (face esquerda mais clara). Altura de ~24 px.
5. **Borda do campo:** cerquinha de ferro baixa em trechos, velas, crisântemos e tufos nas quinas; nada invade a grade jogável.
6. **Névoa** baixa em faixas de xadrez 04/05 atravessando devagar na frente do bloco.
7. **Vinheta** escura nos cantos (sprite dither, não shader de alfa).
- **Enquadramento:** a grade jogável fica centralizada no espaço livre entre as plaquetas de cima e de baixo do HUD, e **o HUD nunca cobre a grade**. Nos campos grandes (15×15 a 18×18), o bloco de terra e a decoração de borda podem ficar por trás das plaquetas de baixo; a altura visível do bloco pode encolher, nunca a grade. Sem zoom fracionário.
- Ambientes animados: chamas das velas (já existem), tufos de grama balançando com brisa (2 frames, ondas que atravessam o campo), fogos-fátuos ambientes fora da grade (só decorativos, mais escuros que os coletáveis).

### 5.1 Cursor e área
- **Pá:** sprite 24×24 (substitui o 16×16), leitura clara a 1×: lâmina larga de metal com reflexo do luar, cabo de madeira com fita, e um brilho âmbar da lanterna. Golpe pose a pose com antecipação, impacto (squash + 2 torrões saindo da lâmina) e volta.
- A ponta da pá acompanha a posição livre do mouse; a arte não salta entre centros da grade. O tile mais próximo define a âncora da área de dano. Fora do campo, a pá ainda segue o ponteiro e nenhum tile recebe dano; entre covas, o alvo continua sendo o tile mais próximo.
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


---

# Parte 2 · Telas do v1.0 (GDD 2.0)

> Acrescentado em 27/10/2026 junto com o GDD 2.0. Vale tudo da Parte 1 (§1–§9): fontes, kit de madeira/pergaminho/pedra, catálogo de juice (§6), cortina de terra, "reduzir movimento"/"reduzir flashes". Ids de som citados estão no `assets/AUDIO_MANIFEST.md` ou na lista de ids novos do [06_PLANO_V1.md](06_PLANO_V1.md) §8 (marcados com \*). Ids de arte novos: DA §13. A letra entre colchetes diz em que marco a tela entra: [A], [B], [C], [D].

## 10. Pátio de navegação na superfície da Árvore [A estrutura · B construções]

### 10.1 Mundo e câmera
- A cena da Árvore passa a ter um **mundo de 1936×1024** (GDD §6.1). **Superfície = y 0–176**; a grama fica em y = 176 e as raízes começam embaixo. A vista é 640×360.
- **Câmera inicial:** x = 648, y = 0 (ipê no centro da tela, superfície inteira visível e o N00 aparecendo embaixo). Arrastar com inércia nos 2 eixos; roda = vertical, Shift+roda = horizontal; **Home** volta para essa posição.
- **Parallax:** céu (`tree_sky_wide`) a 0,5 na horizontal e na vertical; estrelas cintilando; vila distante (`hub_village`) a 0,7; superfície e raízes a 1,0.
- Ambiente: `amb_night` + `mus_tree`; pétalas do ipê, vaga-lumes e fumaça da chaminé da Casa quando restaurada.

### 10.2 Composição da superfície (x = centro da base, y da base = 172)
```
x:  150      290      430      580      760        968        1120      1260    1390    1530    1680    1820
   Jazigo   Portão   Casa do  Capelinha Barraca   IPÊ-ROXO   Pátio   Poço    Canteiro Torre  Galinheiro Coreto
   [D]      [B]      Coveiro  [B]      Mascate   (N00 embaixo) [A]    [C]     [C]     [C]     [D]     [D]
                     [B]               [B]
```
- Cada construção: sprite com estados **ruína** (05/06, mato, tábuas caídas) e **restaurada** (cores cheias, 1 luz quente); tamanho 48–96 px (DA §13). Antes de liberada, a ruína aparece **escurecida** (1 degrau abaixo) com cadeado 8×8; liberada e sem dinheiro, ruína normal com o custo em 32; liberada e comprável, a ruína **respira** (halo 26 pulsando 1,2 s, igual ao medalhão comprável).
- **Hover:** sobe 1 px, contorno 26, tooltip de pergaminho com nome, efeito, custo e "Clique para restaurar".
- **Clique** → **painel de obra** (pergaminho 200×110, ancorado acima da construção): nome m6x11, desenho da versão restaurada em miniatura (o próprio sprite), efeito em m5x7, custo com ícones, botões "Restaurar" e "Agora não". Sem dinheiro: "Restaurar" desabilitado e o que falta em 32.
- **Restaurar:** a câmera centraliza a construção (300 ms) → nuvem de poeira cobre (`dust`, 3 frames) → 3 marteladas com tremor de 1 px (`build_complete`) → troca para o sprite restaurado com pop (1,0→1,1→1,0, 160 ms) e faíscas 26 → texto do bônus sobe ("+10% de Cobre") → autosave.
- **Personagens na superfície:** Tião junto à estação Próxima Noite (idle do título); Mascate na Barraca (`mascate` idle/`wave` quando o cursor passa); Madame Ossada na porta da Capelinha (B, após a Capelinha); Seu Damião sentado no Poço (C); Dona Ceifa só aparece em falas e no final. Clicar num personagem = 1 balão curto de dica (§14, sem pausa).

#### 10.3 Pátio de navegação [A]
A superfície funciona como um hall integrado ao cenário da Árvore, sem um painel central de seleção de cinco lanternas. A tela inicial da Árvore apresenta quatro destinos em cartões/estações ancorados visualmente ao chão:
- **Árvore de Raízes — Talentos:** abre a vista navegável dos nós; botão “Pátio” retorna à superfície.
- **Próxima Noite — Paróquia:** inicia o estágio 1 em um clique. A seleção de estágio aparece nesse destino quando houver mais de um estágio jogável; no Marco A há apenas a Paróquia.
- **Barraca — Loja:** visível bloqueada até a liberação do Capítulo 1 (marco B).
- **Jardim — Fazenda:** visível como destino futuro, bloqueado até sua implementação.
A carteira permanece no canto superior esquerdo. Os destinos bloqueados comunicam disponibilidade futura sem parecerem botões quebrados. O título do espaço é “Pátio do Bom Descanso”; “Cemitério do Bom Descanso” continua sendo o nome do local na narrativa.
Ao retornar ao Pátio, o painel de detalhes do último nó selecionado desaparece; ele volta a aparecer ao abrir as Raízes.
As quatro estações ficam reunidas numa moldura de pergaminho sobre a cena, que separa título e destinos das raízes e do solo e mantém contraste legível; ela não funciona como seletor de estágios.

### 10.4 Noite do Chefe [A]
Quando a Inquietação do estágio atual chega a 100%, aparece na estação Próxima Noite a ação secundária **Enfrentar o Caixão Fujão**. Mantém a entrada com cortina de terra, feedback sonoro e atalho F/Y. No retorno da vitória, a chave é celebrada no pátio e segue para o encerramento do capítulo; não existe animação de desbloqueio de lanterna em um painel.

### 10.5 Navegação e acessibilidade
- O fluxo é Título/Resumo → Pátio; Pátio → Raízes ou Próxima Noite; Árvore → Pátio pelo botão fixo “Pátio”.
- “Próxima Noite” inicia a noite em uma ação, sem exigir a visita a outro painel.
- Home volta ao enquadramento do ipê e do Pátio. A câmera continua arrastável na tela da Árvore.
- Opções e carteira permanecem acessíveis. Destinos bloqueados têm rótulo explícito e estado desabilitado.
## 11. Loja do Mascate [B]

### 11.1 Layout (overlay sobre o hub, 640×360)
```
┌──────────────────────────────────────────────────────────────────────┐
│ ╔═[retrato 48]═╗  ╔═══════════ PRATELEIRA (madeira) ═══════════════╗ │
│ ║  Mascate     ║  ║ [PÁS]  [AMULETOS]   (abas)                    ║ │
│ ║ "Freguês! Pá ║  ║ ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐                  ║ │
│ ║  boa não     ║  ║ │24││24││24││24││24││24││24│   (até 7 por linha║ │
│ ║  quebra."    ║  ║ └──┘└──┘└──┘└──┘└──┘└──┘└──┘    2 linhas)     ║ │
│ ╚══════════════╝  ║ ┌──┐┌──┐ …                                    ║ │
│                   ╚═══════════════════════════════════════════════╝ │
│ ╔═══ PERGAMINHO: item em foco ═══════════════╗ ╔═ EQUIPADO ════════╗ │
│ ║ Dentadura de Ouro            300 🦴         ║ ║ Pá: [■]           ║ │
│ ║ +12% de Cobre                               ║ ║ Amuletos: [■][■]  ║ │
│ ║ [ Comprar ]  [ Equipar ]                    ║ ║  [🔒][🔒]          ║ │
│ ╚═════════════════════════════════════════════╝ ╚═══════════════════╝ │
│                                      [ Voltar (Esc) ]                │
└──────────────────────────────────────────────────────────────────────┘
```
- **Retrato** 48×48 (`portrait_mascate`, tag `talk` enquanto o texto escreve) num quadro de madeira; balão com frase do Mascate (rotativa, ~12 frases; uma nova a cada compra).
- **Prateleira** (madeira `panel_wood` 9-slice, ~400×150): abas **Pás** e **Amuletos** (botão pequeno com ícone); cada item numa casa 24×24 (`shop_slot`) com o ícone 16×16 centralizado e o preço em m5x7 embaixo.
- **Pergaminho de detalhe** (`panel_parchment`, 300×58): nome m6x11, efeito m5x7, "antes → depois" do stat afetado quando houver (mesmo estilo do painel da Árvore, seta animada), preço com ícones, botões.
- **Equipado** (madeira, 150×58): 1 casa de pá + 4 casas de amuleto (as não liberadas com cadeado e "Vença a Raiz-Mãe" / "Restaure o Coreto" no tooltip).

### 11.2 Estados de um item
| Estado | Visual | Som ao clicar |
|---|---|---|
| À venda, comprável | Ícone cheio; casa respira (halo 26, 1,2 s); preço em 22 | `ui_click` |
| À venda, sem dinheiro | Ícone cheio; preço em 32 | `shop_deny` + casa balança ±1 px 2× |
| Trancado (estágio não liberado) | Silhueta 02 com "?" ; tooltip "Chega no ‹estágio›" | `shop_deny` |
| Comprado | Selo de cera 8×8 "✓" no canto; preço some | `ui_click` |
| Equipado | Moldura 26 e brilho varrendo 1× a cada 3 s | `ui_click` |
| Achado em baú | Como comprado, com fitinha 32 "achado" na 1ª vez | — |

### 11.3 Animações e sons
- **Abrir** (clique na Barraca ou no Mascate): `shop_bell` + crossfade `mus_tree` → `mus_shop` (0,5 s); o fundo escurece 2 degraus (vinheta); a prateleira desce de −20 px (180 ms, back-out), o retrato entra pela esquerda (−48 px, 220 ms) e o Mascate dá `wave`.
- **Hover em item:** sobe 1 px, pergaminho troca o conteúdo com contador nos números (120 ms).
- **Comprar:** squash da casa → o preço "voa" para a carteira (contador diminui) → `shop_buy` → selo de cera bate no canto (pop 1,0→1,2→1,0) → frase nova do Mascate; com "Equipar automático" (padrão) o item voa em arco para a 1ª casa livre (`shop_equip`\*).
- **Equipar/desequipar:** arrastar ou clicar; o item desliza em arco (220 ms) para a casa; trocar de pá = a pá velha volta à prateleira com o mesmo arco ao contrário.
- **Fechar:** inverso (120 ms), crossfade de volta para `mus_tree`.
- Teclado/gamepad: foco percorre a prateleira em grade; LB/RB trocam de aba; A compra/equipa; B fecha.

## 12. Escolha de Epitáfio [B]

### 12.1 Overlay (o jogo pausa)
```
┌──────────────────────────────────────────────────────────────────────┐
│                          NÍVEL 4!  (m6x11, 26)                       │
│        ┌────────┐        ┌────────┐        ┌────────┐               │
│        │  ╭──╮  │        │  ╭──╮  │        │  ╭──╮  │   lápides     │
│        │ título │        │ título │        │ título │   64×88       │
│        │ [32×32]│        │ [32×32]│        │ [32×32]│               │
│        │ texto  │        │ texto  │        │ texto  │               │
│        │ ◇ tags │        │ ◇ tags │        │ ◇ tags │               │
│        └───1────┘        └───2────┘        └───3────┘               │
│ ╔═[Madame Ossada 48]══ "As cartas não mentem… só exageram." ═══════╗ │
│ ╚══════════════════════════════════════  [Embaralhar (1) · Z] ═════╝ │
└──────────────────────────────────────────────────────────────────────┘
```
- O campo fica visível por baixo, escurecido 2 degraus (vinheta em xadrez, sem alfa); o HUD de cima continua visível.
- **Cartas** 64×88 (DA §10.4), espaçadas 32 px, centralizadas (4 cartas com S03/Óculos: espaço 16 px). Número da tecla embaixo de cada uma.
- **Madame Ossada** (retrato 48×48, `talk` enquanto escreve) num balão largo na base com uma frase por raridade mais alta da mão.

### 12.2 Animações
- **Entrada:** "NÍVEL N!" cai do topo (−20 px, 200 ms, back-out); as 3 lápides **brotam do chão** uma a uma (y +40 → 0, 220 ms, back-out, 90 ms de defasagem) com terrinha; cada uma vira de costas → frente (2 frames de "giro" pixelado) com `card_flip`; Lendária vira por último com brilho dourado varrendo e `card_legendary` (ducking leve da música).
- **Ocioso:** carta em foco sobe 3 px e respira; Raro tem 2 frames de cintilar ecto; Lendário 2 frames de ouro.
- **Escolher** (clique, 1/2/3/4, A): a carta escolhida dá pop e **voa em arco** até a fileira de Epitáfios do HUD (§13), virando um ícone 12×12; as outras afundam no chão (180 ms); `card_pick`; o jogo despausa com a cortina mais curta (vinheta some em 150 ms).
- **Embaralhar:** as 3 afundam, novas brotam; `card_reroll`\*; contador "(n)" diminui com pop.
- **Fila:** se houver outro nível pendente, o "NÍVEL N+1!" entra logo depois sem soltar a pausa.
- "Reduzir movimento": sem brotar/voar (fade de 120 ms).

## 13. HUD do turno v2 [A ativos · B Clarão e Epitáfios · A barra do chefe]

### 13.1 Wireframe (640×360)
```
┌──────────────────────────────────────────────────────────────────────┐
│ ╔══════════════════════╗   ╔═(Nv 4)══════════╗         ╔══════════╗ │
│ ║ ◉ 1.234  🦴 56  ✦ 3 ║   ║ ███████░░░ XP    ║ [B+]    ║ ☠ ▓▓▓░░ ║ │
│ ╚══════════════════════╝   ╚══════════════════╝         ╚══════════╝ │
│ ▫▫▫▫ (Epitáfios da noite, 12×12) [B]                                  │
│              ╔═[☠16] O CAIXÃO FUJÃO ════════════════════╗            │
│              ║ ██████████████████████░░░░░░  24.560     ║ (Noite do  │
│              ╚══════════════════════════════════════════╝  Chefe)    │
│                       ◇◇ campo em bloco de terra ◇◇                  │
│                                                                      │
│              ╔══════════════════════════════════╗  ╔═[Q]═╗ ╔═[E]═╗  │
│              ║ 🏮  ██████████████░░░░░░   12 s  ║  ║ 👢  ║ ║ ✷   ║  │
│              ╚══════════════════════════════════╝  ╚═pips╝ ╚═pips╝  │
└──────────────────────────────────────────────────────────────────────┘
```
- **Marco A:** sem a barra de XP (a medalha some) e sem a fileira de Epitáfios; o topo fica: recursos à esquerda, Inquietação à direita.
- **Ativos** (base direita): plaquetas 28×28 com ícone 20×20 (`hud_stomp`, `hud_flare`), tecla em m5x7 no topo da moldura e a **recarga** como 4 pips embaixo que enchem da esquerda para a direita (mais um "relógio" de escurecimento 03 descendo sobre o ícone).
  - **Pronto:** ícone aceso, borda 26 com brilho varrendo a cada 1,5 s, `stomp_ready`\* / `flare_ready`\* baixinho (desligável no volume de UI).
  - **Usado:** ícone afunda 1 px, flash 23 de 1 frame (sem flash com "reduzir flashes"), pips zeram.
  - **Sem óleo para o Clarão** (< 2 s): ícone em 05, recusa com `shop_deny`.
  - Pisão no campo: anel de impacto (`fx_stomp`, 4 frames) na área + tremor de 2 px + `stomp`; com Pisão Sísmico, um segundo anel 1 tile maior 60 ms depois.
  - Clarão: luz vai ao raio máximo com o anel em xadrez se expandindo (200 ms), tiles iluminados ganham uma borda 26 pulsando; `flare`. Ao acabar, a luz volta ao raio do óleo em 300 ms.
- **Fileira de Epitáfios** [B]: ícones 12×12 da carta, alinhados abaixo dos recursos, máx. 15; hover mostra o tooltip da carta; um número "×2" quando acumulado.
- **Inquietação:** ao passar de 80% a caveira treme; em 100% a barra fica cheia com brilho 32 varrendo e o rótulo "A terra treme…" pisca 3× ao chegar.
- **Tipos de lápide [A]:** passar o cursor sobre a lápide mostra no tooltip o nome e o efeito (Cova normal, +1 Alma ou Caixão 1,5× mais duro/Ossos ×2); as três colunas do sprite distinguem os tipos sem depender do texto.

### 13.2 Barra do chefe [A]
- Plaqueta larga (320×22) no topo central, **abaixo** da medalha de nível: ícone do chefe 16×16 (`icon_boss_*`), nome em m6x11, barra com moldura `barra_chefe` (preenchimento 31/32, ponta 23) e o HP em m5x7 à direita.
- **Entrada:** quando o chefe surge, a plaqueta desce de −28 px (300 ms) junto com `stinger_boss_appear`.
- **Dano:** a barra perde em 2 passos: um "fantasma" 22 fica por 400 ms e escorre até o valor real (estilo "dano atrasado"); pop de 1 px no ícone a cada golpe (limitado a 8/s); `boss_hit`.
- **Fase/marco do chefe** (bulbo morto, fase do mausoléu, camada da Cova): a barra pisca 26, traço vertical na posição e `boss_phase`\*.
- **Fuga** (óleo acabou): a barra se esvazia ao contrário ("ele recupera") enquanto o chefe some; `boss_flee`\*.
- **Vitória:** a barra estoura em faíscas; hit-stop 2 frames; `boss_defeat` → `jingle_boss_win`.

### 13.3 Pausa no turno
Painel de madeira: **Continuar · Opções · Abandonar a noite · Voltar ao título**. "Abandonar" e "Voltar ao título" abrem a confirmação de lápide (`panel_stone`, como no título): "Os ganhos desta noite serão perdidos." com "Abandonar" em `btn_perigo` e "Voltar" em foco.

## 14. Diálogo em balão com retrato [A]

### 14.1 Dois tamanhos
| Tipo | Uso | Pausa o jogo? | Layout |
|---|---|---|---|
| **Fala** (bloqueante) | Abertura/fim de capítulo, chefes, 1ª visita ao Mascate/Vidente, final | Sim | Faixa na base: retrato 48×48 num quadro de madeira à esquerda (ou à direita para o 2º personagem) + balão de pergaminho `balao` 9-slice de 480×56 com rabicho apontando o retrato; nome em m6x11 na borda do balão |
| **Dica** (não bloqueante) | Tião no 1º turno, 1ª cova, clique em personagem no hub | Não | Balão pequeno (máx. 160×32) com rabicho `balao_rabicho` apontando o personagem ou o elemento, some sozinho em 3,5 s ou no clique |

### 14.2 Texto e ritmo
- m5x7 em 01 sobre pergaminho; até 3 linhas de ~70 caracteres por balão.
- **Máquina de escrever:** 40 caracteres/s; o retrato fica em `talk` enquanto escreve e volta a `idle` no fim; voz `dialog_blip_<personagem>` a cada 2 caracteres visíveis (não em espaços e pontuação), pitch ±6%. Seu Damião: `dialog_blip_damiao`\* (até lá, `dialog_blip`).
- Clique/Espaço/A com o texto escrevendo = completa a linha; com o texto completo = próxima fala (`ui_click` suave). Indicador "▼" 26 balançando 1 px no canto quando dá para avançar.
- "Pular" (Esc/B segurado 0,5 s, com anel enchendo) pula a conversa inteira.

### 14.3 Animações
- **Entrar:** faixa sobe da base (+64 → 0, 220 ms, back-out); o retrato entra pelo lado com 2 px de overshoot. Troca de personagem: o retrato sai e o outro entra pelo lado oposto (140 ms).
- **Sair:** desce (140 ms, ease-in).
- O fundo escurece 1 degrau (vinheta) nas falas bloqueantes.

## 15. Resumo especial pós-chefe [A]

```
┌──────────────────────────────────────────────────────────────────────┐
│               O CAIXÃO FUJÃO DESCANSOU!    (m6x11, cai letra a letra) │
│                         ╔════════╗                                   │
│                         ║ 🗝 32×32║  ← Chave da Cripta I gira e pousa │
│                         ╚════════╝                                   │
│ ╔═══ PRÊMIOS (pergaminho) ═════════╗ ╔═══ O QUE SE ABRIU ══════════╗ │
│ ║ ✦ +25 Almas                      ║ ║ 🏮 Campo dos Indigentes      ║ │
│ ║ 🦴 +60 Ossos                     ║ ║ 🏪 O Mascate chegou          ║ │
│ ║ (+ ganhos normais da noite)      ║ ║ 🌱 20 raízes novas           ║ │
│ ╚══════════════════════════════════╝ ╚══════════════════════════════╝ │
│                    [ Ver o cemitério ▶ ]  (único botão)              │
└──────────────────────────────────────────────────────────────────────┘
```
- Entra depois do diálogo de vitória, com cortina de terra. Fundo do Resumo normal + raios de luz 26/23 em xadrez girando devagar atrás da Chave (sem com "reduzir movimento").
- **Sequência:** título cai letra a letra (30 ms) → a Chave sobe girando (4 frames de giro, 600 ms) e pousa com pop + `key_get`\* + `jingle_boss_win` (se ainda não tocou) → os prêmios contam (contador padrão) → "O que se abriu" entra linha a linha (−8 px, 120 ms de defasagem) com um ícone cada → o botão "chama" (balanço ±1 px).
- **Ver o cemitério ▶** leva ao Pátio; a revelação mostra a nova chave e as raízes brotando (`node_reveal`, máx. 6 visíveis animando, o resto aparece direto). Duração total ≤ 6 s; qualquer clique acelera para o fim.
- Builds A–C: depois da revelação entra o **Fim do Capítulo** (§19). Revanche vencida: Resumo normal com a linha "Revanche: +X Almas".
- Derrota na Noite do Chefe: Resumo normal com a faixa de pedra "O Caixão Fujão fugiu… faltaram 3.420 de vida" e o botão "Árvore" em foco.

## 16. Replantar (respec) [B]
- **Onde:** medalhão do N03 na Árvore (depois de comprado vira um botão de pá com raiz, sempre visível no centro) e atalho na Ficha do Coveiro.
- **Confirmação** em `panel_stone` (lápide 240×120): "Replantar a árvore?" · m5x7: "Todas as raízes voltam para o chão e você recebe de volta tudo o que gastou." · prévia com as 3 moedas que voltam (contadores) · custo do uso "5 ✦ × estágio" · botões **"Replantar"** (`btn_perigo`) e **"Voltar"** (foco).
- **Animação:** as raízes compradas **recolhem** de baixo para cima, das pontas para o N00 (desenho reverso da raiz, 600 ms no total, em ondas por linha), os medalhões viram semente (escala 1→0,6, 2 frames) e voltam ao estado disponível; as moedas sobem do solo e voam para a carteira; `respec`; selos das encruzilhadas se partem (`seal` ao contrário: 2 frames). Autosave.

## 17. Marcos (conquistas internas) [C]
- **Toast:** quando um marco completa (mesmo no turno), uma plaqueta de pergaminho 200×28 desce do topo central (−28 → 6 px, 220 ms, back-out), com o ícone 16×16 do marco, o nome em m6x11 e o prêmio em m5x7; fica 2,5 s e sobe. `milestone`. Vários marcos = fila, 0,4 s entre eles. Não pausa o jogo.
- **Painel** (aberto pela plaqueta do Tião no hub): pergaminho grande 480×280 com o Tião no canto (retrato) e uma lista rolável de 20 linhas: ícone, nome, condição, **barra de progresso** (contador) e prêmio; concluídos com selo de cera e o prêmio riscado em 18 ("recebido"); a fileira das 5 Chaves no topo. Abrir/fechar como qualquer painel (§6).
- Hover numa linha: Tião comenta (dica curta).

## 18. Árvore v2: navegação e molduras [A]

### 18.1 Medalhões por tipo (DA §10.3)
| Tipo | Moldura | Leitura |
|---|---|---|
| P (passivo) | Medalhão 32×32 do ramo (já existe) | — |
| At (ativo) | Aro com 4 "raios" de luz 26 nas diagonais | "botão novo" |
| R (regra) | Aro rúnico (pontos 28 nas 8 direções) | "muda o jogo" |
| D (desbloqueio) | Aro com cadeado aberto 8×8 no topo | "coisa nova no campo" |
| X (encruzilhada) | Dois medalhões ligados por raiz em "Y"; ao comprar um, o outro vira **selado**: pedra 06/07 com raiz cortada e um "×" 8×8 | escolha |
| M (Raiz-mestra) | Medalhão grande 40×40 com raízes abraçando; antes de revelado, silhueta 40×40 com nome e custo no hover | objetivo distante |

- **Selado** ≠ **oculto** ≠ **sem dinheiro**: pedra fria, sem respirar, tooltip "Escolhida a outra raiz. Duas Raízes libera esta."
- Comprar Raiz-mestra: pop maior (1,0→1,25→1,0), 2 ondas de pétalas, tremor de 1 px, `seal` + `node_buy`; o custo das outras mestras atualiza com contador ("×3").

### 18.2 Navegação
- **Minimapa** 96×48 no canto inferior esquerdo (`minimap_frame`): faixas coloridas dos ramos presentes nas cores da DA §10.3, nós comprados como pontos acesos (mestras 2×2), retângulo da vista; clique/arraste move a câmera. O painel de descrição começa à direita do minimapa para manter ambos visíveis.
- **Atalhos 1–7** (E, L, S, N, F, C, A) e **LB/RB**: rolam até o topo do ramo (400 ms, ease-out) com o nome do ramo aparecendo 1 s no topo da tela.
- **Home / R3:** volta à câmera inicial (superfície).
- Painel de descrição, Ficha (Tab) e "Cavar ▶" como na Parte 1 (§7).

## 19. Fim de capítulo e final

### 19.1 "Fim do Capítulo N" [A, B, C]
- Depois da revelação do hub (§15): cortina → cartão de pergaminho 360×220 sobre o céu da Árvore: "FIM DO CAPÍTULO 1 · O Cemitério da Paróquia" (m6x11, cai letra a letra) · estatísticas (tempo de jogo, noites, covas, nós comprados, chefe vencido em N tentativas) contando · os estágios seguintes em silhueta com "Em breve" · botões **Continuar cavando** (foco) e **Créditos**. Música: `jingle_chapter_end`\* e depois `mus_tree` baixinho.
- Mostrado 1× por save (fica no painel de Marcos como "Capítulo 1 ✓").

### 19.2 Final [D]
Sequência (pular com Esc segurado 1 s; o pulo nunca pula os créditos na 1ª vez):
1. Vitória sobre a Cova da Dona Ceifa → diálogo final (6–8 falas, Dona Ceifa e Coveiro).
2. **Cena de encerramento** (`end_*`, 640×360, ~45 s, `mus_ending`): (a) a cova aberta no Jardim; Dona Ceifa tira os óculos, deita, ajeita a prancheta no peito (anim 6 frames); (b) ela estende a foice ao Coveiro, que larga a pá (a pá crava no chão como no título); (c) plano aberto: a fila de almas olha para o Coveiro; uma a uma sobem como na cova aberta; (d) **amanhece pela primeira vez**: o céu passa de 02/03 para 04/05 com o sol de 26/23 surgindo atrás das lápides (troca de paleta por passos de 300 ms, sem gradiente).
3. **Créditos:** pergaminho rolando devagar (reaproveita Créditos do título, §9.4), com os personagens passando na base (desfile 16 px, cada um com sua anim idle) e `credits_roll`\* (arranjo de `mus_title`) após `mus_ending`.
4. **Tela "Fim":** "FÉRIAS MERECIDAS" em letras de pedra (estilo do logo, 1 linha) + estatísticas + selo; botões **Continuar cavando** e **Voltar ao título**. O título passa a ter Dona Ceifa de chapéu de praia sentada no monte ao lado do Coveiro.

## 20. Fluxo completo de telas e transições

```
                        ┌───────────────── Opções / Créditos (painéis do título)
                        │
BOOT ─► TÍTULO ─Novo Jogo (Coveiro levanta)─► [cortina] ─► TURNO 1 ─┐
          │  └─Continuar (Coveiro levanta)──► [cortina] ─► ÁRVORE/HUB
          ▲                                                           │
          └──────── Pausa: Voltar ao título [cortina] ◄───────────────┤
                                                                       ▼
TURNO ─óleo/amanhecer─► "O ÓLEO ACABOU" 0,8 s ─► HUD sai ─► [cortina] ─► RESUMO
RESUMO ─[Árvore]──────► [cortina] ─► ÁRVORE/HUB (câmera na superfície)
       └[Mais uma noite]► [cortina] ─► TURNO (mesmo estágio)
PÁTIO ─[Próxima Noite]───────────────────► [cortina] ─► TURNO (estágio atual)
           ─[Enfrentar / F]─ vinheta 200 ms ► [cortina] ─► NOITE DO CHEFE
           ─[Barraca/Mascate]─► LOJA (overlay, sem trocar de cena; crossfade de música)
           ─[ruína]─► PAINEL DE OBRA (overlay) ─Restaurar─► animação na própria superfície
           ─[Tião]─► PAINEL DE MARCOS (overlay) · ─[Tab]─► FICHA · ─[N03]─► REPLANTAR (overlay)
           ─[Esc]─► PAUSA (Continuar / Opções / Voltar ao título)
NOITE DO CHEFE ─perdeu─► RESUMO (faixa "fugiu") ─► ÁRVORE/HUB (placa Enfrentar continua)
               └venceu─► hit-stop ─► DIÁLOGO (overlay no turno) ─► [cortina] ─► RESUMO ESPECIAL
RESUMO ESPECIAL ─[Ver o cemitério]─► [cortina] ─► ÁRVORE/HUB + REVELAÇÃO (≤ 6 s)
                                            └─(A–C, 1ª vez)─► FIM DO CAPÍTULO ─► Continuar cavando / Créditos
NOITE DO CHEFE 5 ─venceu─► DIÁLOGO FINAL ─► [fade preto 600 ms] ─► CENA FINAL ─► CRÉDITOS ─► "FIM"
"FIM" ─[Continuar cavando]─► [cortina] ─► ÁRVORE/HUB · ─[Voltar ao título]─► TÍTULO (Dona Ceifa de férias)
TURNO ─nível (B+)─► EPITÁFIO (overlay, pausa) ─escolheu─► TURNO
TURNO ─[Esc]─► PAUSA ─Abandonar a noite (confirmação)─► [cortina] ─► ÁRVORE/HUB (sem ganhos)
```
- **Cortina de terra** (450 ms, `screen_transition`) em toda troca de cena; overlays usam "abrir painel" (180 ms) e nunca a cortina.
- **Música entre telas:** título `mus_title` → turno `mus_areaN` (crossfade 1 s) → Resumo `jingle_summary` → Árvore/hub `mus_tree`; Loja `mus_shop`; Noite do Chefe `mus_boss`; final `mus_ending` → `credits_roll`\*.
- **Regra de 1 clique:** de qualquer Resumo ou da Árvore, um turno novo está a 1 clique; de qualquer overlay, Esc/B fecha e volta ao estado anterior.
- **Autosave:** fim de cada noite, compra de nó/item/construção, vitória sobre chefe, Replantar, a cada 60 s no hub.

## 21. Splash do estúdio (Briba Studio)
- Primeira coisa que o jogo mostra, antes da tela-título (§9). Fundo chapado 01, logo `briba_logo_anim` centralizado em escala 1× (canto em (268, 114)).
- Sequência: preto 0,2 s → fade-in 0,3 s com a tag `intro` (0,8 s) e o som `splash_briba` no primeiro frame → segura em `idle` até 1,8 s no total → fade para preto 0,3 s → título (o `mus_title` começa no fade do título, como hoje).
- Qualquer tecla, clique ou botão pula direto ao título. Só aparece ao abrir o jogo, nunca ao "Voltar ao título". O autopilot pula a splash.
- "Reduzir flashes" não muda nada (não há flash); "reduzir movimento" mantém a sequência (a animação é pequena).
