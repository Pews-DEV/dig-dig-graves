# Dig Dig Graves — Direção de Arte

> Versão 1.0 · 26/10/2026 · Complementa o [01_GDD.md](01_GDD.md).
> Este documento é a **fonte da verdade** para qualquer ilustração do jogo, feita à mão ou via ferramentas (Aseprite/MCP). Se um asset contradiz este documento, quem está errado é o asset.
> Paleta em arquivo: [palette/lua-de-cova-32.gpl](palette/lua-de-cova-32.gpl) (abre no Aseprite e no GIMP) e [palette/lua-de-cova-32.hex](palette/lua-de-cova-32.hex).

---

## 1. Conceito visual: "macabro aconchegante"

Um cemitério de interior brasileiro numa noite de lua cheia, visto como um diorama isométrico de brinquedo. É assustador como uma história contada à beira da fogueira: escuro, mas sempre com uma vela acesa por perto.

**Palavras-chave:** noite azul-índigo · luz quente de lanterna · terra fofa e úmida · velas de Finados · crisântemos · cruzes de madeira tortas · esqueletos fofos · almas que parecem chamas de vela azuis.

**Não é:** gore, sangue, terror realista, zumbis podres, "grimdark", roxo neon de Halloween genérico ou paleta saturada de mobile.

### 1.1 Pilares visuais
1. **O campo se lê em 1 segundo.** Em qualquer momento o jogador sabe, sem ler números, onde ainda há camada para cavar, onde está fundo e onde está a cova. Legibilidade vem antes de detalhe.
2. **Frio em volta, quente no cursor.** O mundo é azul-violeta (luar); o cursor é âmbar (lanterna). Recompensas (moedas, ouro, velas) são quentes; o sobrenatural (almas, ectoplasma) é ciano/menta.
3. **Fofura no macabro.** Personagens em proporção chibi (cabeça ≈ 1/2 do corpo), olhos de 1–2 px, cantos arredondados. Ossos são "ossinhos de desenho animado" (pontas em bolinha).
4. **Peso tátil.** Terra voa, torrões quicam, a pá "afunda" com squash. Tudo que é cavado tem massa.

### 1.2 Toque brasileiro (identidade)
Use em props e decoração, nunca como caricatura:
- Lápides com **foto oval** em porcelana; nomes com "Saudades eternas", "Aqui jaz".
- **Velas** brancas e coloridas em grupos, potes de vidro com vela de sete dias.
- **Crisântemos** e flores de plástico desbotadas, coroas de flores com fita.
- **Cruzes de madeira** pintadas de azul ou branco, cercadinhos de ferro em volta de túmulos.
- **Muro caiado** com reboco descascando, portão de ferro com arabescos.
- **Ipê-roxo** velho no centro do cemitério (é a árvore de habilidades).
- **Cata-ventos** coloridos em túmulos de criança (só como cor; sem destaque narrativo).

## 2. Especificações técnicas de pixel art

| Item | Regra |
|---|---|
| Resolução interna | **640×360**, escala inteira (2×, 3×, 4×, 6×). Nada é desenhado para outra resolução |
| Projeção | Isométrica 2:1 (linhas de 2 px na horizontal por 1 px na vertical, ≈26,57°) |
| Tile base | Losango de **32×16 px** |
| Pixel | 1 pixel do asset = 1 pixel da tela interna. **Proibido:** escalar sprites em engine (exceto inteiro, ex.: logo 2×), rotacionar sprites e "mixels" (pixels de tamanhos diferentes) |
| Anti-aliasing | Proibido na silhueta externa. Permitido AA interno manual (1 px) em sprites ≥ 32 px |
| Dithering | Só em fundos grandes (céu, névoa, gradiente da lua) e em xadrez 2 cores. Proibido em sprites < 32 px e em tiles |
| Gradientes | Proibidos. Volume é feito com 3–4 tons de uma rampa |
| Contorno | Ver §2.2 |
| Luz principal | **Lua, vindo do alto à esquerda** (NO). Lado esquerdo/topo = claro; lado direito/base = escuro |
| Luz secundária | Lanterna (cursor), quente, tratada por troca de rampa (§4) |
| Filtro de textura | Nearest, sem mipmaps (Godot: `default_texture_filter = Nearest`) |

