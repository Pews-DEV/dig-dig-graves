# Dig Dig Graves — Direção de Arte

> Versão 1.1 · 27/10/2026 (§13: assets do v1.0) · Complementa o [01_GDD.md](01_GDD.md).
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
| Tião, o Corvo | 12×12 (tela-título: 16×16, pivô (8, 15), para caber o pulinho e o grasnado) | Base | — |
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
| **Mascate** | Esqueleto vendedor ambulante, chapéu de feltro, mochila alta de quinquilharias | Ossos 21/22/23, chapéu e colete 18/19/20 (fita 25), paletó 03/04/05, mochila 14/15/16, frigideira 05/06/07 | Dente de ouro (26) e sininho (25/26) |
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

## 12. Lista de assets por marco (M0/M1 — histórico; v1.0 no §13)

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

## 13. Assets do v1.0 (GDD 2.0)

> Acrescentado em 27/10/2026 com o GDD 2.0. Substitui a lista do §12 para o jogo completo; o §12 fica como histórico do M0/M1. Paleta fechada e regras dos §2–§11 valem para tudo. A letra [A]–[D] é o marco jogável em que o asset precisa estar pronto (GDD §19; plano em [06_PLANO_V1.md](06_PLANO_V1.md)). Ids já no `assets/MANIFEST.md` estão marcados com ✔.

### 13.1 Kit por estágio
Todo estágio repete o **mesmo contrato de atlas** do estágio 1/2 (layout de colunas, pivôs e `_lit`), para o código só trocar caminhos no `StageData`.

| Peça | Id por estágio (N = 1…5) | Observação |
|---|---|---|
| Tiles | `tiles_aN` + `_lit` (colunas 0–3 = S0–S3; coluna 4+ = camadas próprias do estágio) | Estágio 1 ganha a coluna da **Ossada** (S1-like com ossinhos 21/22 e rachaduras; o fundo S3 igual) [A]; a Ossada aparece em todos os estágios, então cada `tiles_aN` traz a sua coluna Ossada |
| Rachaduras · regeneração | `cracks_aN`, `regen_aN` (+ `_lit`) | Uma linha de rachadura por camada |
| Covas | `grave_aN`, `grave_open_aN` (+ `_lit`) | Caixão no material do estágio (tábua simples no 2, pedra lavrada no 3, mogno com alças 26 no 4, vidro de névoa 05/08 no 5) |
| Lápides | `lapide_aN` (célula 16×24, pivô (8, 23)) com **7 colunas**: 0 foto oval · 1 cruz de pedra · 2 musgo · 3 rachada · 4 coroa de flores · 5 anjo de pedra · 6 flutuante | Colunas sem uso no estágio podem ficar vazias. O tipo precisa ser **legível sem tooltip** (silhueta e 1 cor-assinatura: cruz 07/08, musgo 10/11, rachadura 01 em zigue-zague, coroa 32/26, anjo 08 com asas, flutuante com sombra destacada 2 px abaixo) |
| Obstáculo | `rocha` ✔ (1, 3–5) · `poca_lama` ✔ (2) | Ocupa o tile inteiro, como a rocha |
| Bloco do diorama · cerca · tufos · placa | `bloco_aN`, `cerca_aN`, `tufos_aN`, `placa_aN` | Mesmas células do estágio 1 |
| Fundo do turno | `bg_aN_chao`, `bg_aN_props`, `bg_aN_mata` (672×392, canto em (−16, −16)) | Contrato do §5 da UI/UX; decoração com luma ≤ 105 |

**Ambientação (detalha o §6):**
| Estágio | Chão do fundo | Props do fundo | Elementos novos na grade | Luz |
|---|---|---|---|---|
| 1 · Paróquia | grama-funda 09/10 | Cerquinha de ferro, lápides, velas | Vela de Finados no tile (`vela_campo` 32×24, chama 3f), moeda dourada (`moeda_ouro` 8×8, 4f giro), alminha errante (reusa `alma_fila`) [A] | Lua cheia |
| 2 · Indigentes | campo aberto 09, névoa 04/05 | Fileiras de cruzes sem nome, árvores secas, corvos ✔ | Fantasma travesso (`fantasma` 16×16, idle 4f + tapar 4f + pop 3f), cruz de madeira cavável (`cruz_madeira` ✔ + rachaduras), ossário (`ossario` 32×32: vazio/meio/cheio + esvaziar 4f), baú (`bau` 16×16 fechado/abrindo 4f + brilho sutil 2f) [B] | Lua velada (céu 03, mais névoa) |
| 3 · Catacumbas | pedra 02/03 com junta 04 | Paredes de nichos com crânios (21/22 em ≤ 10% da área), teias 05, raízes 18/19 | Raiz (`raiz` 32×24: reta NO, reta NE, canto ×4, ponta ×2; HP rachadura 2), **atlas escuro** `tiles_a3_dark` (1 degrau abaixo, usado fora da luz) [C] | **Sem lua**: só a lanterna; fora da luz os tiles usam `_dark` |
| 4 · Barões | grama aparada 11 com mármore 07/08 | Mausoléus com colunas, anjos de pedra, vitrais 28/30/32 em pontos pequenos | Baú dos Barões (`bau_baroes` 32×24 1×2, ouro 25/26, abrir 4f) [D] | Lua cheia fria, vitrais emissivos |
| 5 · Jardim das Almas | ecto 27 escuro com flores 28/29 | Lápides flutuantes, flores luminosas, a fila de almas no horizonte | **Névoa** sobre tiles (`nevoa_tile` 32×24, xadrez 05/08 em 3 frames: entra, cheia, sai), 3 fantasmas [D] | Céu "ao contrário": 03 com estrelas 30 embaixo, ecto 28 no alto |

### 13.2 Fichas dos chefes
| Chefe | Canvas · pivô | Ocupa | Leitura / silhueta | Paleta | Tags (frames) | Marco |
|---|---|---|---|---|---|---|
| **Caixão Fujão** ✔ | 64×48 · (32, 32) | 2×2 | Caixão em pé, olhinhos e sorriso de travessura | Caixão 18/19/20, pregos 26 | `idle` 4 · `sink` 6 · `emerge` 6 · `hit` 1 · `defeat` 6 · + `boss_caixao_buraco` ✔ | A |
| **Seu Damião** (chefe) | 24×32 · (12, 31) | 1×1, andando | O fantasma da ficha §8.2 com a pá fantasma no ombro e uma **trilha** de pegadas ecto | Corpo 30/23 em xadrez nas bordas, chapéu 18, pá 28 | `walk` 4 (por eixo iso, espelhado) · `fill` 4 (tapa buraco) · `hit` 1 · `defeat` 6 (vira aliado: tira o chapéu) · `trail` (pegada 16×8, 3f de sumir) | B |
| **A Raiz-Mãe** | núcleo 64×64 · (32, 48) · bulbo 32×32 · (16, 24) | núcleo 2×2 + 4 bulbos 1×1 | Bulbo de raiz com "coração" pulsando; bulbos como cebolas com olhinho | Raiz 18/19/20 e 14/15, coração 31/32 (único vermelho grande do jogo, ≤ 8% do sprite), olhos 26 | núcleo `idle` 4 (pulso) · `shield` 2 (imune) · `hit` 1 · `defeat` 8 · bulbo `idle` 2 · `hit` 1 · `pop` 4; raiz de ligação reusa `raiz` | C |
| **O Mausoléu Vivo** | 128×96 · (64, 80) | 4×4 | Mausoléu com colunas e porta-boca, vitral-olho | Mármore 06/07/08, ouro 25/26, vitral 28/30 | `idle` 4 · `phase1..3` (1 frame cada, com rachaduras crescentes) · `spawn` 4 (porta abre) · `hit` 1 · `defeat` 8 · **herdeiro** 16×16 (fantasma com cartola) `idle` 4 · `pop` 3 | D |
| **A Cova da Dona Ceifa** | 96×96 · (48, 80) | 3×6 | Cova gigante com a lápide de Dona Ceifa (foice gravada, óculos); as camadas aparecem na borda | Terra/camadas das 6 rampas, lápide 07/08 | `layer0..5` (topo de cada camada) · `regen` 3 · `hit` 1 · `open` 8 (abre e mostra o "colchão") | D |
| Ícones de chefe | 16×16 | — | Rosto de cada chefe para a barra e a placa Enfrentar | — | `icon_boss_caixao` ✔, `icon_boss_damiao`, `icon_boss_raiz`, `icon_boss_mausoleu`, `icon_boss_ceifa` | A–D |

Flash de dano = todas as cores por 23 por 1 frame (§9.2), igual para todos.

### 13.3 Personagens, retratos e final
- Retratos 48×48 (`idle`/`talk`): `portrait_dona_ceifa` ✔, `portrait_tiao` ✔, `portrait_madame_ossada` ✔, `portrait_coveiro` ✔, `portrait_mascate` ✔, **`portrait_damiao`** [C].
- Sprites na superfície do hub (pivô na base): `mascate` ✔ [B]; `madame_ossada` 24×32 (`idle` 4, bola de cristal piscando) [B]; `damiao_hub` 24×32 sentado no poço (`idle` 4) [C]; `tiao` ✔ reusado na placa [A].
- Ajudantes 16×16 (`idle` 2 + `act` 4): `tita` [B], `gato_breu` [C], `cao_ossinho` [D], `morcegos` (dois 8×8 em oito) [D].
- **Cena final** [D]: `end_bg` (Jardim, 640×360, 3 variações de céu: noite 02/03, aurora 04/05, amanhecer com sol 26/23 — trocadas em passos), `end_ceifa` (48×48: tira os óculos 4f, deita 6f), `end_coveiro` (32×32: pega a foice 6f), `end_souls` (reusa `alma`), `title_ceifa_ferias` (Dona Ceifa de chapéu de praia 24×32 para o título pós-final).