### 2.1 Linhas isométricas
- Diagonais "iso" sempre em degraus de **2-2-2** px (nunca 2-1-3). As arestas do losango também.
- Arestas verticais (cantos de lápides, muros) são retas de 1 px.
- Curvas: degraus graduais (1, 2, 3…), sem "dentes" (1, 3, 1).

### 2.2 Contorno (outline)
| Elemento | Contorno |
|---|---|
| Personagens, ajudantes, chefes, props soltos (lápides, velas, baús), ícones | **Seletivo**: cor 01 `#0d0b14` na silhueta externa; no lado iluminado (topo/esquerda) o contorno pode virar o tom mais escuro da própria rampa |
| Tiles de solo | **Sem contorno.** A separação entre tiles vem da borda (cor `-borda`/`-clara`) e da sombra |
| UI (painéis, cartas, medalhões) | Contorno 01 completo de 1 px |
| Efeitos (poeira, almas, fogo-fátuo, números) | Sem contorno; brilho por cor clara no centro |
| Números flutuantes | Fonte com contorno de 1 px em 01 |

## 3. Paleta "Lua de Cova 32"

32 cores, **paleta fechada**: nenhum asset do jogo usa cor fora dela (o check está na §11). As cores estão organizadas em rampas; cada rampa vai do escuro ao claro.

| # | Hex | Nome | Luma* | Rampa / papel |
|---|---|---|---|---|
| 01 | `#0d0b14` | sombra-breu | 12 | **Contorno universal**, fundo de buraco profundo, texto |
| 02 | `#1a1626` | sombra-noite | 25 | Fundo da tela, sombras projetadas |
| 03 | `#2a2440` | sombra-indigo | 40 | Céu noturno, sombras de objetos |
| 04 | `#3d3660` | sombra-violeta | 60 | Céu perto do horizonte, lado escuro da pedra |
| 05 | `#58507f` | sombra-luar | 87 | Névoa, reflexo do luar, UI inativa |
| 06 | `#7d789c` | pedra-escura | 125 | Pedra/lápide (sombra) |
| 07 | `#a8a5bf` | pedra-media | 168 | Pedra/lápide (base) |
| 08 | `#d6d4e3` | pedra-clara | 214 | Pedra/lápide (luz), mármore, lua |
| 09 | `#1f3b35` | grama-funda | 49 | Sombra da grama, folhagem escura |
| 10 | `#2f5a46` | grama-escura | 74 | Grama (sombra) |
| 11 | `#4a7d55` | grama-media | 105 | **Grama (base do tile intacto)** |
| 12 | `#7aa35e` | grama-clara | 142 | Pontas de grama iluminadas |
| 13 | `#2b1a17` | terra-fundo | 30 | **Fundo do buraco** |
| 14 | `#4a2c22` | terra-escura | 51 | Barro exposto, parede de buraco na sombra |
| 15 | `#6e4430` | terra-media | 78 | **Terra exposta (base)**, parede iluminada |
| 16 | `#946140` | terra-clara | 108 | Torrões, terra iluminada |
| 17 | `#b88a5a` | terra-borda | 146 | Borda/lábio do buraco, areia, madeira clara |
| 18 | `#3b2230` | caixao-escuro | 43 | Madeira de caixão (sombra), cruzes |
| 19 | `#5e3340` | caixao-medio | 65 | Madeira de caixão (base) |
| 20 | `#8a4b4f` | caixao-claro | 94 | Madeira de caixão (luz), telhas |
| 21 | `#c9b48f` | osso-sombra | 182 | Osso/pergaminho (sombra) |
| 22 | `#e8dcc0` | osso | 220 | **Osso**, pergaminho, texto claro de UI |
| 23 | `#fff6e0` | osso-brilho | 246 | Brilho máximo, flash de dano, chama de vela |
| 24 | `#a8541a` | lanterna-escura | 102 | Cobre (sombra), ferrugem |
| 25 | `#e08a2a` | lanterna | 152 | **Cobre**, luz de lanterna, vela |
| 26 | `#ffc94a` | lanterna-brilho | 202 | Ouro, brilho de moeda, contorno da área do cursor |
| 27 | `#1b5e5a` | ecto-escuro | 73 | Sobrenatural (sombra), lama esverdeada |
| 28 | `#2fb39a` | ecto | 136 | Ectoplasma, fogo-fátuo, Epitáfio Raro |
| 29 | `#7cf2c8` | ecto-brilho | 201 | Núcleo do fogo-fátuo |
| 30 | `#8fd3ff` | alma | 195 | **Almas**, luar refletido, Ramo Almas |
| 31 | `#8c2b3a` | perigo-escuro | 73 | Perigo, crisântemo vermelho (sombra) |
| 32 | `#d0465a` | perigo | 113 | Alerta de óleo acabando, flores, laços |

\*Luma = 0,299R + 0,587G + 0,114B (0–255), usada para checar contraste de valor.

### 3.1 Rampas permitidas (e cruzamentos entre rampas)
```
Noite:    01 → 02 → 03 → 04 → 05 → 06 → 07 → 08      (sombras viram pedra/luar)
Grama:    01 → 09 → 10 → 11 → 12
Terra:    01 → 13 → 14 → 15 → 16 → 17 → 21 → 22      (terra clareia para areia/osso)
Caixão:   01 → 18 → 19 → 20 → 17
Osso:     15 → 21 → 22 → 23
Lanterna: 18 → 24 → 25 → 26 → 23
Ecto:     02 → 27 → 28 → 29 → 23
Alma:     03 → 05 → 30 → 23
Perigo:   18 → 31 → 32 → 26
```
Use **no máximo 4 tons por material** num sprite pequeno (< 32 px).

### 3.2 Papéis de cor (semântica — não violar)
| Significado | Cores | Regra |
|---|---|---|
| Recompensa / dinheiro | 24–26 | Só moedas, ouro, luz de lanterna e UI de compra. Nunca em inimigos |
| Sobrenatural | 27–30 | Almas, fogos-fátuos, fantasmas, cartas raras. Nunca em solo comum (exceto lama da Área 2, com 27 em no máx. 15% da área) |
| Perigo / atenção | 31–32 | Óleo < 25%, recarga, botões destrutivos (Lua Nova). Também flores, em pequenas doses |
| Interativo | Mais claro que o entorno | Tudo que pode ser cavado ou clicado fica pelo menos 1 degrau de luma acima do fundo ao redor |
| Fundo / decoração fora da grade | 01–05, 09–10 | Decoração nunca usa luma > 105, exceto fontes de luz (velas, lua) |

### 3.3 Proporção de cor na tela (meta)
~60% tons de noite/sombra (01–05) · ~25% materiais (grama/terra/pedra) · ~10% luz quente (lanterna, velas, moedas) · ~5% sobrenatural (almas, ecto).

### 3.4 Teste de valor
Todo tile e todo sprite de gameplay passa no **teste em tons de cinza**: com a imagem dessaturada, as 4 profundidades do tile e a lápide de cova continuam distinguíveis. Se não passar, ajuste o **valor**, não o matiz.

## 4. Luz

### 4.1 Luar (global)
Fixo, do alto à esquerda. Define o sombreamento base de tudo. Sombras projetadas: losango achatado em 02/03, deslocado para baixo à direita (1–2 px), sem transparência (é uma cor sólida da paleta).

### 4.2 Lanterna (cursor) — luz por troca de rampa
Para manter a paleta fechada, **a luz da lanterna não é um shader de luz contínuo**. Cada tileset tem uma **variante "iluminada"**, gerada no Aseprite com um remapeamento de 1 degrau para cima na rampa (tabela abaixo). Na engine, tiles dentro do raio de luz usam o atlas iluminado. O raio (em tiles) encolhe com o óleo: 4 → 3 → 2 → 1, com um anel de transição de 1 tile em xadrez (metade iluminado).