### 13.4 UI nova
| Id | Tamanho | Descrição | Marco |
|---|---|---|---|
| `frame_at` · `frame_r` · `frame_d` | 32×32 (sobre o medalhão do ramo) | Aro de ativo (4 raios 26), de regra (pontos 28 em 8 direções) e de desbloqueio (cadeado aberto 8×8) | A |
| `frame_master_<ramo>` (×6) + `frame_master_shadow` | 40×40 | Medalhão grande com raízes abraçando, na cor do ramo; silhueta 02 | A |
| `frame_sealed` | 32×32 | Pedra 06/07, raiz cortada e "×" 8×8 | A |
| `root_y` | 8×4 tira | Raiz em "Y" da encruzilhada (mesmo estilo de `tree_roots`) | A |
| `tree_soil_wide` · `tree_sky_wide` · `tree_grass_wide` | 1936×848 · 1936×176 · 1936×16 | Árvore v2 (mundo 1936×1024); pode ser montado por tiles de 64 px | A |
| `minimap_frame` | 104×56 | Moldura de madeira do minimapa | A |
| `hud_stomp` · `hud_flare` | 20×20 (+ estado apagado) | Bota pisando a terra; fósforo com chama | A · B |
| `hud_active_frame` · `hud_pips` | 28×28 · 4×4 | Plaqueta do ativo e pips de recarga | A |
| `barra_chefe` | 9-slice 24×10 | Moldura da barra do chefe; preenchimento 31/32, "fantasma" 22 | A |
| `panel_stone` ✔ | — | Placa "Enfrentar", confirmações | A |
| `chapter_card` | 9-slice | Pergaminho do Fim do Capítulo com fita 32 | A |
| `hub_selector` | 96×64 | Placa com 5 lanternas (acesa/selecionada/apagada) e nomes | A |
| Construções `bld_<id>_ruina` / `bld_<id>` | 48–96 × 48–96, base | Portão, Casa, Capelinha, Barraca do Mascate [B]; Poço, Canteiro, Torre [C]; Galinheiro, Jazigo, Coreto [D] | B–D |
| `shop_slot` · `shop_tabs` | 24×24 · 20×20 | Casa da prateleira (normal/foco/comprado/equipado) e abas | B |
| Ícones de item `icon_item_<id>` | 16×16 | 6 pás + 14 amuletos (GDD §8) | B (5) · C (12) · D (20) |
| `ui_card_comum` · `ui_card_raro` · `ui_card_lendario` | 64×88 | Molduras das cartas (§10.4), costas `ui_card_back` | B |
| `card_art_<id>` | 32×32 | 24 ilustrações (GDD §7) | B (8) · C (16) · D (24) |
| `icon_epitaph_<id>` | 12×12 | Mini-ícone da fileira do HUD | B |
| `icon_milestone_<id>` + `toast_frame` | 16×16 · 9-slice | 20 marcos | C |
| `icon_key_1..5` | 16×16 · 32×32 (Resumo) | Chaves da Cripta, giro 4f | A |
| FX | — | `fx_stomp` (anel 4f), `fx_flare` (anel xadrez 3f), `fx_coin_rain`, `fx_bone_rain`, `fx_constellation` (3 estrelas 30 ligando os fogos-fátuos) | A–C |

### 13.5 Ordem de produção por marco
- **A:** coluna Ossada no `tiles_a1`; `lapide` com colunas 0–2 legíveis por tipo; `vela_campo`, `moeda_ouro`; molduras de tipo/mestra/selado; árvore larga; minimapa; HUD do Pisão; barra e ícone do chefe; chave 1; placa do seletor; cartão de capítulo; ruínas em silhueta da superfície.
- **B:** estágio 2 completo ✔ (falta a coluna Ossada do `tiles_a2` e as colunas 3 da `lapide_a2`); Seu Damião chefe; Mascate ✔, Madame Ossada no hub; 4 construções; loja; cartas (3 molduras + 8 ilustrações); Tita; fantasma, ossário, baú; Clarão no HUD.
- **C:** estágio 3 completo + `_dark`; Raiz-Mãe; Damião no hub e retrato; 3 construções; 7 itens; 8 cartas; Gato; raiz; Mausoléu 3×3 do CX (`mausoleu_cx` 96×72); marcos e toast.
- **D:** estágios 4 e 5; Mausoléu Vivo e herdeiros; Cova da Dona Ceifa; 3 construções; 8 itens; 8 cartas; Cão e Morcegos; baú dos barões; névoa; lápides 5–6; cena final; Dona Ceifa de férias no título.