| Original → Iluminado | | | |
|---|---|---|---|
| 01 → 02 | 02 → 03 | 03 → 04 | 04 → 05 |
| 05 → 06 | 06 → 07 | 07 → 08 | 08 → 08 |
| 09 → 10 | 10 → 11 | 11 → 12 | 12 → 12 |
| 13 → 14 | 14 → 15 | 15 → 16 | 16 → 17 |
| 17 → 17 | 18 → 19 | 19 → 20 | 20 → 20 |

Cores 21–32 não mudam (já são claras ou emissivas). O contorno da área de escavação é desenhado por código em **26** (pulso) e **25** (repouso), em degraus iso de 1 px.

### 4.3 Fontes emissivas
Velas, fogos-fátuos, almas, lua e janelas acesas **não recebem sombra** do luar. Núcleo em 23, corpo na cor da rampa, halo opcional de 1 px na cor escura da rampa. Halo grande = sprite separado em xadrez (dither) de 2 cores, nunca alfa.

## 5. Grade, tamanhos e pivôs

| Asset | Canvas (px) | Pivô (ponto de apoio) | Observação |
|---|---|---|---|
| Tile de solo | **32×24** | Centro do losango em (16, 16) | Losango ocupa y = 9–23 (§5.1); 9 px de folga acima para tufos e lábio do buraco |
| Lápide comum | 16×24 | Base central (8, 23) | Fica no tile "cabeceira" da cova |
| Cruz de madeira | 12×20 | (6, 19) | — |
| Vela / grupo de velas | 8×12 / 16×12 | Base | Chama animada 3 frames |
| Rocha (obstáculo) | 32×24 | Igual ao tile | Ocupa o tile inteiro |
| Raiz (obstáculo) | 32×24 por segmento | Igual ao tile | Peças retas e de canto |
| Baú enterrado (revelado) | 16×16 | Base | — |
| Fogo-fátuo | 8×8 | Centro | Flutua 2 px em senoide |
| Fantasma travesso | 16×16 | Base (sombra no chão) | — |
| Ajudantes | 16×16 | Base | — |
| Coveiro (hub) | 16×24 | Base | — |
| Dona Ceifa / Madame Ossada / Seu Damião | 24×32 | Base | — |
| Tião, o Corvo | 12×12 | Base | — |
| Retratos de diálogo | 48×48 | — | Busto, fundo transparente |
| Cursor (pá) | **24×24** (v1.1; antes 16×16) | Ponta da lâmina em (3, 20) | Pá de bico com alça em D. A área é desenhada por código |
| Chefe: Caixão Fujão | 64×48 | Base central | Ocupa 2×2 tiles |
| Chefe: Raiz-Mãe (bulbo / núcleo) | 32×32 / 64×64 | Base | — |
| Chefe: Mausoléu Vivo | 128×96 | Base | 4×4 tiles |
| Chefe: Cova da Dona Ceifa | 96×96 | Base | 3×6 tiles |
| Ícone (recurso, nó, relíquia) | 16×16 | — | Contorno 01; legível em 1× |
| Medalhão de nó | 24×24 | — | Moldura por ramo + ícone 16×16 |
| Carta de Epitáfio | 64×88 | — | Forma de lápide; moldura por raridade |
| Painel de UI (9-slice) | 24×24, margens de 8 | — | Madeira (19/20) ou pergaminho (21/22) |
| Construções do hub | 48–96 × 48–96 | Base | Duas versões: ruína e restaurada |
| Fundo do hub / tela-título | 640×360 | — | Pode usar dithering no céu |

### 5.1 Desenho do losango 32×16
**15 linhas** (y = 9–23 no canvas 32×24) com largura: 4, 8, 12, 16, 20, 24, 28, **32**, 28, 24, 20, 16, 12, 8, 4 — uma única linha de 32 px em y = 16, onde fica o pivô. Degraus de 2 px de cada lado por linha. Com passo (16, 8) entre vizinhos, os tiles encaixam sem sobreposição e sem buraco (área = 256 px = 32×16/2).
> Revisão 1.1: a versão 1.0 listava 16 linhas (…32, 32…), o que sobrepõe 2 px por linha ao vizinho. Corrigido após a prova de encaixe do tileset da Área 1.

## 6. Ambientação por área

Todas as áreas usam a mesma paleta; muda o **peso** de cada rampa e o conjunto de props.

| Área | Cores dominantes | Camadas (aparência do topo) | Props de borda | Clima |
|---|---|---|---|---|
| 1 · Cemitério da Paróquia | 03/04 céu, 11 grama, 15 terra, 07 lápides, 25 velas | Grama 11/12 · Terra 15/16 · Barro 14 | Muro caiado (07/08), portão de ferro, ipê ao fundo, velas, crisântemos (32/26) | Lua cheia, aconchegante, introdutório |
| 2 · Campo dos Indigentes | 05 névoa baixa, 10 grama rala, 27 lama | Grama rala 10/11 · Terra 15 · Lama 14 + manchas 27 · Barro 14 | Cruzes de madeira sem nome (18/19), cercas quebradas, corvos | Névoa no chão (faixas em xadrez 04/05), melancólico |
| 3 · Catacumbas de Pedra | 02/03 ambiente, 06/07 pedra, 18/19 raízes | Terra 15 · Pedra 06/07 · Barro 14 | Paredes de nichos, crânios em prateleira, teias | **Mais escuro**: fora do raio da lanterna os tiles usam 1 degrau abaixo do normal, então a luz do cursor é a principal fonte de leitura do campo |
| 4 · Necrópole dos Barões | 08 mármore, 22 osso, 25/26 ouro, 11 grama aparada | Grama aparada 11 · Mármore 07/08 · Terra 15 · Barro 14 | Mausoléus com colunas, anjos de pedra, vitrais (28/30/32) | Rico, solene, ostentação decadente |
| 5 · Jardim das Almas | 28/29 ecto, 30 alma, 05/08 névoa | Névoa 05/08 (tiles meio transparentes por padrão xadrez) · Terra 15 · Barro 14 | Flores luminosas, lápides flutuantes, a fila de almas | Etéreo, onírico, o "céu" ao contrário |

## 7. Estágios de escavação do tile (o asset mais importante do jogo)

Cada tile mostra no **topo** o material da camada atual, e a **profundidade** é lida pelo quanto do losango já virou buraco. A escala de valor do centro do tile desce a cada estágio: **105 → 78 → 51 → 30**.

| Estágio | Visual | Cores principais |
|---|---|---|
| S0 · Intacto (Grama) | Losango cheio de grama com 3–5 tufos de 1–2 px saindo acima da aresta | 10, 11, 12 (+09 na aresta de baixo à direita) |
| S1 · Arranhado (Terra) | Grama arrancada; terra revolvida com 2–3 torrões; restos de grama só nas bordas | 15, 16, 17 nos torrões |
| S2 · Raso (Barro) | Buraco raso ocupando ~60% do losango; parede de trás à esquerda na sombra (14), parede de trás à direita iluminada (15/16), lábio em 17 | 13, 14, 15, 16, 17 |
| S3 · Fundo (Buraco) | Buraco ocupando ~85% do losango; fundo 13 com 1–2 px de 01 no canto mais escuro (junto à parede da esquerda); parede esquerda 13/14, direita 14/15 | 01, 13, 14, 15, 17 |
| Cova: Caixão exposto | Fundo do S3 com uma tampa de caixão em perspectiva iso (cada tile mostra metade) | 18, 19, 20 + pregos 26 |
| Cova aberta | Tampa deslocada, interior 01, uma alma (30/23) subindo | — |

- **Regra da concavidade:** buracos têm sombreamento invertido em relação a objetos convexos. Com a lua no NO, a parede do lado da luz (trás-esquerda) fica na sombra e a parede oposta (trás-direita) recebe luz; o lábio da frente pega o 17. É esse contraste que faz o olho ler "buraco" e não "caixa".
- **Variações:** 3 variantes do S0 e do S1 (tufos e torrões em posições diferentes) para quebrar a repetição; S2/S3 com 2 variantes.
- Camadas de outras áreas (Lama, Pedra, Mármore, Névoa) trocam o **topo** do S0/S1, mas S2/S3 mantêm a mesma estrutura de buraco, para que a leitura da profundidade seja universal.
- **Dano parcial:** 2 sobreposições de rachadura (16×8, cores do degrau mais escuro da camada, com borda de 1 degrau claro) indicam HP < 66% e < 33% da camada atual. Uma rachadura por camada; no Barro usa 01, porque 13 some sobre 14.

## 8. Personagens e criaturas

### 8.1 Regras de estilo
- Proporção chibi: cabeça ≈ 40–50% da altura.
- Olhos: 1×1 ou 1×2 px em 01, com brilho de 1 px em 23 apenas nos personagens com retrato.
- Silhueta reconhecível só pelo contorno preenchido de 01 (teste da sombra chinesa).
- Mãos e rostos abaixo de 12 px são desenhados pixel a pixel, nunca com formas geométricas.
- Esqueletos: ossos 22/21, contorno 01, crânio grande e arredondado, órbitas grandes (fofas).

### 8.2 Fichas
| Personagem | Silhueta / leitura | Paleta | Detalhe-assinatura |
|---|---|---|---|
| **Coveiro** | Chapéu de palha largo e furado, macacão, pá maior que ele | Chapéu 17/21, roupa 04/05, pele 16/17, pá 06/07 | Lanterna âmbar (25/26) na cintura |
| **Dona Ceifa** | Manto longo triangular, capuz, foice usada como bengala | Manto 02/03 com borda 05, rosto 22, foice 07/08 | Óculos de leitura (26) e uma prancheta |
| **Madame Ossada** | Esqueleto com turbante e xale, bola de cristal | Ossos 21/22, turbante 31/32, xale 28, bola 30/23 | Brincos de argola (26) |
| **Tião, o Corvo** | Corvo gordinho, peito estufado | 01/02/04, bico 17 | Moeda de cobre no bico |
| **Seu Damião** | Fantasma de coveiro velho, bigode grande, chapéu | Corpo 30/23 em xadrez nas bordas, chapéu 18 | Pá fantasma (28) |
| **Toupeira Tita** | Bolinha marrom com focinho rosa e óculos de proteção | 14/15/16, focinho 32 | Óculos (07/26) |
| **Gato Breu** | Gato preto sentado, olhos grandes | 01/02/04, olhos 26 | Coleira com sininho (25) |
| **Cão Ossinho** | Cachorro esqueleto abanando o rabo | 21/22/23 | Osso na boca |
| **Morcegos Gêmeos** | Dois morceguinhos de 8×8 em par | 03/04/05, olhos 26 | Voam em oito |
| **Fantasma Travesso** | Lençol arredondado com dois buracos | 30/23 com xadrez na base | Língua para fora (32) |
| **Fogo-fátuo** | Gota de chama | Núcleo 29/23, corpo 28, halo 27 | Pisca em 4 frames |

## 9. Animação e efeitos

### 9.1 Regras gerais
- Base de **12 fps** (83 ms por frame); idles a 6–8 fps.
- Animar pose a pose (antecipação → ação → acompanhamento). Tween só para objetos rígidos e efeitos secundários.
- Squash & stretch em torrões, almas e ajudantes (30–50% em corpos moles).
- **Hit-stop**: 2 frames ao abrir cova e ao causar crítico ≥ ×5. Desligável junto com "reduzir flashes".

### 9.2 Lista de animações (MVP primeiro)
| Animação | Frames | Duração | Notas |
|---|---|---|---|
| Golpe da pá (cursor) | 4 | min(250 ms, 80% do intervalo do golpe) | Sobe (antecipação) · desce · impacto com squash · volta |
| Contorno da área pulsando | 2 | No pulso | 25 → 26 → 25 |
| Quebra de camada (poeira) | 3 | 250 ms | 16×16, cor do degrau claro do material |
| Torrões (partícula) | — | 400 ms | Quadradinhos de 1–3 px nas cores do material, arco balístico, 1 quique |
| Regeneração do tile | 4 | 330 ms | Terra "fechando" de fora para dentro |
| Cova aberta | 4 + alma 6 em loop | 1 s | Tampa abre; alma sobe 24 px e some em xadrez |
| Fogo-fátuo idle | 4 | Loop 8 fps | — |
| Fantasma flutuando | 4 | Loop 6 fps | — |
| Ajudantes: idle / ação | 2 / 4 | — | — |
| Chefes: idle / dano / especial | 4 / 1 (flash) / 6 | — | Flash = todas as cores trocadas por 23 por 1 frame |
| Vela | 3 | Loop 8 fps | — |
| Moeda voando para o HUD | 4 (giro) | 400–600 ms | Trajetória em curva |
| Número flutuante | — | 600 ms | Sobe 12 px, some em 2 passos. Normal 22, crítico 26, Osso 21, Alma 30 |

### 9.3 Tremor de tela
Máx. 2 px (resolução interna), só em cova aberta, crítico grande e eventos de chefe. Escalonado pela opção de acessibilidade.

## 10. UI

### 10.1 Linguagem
- **Materiais:** painéis de **madeira de caixão** (19/20, contorno 01, pregos 26 nos cantos) para menus; **pergaminho/osso** (21/22) para textos e descrições; **pedra** (06–08) para lápides-carta.
- **Fontes:** pixel fonts de Daniel Linssen: **m5x7** (texto corrido, 7 px) e **m6x11** (títulos e números). Antes do lançamento, confirmar a licença na página do autor e incluir crédito. Texto base em 22 sobre 01–03; nunca texto < 7 px de altura.
- **Números grandes** (recursos no HUD): m6x11 em 22 com contorno 01; ícone de 16×16 à esquerda.

### 10.2 Ícones de recurso (16×16)
| Recurso | Desenho | Cores |
|---|---|---|
| Cobre | Moeda redonda com furo quadrado no meio (moeda antiga) | 24/25/26 |
| Osso | Ossinho de desenho em diagonal | 21/22/23 |
| Alma | Chama-gota azul com 2 olhinhos | 30/23, olhos 03 |
| Selo Lunar | Lua crescente gravada num selo de cera | Cera 31/32, lua 26 |
| Chave da Cripta | Chave antiga com caveira na cabeça | 06/07/08 |

Modo daltônico: as formas acima já diferem entre si; o modo adiciona uma letra/símbolo de 3×5 px ao lado do número.

### 10.3 Árvore de Raízes
- Fundo: corte de solo em faixas horizontais (01/13/14 com pedrinhas 06), ficando mais escuro para baixo.
- Raízes: linhas de 2 px em 18/19 (não compradas) e 17/20 (compradas), com brilho de 1 px no topo.
- Medalhões 24×24 com moldura na cor do ramo: Escavação 16/17 · Lanterna 25/26 · Fortuna 26/23 · Cemitério 11/12 · Ajudantes 05/06 · Almas 30/23 · Lunar 08/26.
- Nós do Centro (N00–N02) usam a moldura de Escavação. O medalhão **máximo** se distingue de Fortuna pelo filete interno 24 e pela estrela; Lunar usa aro 08 com filete 26.
- O ipê-roxo da superfície usa **04/05** nas flores (decoração grande, luma ≤ 105; 31/32 fica reservado a perigo).
- Estados: **oculto** (silhueta 02 com "?"), **disponível** (moldura acesa, custo em 22), **sem dinheiro** (custo em 32), **comprado parcial** (barrinhas de nível), **máximo** (moldura em 26 + estrela).

### 10.4 Carta de Epitáfio (64×88)
Forma de lápide arredondada no topo. Área do título (m6x11), ícone/ilustração 32×32 no centro, descrição (m5x7) em pergaminho na base, tags como mini-ícones 8×8.
Moldura por raridade: **Comum** pedra (06/07/08) · **Raro** ecto (27/28/29) · **Lendário** ouro (24/25/26) com 2 frames de brilho.

## 11. Pipeline e organização

### 11.1 Ferramentas
Aseprite (fonte `.aseprite` versionada), paleta `lua-de-cova-32.gpl` carregada antes de desenhar, modo de cor **Indexed**.

### 11.2 Nomenclatura
`categoria_nome_variante.aseprite` em minúsculas e com `_`. Ex.: `tile_a1_grama_s0_v1`, `char_dona_ceifa`, `boss_caixao_fujao`, `icon_res_cobre`, `ui_card_raro`.
Tags de animação no Aseprite: `idle`, `act`, `hit`, `special`, `open`, `regen`, `low` (estado de alerta, ex.: lanterna com pouco óleo).

### 11.3 Pastas
```
art_src/            (.aseprite fonte; fora do res:// ou com .gdignore)
assets/sprites/     chars/, bosses/, props/, fx/
assets/tiles/       a1/ … a5/ (atlas normal + atlas _lit)
assets/ui/          panels/, icons/, cards/, fonts/
```

### 11.4 Exportação
- Spritesheet PNG + JSON (Aseprite "Array", trim desligado em tiles e ligado em FX).
- Tiles: um atlas por área com todos os estágios e variantes em grade de 32×24, **mais o atlas `_lit`** (§4.2).
- Godot: importar com Filter **off** e Mipmaps **off** (o default do projeto já cobre o filtro).

### 11.5 Checklist de aprovação de asset
1. Usa só cores da paleta (Indexed sem cores extras; `get_color_stats` no MCP).
2. Silhueta legível em 1× e no teste de sombra chinesa.
3. Passa no teste em tons de cinza (§3.4).
4. Luz do alto à esquerda, consistente.
5. Contorno conforme §2.2; sem pixels soltos, sem degraus irregulares (`lint_sprite`).
6. Pivô e canvas conforme §5.
7. Encaixa no losango 32×16 sem sobrepor o tile vizinho (exceto tufos/props na folga superior).
8. Animação com nome de tag correto e timing da §9.2.

## 12. Lista de assets por marco

### M0 · Protótipo cinza
Formas lisas em 05/07/15/13 para os 4 estágios do tile, losango da área desenhado por código, ícones placeholder 16×16. Objetivo: validar a leitura de profundidade (§7) antes da arte final.

### M1 · Vertical slice (Área 1) — ordem de produção
1. Tileset Área 1: S0×3, S1×3, S2×2, S3×2, rachaduras ×2, caixão ×2 metades, cova aberta, regeneração 4f — **+ atlas _lit**
2. Cursor pá (4f) + poeira (3f) + torrões
3. Ícones: Cobre, Osso, Alma
4. Lápide de cova ×3 variantes, rocha ×2, vela, crisântemo
5. HUD: barra de óleo (lanterna como ícone), barra de XP, barra de Inquietação, números
6. Fogo-fátuo (4f), alma subindo (6f)
7. Carta de Epitáfio (3 molduras) + 12 ilustrações 32×32
8. Árvore: fundo, raízes, 7 molduras de medalhão, ~25 ícones de nó
9. Chefe Caixão Fujão (idle 4, afundar 6, emergir 6, dano 1)
10. Ajudantes Toupeira Tita e Gato Breu
11. Personagens: Dona Ceifa, Madame Ossada, Tião (sprite + retrato 48×48)
12. Hub: fundo 640×360 + Portão, Casa do Coveiro e Capelinha (ruína/restaurado)
13. Bordas da Área 1: muro, portão, ipê, céu com lua
14. Tela-título: logo "DIG DIG GRAVES" (letras de pedra 08/07 com terra 15 escorrendo e uma pá cravada no segundo "G")

### Brief-padrão para pedir uma ilustração
> **Asset:** [nome] · **Canvas:** [W×H] · **Pivô:** [x,y] · **Área:** [n] · **Rampas:** [lista de índices] · **Luz:** NO (lua) · **Contorno:** [seletivo/sem] · **Frames/tags:** [..] · **Referência de tom:** macabro aconchegante, chibi, sem gore · **Critério de pronto:** checklist §11.5.
