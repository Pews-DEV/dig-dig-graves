# Dig Dig Graves — Game Design Document

> **Versão 2.0** · 27/10/2026 · Engine: Godot 4.7 (GL Compatibility) · Status: produção do v1.0 em marcos jogáveis
> Documentos irmãos: [02_DIRECAO_DE_ARTE.md](02_DIRECAO_DE_ARTE.md) (visual), [03_UI_UX.md](03_UI_UX.md) (interface, animação e som), [06_PLANO_V1.md](06_PLANO_V1.md) (plano de produção em pacotes), [07_HISTORIA.md](07_HISTORIA.md) (tratamento narrativo), [05_DECISOES_PENDENTES.md](05_DECISOES_PENDENTES.md) (D0–D12, aprovadas e incorporadas aqui) e [04_REVISAO_E_ROADMAP.md](04_REVISAO_E_ROADMAP.md) (análise que originou esta versão; superada por esta onde houver conflito).
> Todos os números são **valores de balanceamento prontos para `.tres`**, calibrados por simulação (§14). O formato das fórmulas é decisão de design; os coeficientes se ajustam em playtest.

**Changelog 2.0 (em relação à 1.1)**
- Escopo do **v1.0 completo** (D0) organizado em **4 marcos jogáveis** (A · Capítulo 1, B · Capítulo 2, C · Capítulo 3, D · v1.0); cada tabela marca em que marco o item entra (§19).
- Economia nova (D1–D3, D10): pá começa em **1×1** e cresce **por lado** (passos de área); campo começa em **5×5** e vai a 18×18; **Cobre por ponto cresce com a profundidade**; fogo-fátuo com retorno de 80%; Campo Limpo sem efeito composto; óleo de cova com teto.
- Árvore nova com **100 nós em 7 ramos** (D4): Raízes-mestras compráveis em **Almas, ×3 a cada uma**, 3 encruzilhadas, **Duas Raízes**, Replantar (D8), Cava-Funda (D9), Pisão e Clarão. Grade e layout novos (mundo 1936×1024).
- **5 estágios** com diorama, novidade e **chefe** próprios; **Noite do Chefe** (D5); seletor de estágios (D12); **final** com cena, créditos e "Continuar cavando".
- **Lápides com efeito** (D11) e 1–2 elementos de tabuleiro novos por estágio.
- **Epitáfios** (24), **Mascate** com 6 pás e 14 amuletos (D6), **hub na superfície da Árvore** com 9 construções (D7), **4 ajudantes**, **20 marcos** internos, diálogos em balão com retrato.
- Fora do v1.0 (pós-1.0, §19.6): Lua Nova/Ramo Lunar, Codex completo, EN, Steam/achievements, ganho offline, Noites Eternas, hub como cena separada.

---

## Sumário
1. Ficha técnica e escopo
2. Visão e pilares
3. Mundo, tom e personagens
4. Mecânica principal: o Turno da Noite
5. Recursos e economia
6. Árvore de Raízes
7. Epitáfios
8. Ferramentas e Mascate (pás e amuletos)
9. Ajudantes
10. Estágios e chefes
11. Hub na superfície da Árvore
12. Prestígio (pós-1.0)
13. Marcos, final e pós-final
14. Balanceamento e ritmo (simulação)
15. Telas, fluxo e UI
16. Controles e acessibilidade
17. Áudio
18. Arquitetura técnica
19. Marcos jogáveis e escopo
20. Riscos
21. Glossário

---

## 1. Ficha técnica e escopo

| Item | Definição |
|---|---|
| Título | **Dig Dig Graves** (subtítulo PT-BR: "Cava Cava Covas") |
| Gênero | Incremental ativo com árvore grande, portões de chefe e cartas por noite (nicho Nodebuster/SuperReap) |
| Referências | Nodebuster (área em pulsos, árvore, chefe como portão, marcos), SuperReap (cartas 3→1, restaurar o lugar, estágios), Harventure (nós ativos), Xenosensory (equipáveis com limite) |
| Câmera | 2D isométrica 2:1, fixa |
| Arte | Pixel art 640×360, escala inteira, paleta fechada Lua de Cova 32 |
| Plataforma | PC (Windows; Linux como alvo secundário). v1.0 distribuído no itch.io; Steam é pós-1.0 |
| Controles | Mouse (principal), teclado e gamepad |
| Duração | Chefe 1 em ~35–45 min · final em **~3h30–4h** · tudo no máximo em **~5 h** (jogador atento; relaxado +25%) |
| Idioma do v1.0 | PT-BR (textos já preparados para `tr()`; EN é pós-1.0) |
| Público | Fãs de incrementais curtos e "satisfatórios", 16+, sessões de 5–60 min |
| Classificação | Livre/10+: morte com humor, sem sangue |

**Pitch:** você é o novo coveiro do Cemitério do Bom Descanso e, a cada noite, até a lanterna apagar, passa a pá pelo terreno abrindo covas para as almas da fila. Cada pá de terra vira moeda, cada moeda vira raiz na árvore, cada chefe abre um cemitério novo, até a última cova: a da própria Morte, que quer tirar férias.

### 1.1 Conteúdo total do v1.0 e o que entra em cada marco
Cada marco é um **jogo completo** com início, meio e fim (critérios em §19). Números acumulados.

| Sistema | Total planejado | A · Cap. 1 | B · Cap. 2 | C · Cap. 3 | D · v1.0 |
|---|---|---|---|---|---|
| Estágios (dioramas) | 5 | 1 | 2 | 3 | 5 |
| Chefes | 5 | 1 | 2 | 3 | 5 |
| Nós da árvore | 100 | 44 | 64 | 84 | 100 |
| Raízes-mestras | 6 | 2 (EX, LX) | 3 (+FX) | 5 (+CX, AX) | 6 (+SX) |
| Encruzilhadas | 3 (+ Duas Raízes) | 1 (E12) | 2 (+L07) | 3 (+C09) | 3 + N05 |
| Ativos | 2 | Pisão | + Clarão | 2 | 2 |
| Epitáfios | 24 | 0 | 8 | 16 | 24 |
| Itens do Mascate | 20 (6 pás + 14 amuletos) | 0 | 5 | 12 | 20 |
| Espaços de amuleto | 4 | — | 2 | 3 | 4 |
| Construções do hub | 9 (+ Barraca do Mascate) | 0 | 3 + Barraca | 6 + Barraca | 9 + Barraca |
| Ajudantes | 4 | 0 | 1 (Tita) | 2 (+Gato) | 4 (+Cão, Morcegos) |
| Tipos de lápide com efeito | 7 | 3 | 4 | 5 | 7 |
| Elementos de tabuleiro (além de lápide/rocha) | 12 | 3 (vela, moeda de ouro, alminhas) | 8 (+fantasma, cruz, poça, ossário, baú) | 10 (+raiz, escuridão) | 12 (+baú dos barões, névoa) |
| Camadas de solo | 9 (grama, terra, barro, ossada, grama rala, lama, pedra, mármore, névoa) | 4 | 6 | 7 | 9 |
| Marcos internos | 20 | 0 | 0 | 15 | 20 |
| Personagens com retrato | 5 (Dona Ceifa, Tião, Madame Ossada, Mascate, Seu Damião) | 2 (Ceifa, Tião) | 4 (+Mascate, Ossada) | 5 (+Damião) | 5 |
| Falas (balões) | ~80 | ~14 | ~34 | ~52 | ~80 |
| Músicas | 12 (título, árvore/hub, 5 estágios, chefe, loja, final, jingle de resumo, jingle de vitória) | 5 | 8 | 9 | 12 |
| Tela de fim | 4 (3 "Fim do Capítulo" + final) | Cap. 1 | Cap. 2 | Cap. 3 | Final + créditos |

## 2. Visão e pilares

### 2.1 Fantasia do jogador
Começar com uma pá enferrujada que mal arranha um canteiro de 5×5 e terminar revolvendo um campo de 18×18 com uma pá de 6×6, numa chuva de torrões, ossos e almas, depois de enterrar a própria Morte (que agradece).

### 2.2 Pilares (critério de corte)
1. **Cavar tem que ser gostoso.** Cada golpe tem retorno visual e sonoro. Se uma feature atrapalha a leitura do campo, ela sai.
2. **Sempre há um próximo nó.** Toda noite compra algo ou mostra quanto falta. **Nenhum trecho de 5 noites sem compra** (medido na simulação e na telemetria).
3. **Macabro aconchegante.** Noite, velas, flores, bichinhos, humor. Nunca gore.
4. **Ativo, não AFK.** O jogador mira; Pisão e Clarão recompensam atenção, mas o jogo é jogável sem clicar (auto-pisão). Sem ganho offline no v1.0.
5. **Curto e respeitoso.** Final claro em ~3h30–4h; cada chefe é um capítulo; nada de parede de grind > 10 min sem novidade.

### 2.3 Diferenciais
| Nicho (Nodebuster/SuperReap) | Dig Dig Graves |
|---|---|
| Campo plano | **Profundidade**: camadas por tile; cavar fundo paga mais (§4.3) |
| Alvos isolados | **Covas** de 2 tiles com **lápides que têm regra** (§4.6) |
| Área sempre quadrada | Área cresce **por lado** (1×1 → 6×6) e **pás** mudam o formato (§8) |
| Timer genérico | **Óleo da lanterna**, que também é a luz do cursor |
| Chefe que dá pouca recompensa | Chefe **escolhido pelo jogador** (Noite do Chefe) e com prêmio **grande e visível**: Chave, estágio novo, metade nova da árvore, personagem novo no hub (§10) |
| Árvore abstrata | Raízes de um ipê; a **superfície** é o cemitério que você restaura (hub) |

## 3. Mundo, tom e personagens

### 3.1 Cenário
**Vila do Bom Descanso**, vilarejo fictício de interior: cruzes de madeira, lápides com foto oval, velas de Finados, crisântemos, muro caiado. Sempre noite, lua grande. Além do cemitério da paróquia há quatro lugares mais antigos e estranhos, cada um um estágio (§10).

### 3.2 Premissa
O antigo coveiro, Seu Damião, sumiu. Sem covas, as almas formam uma **fila** na porta. **Dona Ceifa** contrata você. Cada cova aberta deixa uma alma descansar; cada chefe vencido abre o caminho para outro cemitério. No fim, Dona Ceifa revela o que queria desde o começo: que você abra uma cova para *ela*, porque quer tirar férias.

### 3.3 Elenco
| Personagem | Função | Entra em | Tom |
|---|---|---|---|
| **O Coveiro** (jogador) | Pá-cursor no turno; sprite no título e no final | A | Silencioso, chapéu de palha furado |
| **Dona Ceifa** | Contratante; abre e fecha cada capítulo, anuncia a Noite do Chefe, final | A | Burocrática, cansada, engraçada |
| **Tião, o Corvo** | Tutorial em 1 balão por vez, dicas na Ficha e nos marcos | A | Fofoqueiro, ganancioso por brilho |
| **Madame Ossada** | Vidente; apresenta os Epitáfios (N02) e se muda para a Capelinha | B | Dramática, trocadilhos |
| **Mascate** | Vendedor ambulante esqueleto: pás e amuletos (§8) | B | Lábia de feira, dente de ouro |
| **Seu Damião** | Chefe do estágio 2; depois mora no hub e comenta os chefes | B (chefe) · C (retrato no hub) | Rabugento, competitivo |
| Ajudantes | Toupeira Tita, Gato Breu, Cão Ossinho, Morcegos Gêmeos (§9) | B–D | Mascotes |

### 3.4 Narrativa em pílulas
Sem cutscenes longas: **balões de 1–4 falas** com retrato 48×48 (UI/UX §14). ~80 falas no total, em `DialogueData` (§18.3). Gatilhos: 1º turno, 1ª cova, 1º nó, 1ª Inquietação cheia de cada estágio, início e vitória de cada Noite do Chefe, 1ª entrada em cada estágio, 1ª visita ao Mascate, N02, final. O arco, os motivos recorrentes e a orientação de voz estão em [07_HISTORIA.md](07_HISTORIA.md); divergência de mecânica ou escopo é resolvida por este GDD.

## 4. Mecânica principal: o Turno da Noite

### 4.1 Visão geral
1. Do Pátio, o jogador escolhe **Próxima Noite** para iniciar o estágio atual ou, com a Inquietação cheia, **Enfrentar ‹chefe›** (Noite do Chefe, §4.11).
2. O **Óleo da Lanterna** queima; o pulso golpeia sozinho a **área de escavação** sob o cursor.
3. O dano paga **Cobre por ponto** (mais nas camadas fundas), quebra camadas (Ossos e XP) e abre **covas** (Almas, Ossos, Inquietação).
4. A partir do N02 (marco B), cada nível do turno pausa e oferece **1 de 3 Epitáfios** (§7).
5. O óleo acaba ou o sol nasce (300 s) → **Resumo** → **Árvore/hub** → próxima noite.

Duração: 15–17 s no 1º turno, ~60 s aos 12 min, ~95 s no fim do estágio 1, 120–160 s nos estágios 2–4, até 250 s no fim do jogo; **teto absoluto 300 s** (amanhecer).

### 4.2 O campo
- Grade isométrica N×N (losango 32×16). **Começa em 5×5** e cresce por C01/C11/C12/C17 até **18×18** (D1): 5 → 10 (C01, 5 níveis) → 12 (C11) → 14 (C12) → 16 → 18 (C17). Ritmo simulado: 8×8 aos 7 min, 10×10 aos 22 min, 12×12 aos 43 min, 14×14 a 1h50, 16×16 a 2h55, 18×18 a 3h50.
- O campo inteiro sempre visível (18×18 = 576×288 px). O fundo do turno e o bloco de terra acompanham o tamanho (DA §6).
- Elementos: solo, covas (lápide + 2 tiles), obstáculos do estágio, elementos de tabuleiro (§4.8), chefe (na Noite do Chefe).

### 4.3 Camadas e valor por profundidade (D3)
Cada tile tem uma pilha de camadas (topo → fundo). Valores **base** (antes do multiplicador do estágio, §10.1):

| Camada | Estágios | HP | Cobre (total da camada) | Cobre por ponto | XP | Chance de Osso | SFX | Marco |
|---|---|---|---|---|---|---|---|---|
| Grama | 1 | 2 | 2 | 1 | 1 | 0% | `dig_grass` | A |
| Terra | todos | 4 | 6 | 1,5 | 2 | 3% (est. 1) · 4% (2+) | `dig_dirt` | A |
| Barro | todos | 8 | 16 | 2 | 3 | 6% (est. 1) · 8% (2+) | `dig_clay` | A |
| **Ossada** (C08) | todos, sempre a última | 14 | 42 | 3 | 4 | 15% | `dig_bone` | A |
| Grama rala | 2 | 2 | 2 | 1 | 1 | 0% | `dig_grass` | B |
| Lama | 2 | 6 | 12 | 2 | 3 | 6% | `dig_mud` | B |
| Pedra | 3 | 12 | 30 | 2,5 | 4 | 8% | `dig_stone` | C |
| Mármore | 4 | 16 | 48 | 3 | 5 | 10% | `dig_marble` | D |
| Névoa | 5 | 6 | 12 | 2 | 3 | 6% | `dig_mist` | D |

- **Cobre por ponto de dano** = Cobre da camada × Recompensa do estágio ÷ (HP × HP do estágio); frações acumulam no turno. Ossos e XP só quando a camada quebra. Camadas mais fundas pagam mais por ponto: cavar fundo é o objetivo (D3).
- **Excedente:** por padrão o dano que passa da vida da camada é perdido. Com **Cava-Funda (E13)** ele continua na camada de baixo, em cascata, até o fundo (D9). O Epitáfio "Morte súbita" esvazia o tile inteiro.
- Chance de Osso: F02 soma só nas camadas que já têm chance (> 0%). Grama nunca solta Osso.
- Tile sem camadas = **Buraco**. Ordem por estágio em §10.1.

### 4.4 Área de escavação, pulso e ativos
| Stat | Inicial |
|---|---|
| Dano por golpe | 1 |
| Intervalo entre golpes | 1,00 s (mínimo 0,15 s) |
| Área | **1×1** (passo 0) |
| Crítico | 0% · ×2 |

**Área por lado (D2).** A área é um retângulo L×A medido em **passos**; cada nó de área dá +1 passo:

| Passo | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Área | 1×1 | 1×2 | 2×2 | 2×3 | 3×3 | 3×4 | 4×4 | 4×5 | 5×5 | 5×6 | 6×6 |
| Fonte | — | E03 | E03 | E03 | E06 | E06 | E14 | E16 | E19 | EX | E21 |

- O sprite da pá acompanha o ponteiro em posição livre, sem prender o desenho ao centro dos tiles. O tile mais próximo do ponteiro determina o alvo/âncora da área; fora da grade, o cursor continua visível, mas o golpe não atinge tiles. A âncora do bloco central é: lado ímpar = centro; lado par = canto superior-esquerdo do par central (tile sob o ponteiro + vizinhos à direita/abaixo na grade). Com A > L, o retângulo é "em pé" no eixo y da grade; a Pá Velha não gira (o Enxadão gira, §8).
- Recortada nas bordas; tiles de lápide e elementos bloqueados não levam dano.
- Pulso automático e global; crítico rolado **por tile**.

**Ativos (habilidades com recarga).** Ícones no HUD (UI/UX §13).
| Ativo | Nó | Entrada | Efeito | Recarga | Marco |
|---|---|---|---|---|---|
| **Pisão** | E10 (400 Cobre) | Clique esquerdo · Q · gamepad A | Golpe extra imediato com **×4** de dano na área atual | 8 s (E11: −1 s/nível, mínimo 4 s) | A |
| ↳ Pisão Sísmico (E12a) | encruzilhada | — | O Pisão também acerta o anel de 1 tile em volta da área, com ×2 | — | A |
| ↳ Pisão Ritmado (E12b) | encruzilhada | — | Dispara sozinho a cada 8 golpes (além do manual) | — | A |
| **Clarão** | L05 (750 mil Cobre) | Botão direito · E · gamepad X | Por 3 s (L11: +1 s/nível) a luz vai ao raio máximo e tiles iluminados levam **+50%** de dano; custa 2 s de óleo | 20 s | B |

- **Auto-pisão** (acessibilidade, GDD §16): opção que dispara o Pisão sozinho quando recarrega. Disponível desde o E10.
- Golpe extra do Pisão conta como pulso para crítico, covas, chefe e Epitáfios; **não** gasta o relógio do pulso normal.

### 4.5 Óleo da Lanterna (o timer)
- Começa em **15 s**; queima 1 s/s (L09: −5%/nível, multiplicativo).
- **Fogos-fátuos**: um a cada **12 ± 3 s** (÷ frequência de L03), duram 5 s (+1 s/nível de L10); a área tocá-los dá **+2 s** (+0,5 s/nível de L02). **Retorno decrescente (D10):** cada fogo-fátuo coletado na mesma noite vale **80%** do anterior (L13: +4 p.p./nível); volta a 100% na noite seguinte. A soma por noite fica limitada a ~5× o primeiro.
- **Óleo de cova** (L04): +0,5 s por cova/nível, com **teto de 3 s por nível por noite**.
- **Obstáculo do estágio** dentro da área drena óleo por golpe (rocha 0,5 s; poça de lama 0,3 s), salvo com a Picareta.
- O **raio de luz** encolhe com o óleo (>75% → 4; >50% → 3; >25% → 2; senão 1).
- **Amanhecer** aos 300 s: óleo restante vira bônus de Cobre (1 s = +2% do Cobre do turno).
- Segundo Fôlego (L06), Constelação (LX), Ressuscitou (Epitáfio) e Vela de Sete Dias (amuleto/Epitáfio) são as únicas exceções ao relógio.
- Abandonar a noite pela pausa perde os recursos dela (pausa: Continuar / Opções / Abandonar a noite / Voltar ao título).

### 4.6 Covas e lápides com efeito (D11)
- Uma **lápide** marca uma cova de **2 tiles** (eixo NO–SE ou NE–SO). Os tiles da cova têm todas as camadas do estágio **mais o Caixão**: HP = **1,5×** a camada mais dura da pilha (com a Ossada, 21 × HP do estágio). Caixão não paga Cobre por ponto.
- O tile da lápide é bloqueado e não conta para o Campo Limpo. Covas nascem só em tiles intactos, com 1 tile de folga entre elas. Simultâneas: **1** no início, +1 por nível de C02 (3), C14 (3) e pelo amuleto Retrato Oval, **teto 7**.
- **Cova Aberta** (os 2 caixões quebrados): alma sobe, hit-stop de 2 frames e:
  - **Cobre** = 30 × Recompensa do estágio × (1 + C04/C13) × (1 + 1% × covas da noite com F04)
  - **Ossos** = 2–5 × Ossos do estágio
  - **Almas** = 1 × Almas do estágio (S07, S01, S10 multiplicam)
  - **XP** = 15 · **Inquietação** = 100% ÷ N do estágio (§10.1) × (1 + C10 + Torre)
  - **Óleo** = L04 (com teto)
- A cova aberta fecha em 3 s (tiles viram Buraco regenerando) e outra lápide surge.

**Tipos de lápide** (sorteados ao nascer a cova; a regra aparece no tooltip e no ícone da lápide):
| Tipo | Peso | Efeito | Sprite | Marco |
|---|---|---|---|---|
| Foto oval | 50 | Cova normal | `lapide` col. 0 | A |
| Cruz de pedra | 25 | +1 Alma × estágio | `lapide` col. 1 | A |
| Lápide com musgo (antiga) | 25 | Caixão 1,5× mais duro; Ossos ×2 | `lapide` col. 2 | A |
| Lápide rachada | 15 (est. 2+) | Ao abrir, a lápide quebra e solta 5 Ossos × estágio | nova, col. 3 | B |
| Coroa de flores | 8 (est. 3+) | Cobre ×3; uma pétala sobe ao HUD (+1% de Cobre até o fim da noite, acumula) | nova, col. 4 | C |
| Anjo de pedra | 6 (est. 4+) | Cobre ×5 e um baú garantido no tile da cabeça | nova, col. 5 | D |
| Lápide flutuante | 10 (est. 5) | Troca de lugar a cada 8 s (a cova vai junto); Almas ×2 | nova, col. 6 | D |

Cada estágio usa sua própria arte de lápide (`lapide_aN`), sempre com o mesmo layout de colunas; tipos que não existem num estágio têm peso 0.

### 4.7 Regeneração e Campo Limpo
- Só **Buracos** regeneram. Tempo: **18 s** (C03 −10%/nível ×6; C16 −8%/nível ×4; mínimo 5 s). Velas aceleram (§4.8).
- **Campo Limpo** (100% dos tiles como Buraco ao mesmo tempo): "CAMPO LIMPO!", +**20% do Cobre minerado desde o último Campo Limpo** (corrige o efeito composto da 1.1; com FX: +50% e chuva de moedas) e o campo regenera na hora.

### 4.8 Elementos de tabuleiro (por estágio)
Regra de legibilidade: todo elemento interativo é ≥ 1 degrau de luma mais claro que o entorno (DA §3.2). Todos são dados (`BoardElementData`, §18.3) e reaproveitam o modelo de campo (Kind novo + regra).

| Elemento | Estágio / origem | Comportamento | Marco |
|---|---|---|---|
| Rocha | 1, 3 (comum), 4–5 (rara) | Obstáculo: 1 tile, HP 30× camada do topo, drena 0,5 s de óleo por golpe dentro da área; quebrada solta 1 Osso × estágio | A (existe) |
| Vela de Finados | C06 (+1 por nível, máx. 3) | Tile bloqueado; tiles em raio 1 regeneram **2×** mais rápido e rendem **+25%** de Cobre | A |
| Moeda de ouro | F09 | Pula num tile a cada 20 s (−3 s/nível), some em 4 s; tocá-la = +5% do Cobre da noite | A |
| Alminha errante | S04 (+1 por nível) | Flutua devagar; tocá-la = +1 Alma × estágio e um "obrigado" em 1 palavra; renasce em 15 s | A |
| Fantasma travesso | Estágio 2+ (1–2 por noite; 3 no estágio 5) | Flutua; se passar por um Buraco, **tapa** (regenera na hora). HP = 1 camada de Terra; derrubado = 0,5 Alma × estágio | B |
| Cruz de madeira | C15 (+1 por nível) | Cavável, HP 3× Barro; quebrada = 3 Ossos × estágio; covas nascem 2× mais perto dela | B |
| Poça de lama | Estágio 2 (0–3, no lugar das rochas) | Obstáculo: HP 3× Lama, drena 0,3 s de óleo por golpe; quebrada = 2 Ossos × estágio | B |
| Ossário 2×2 | C07 | Bloqueado; cada camada quebrada em raio 1 enche 1%; cheio = **chuva de Ossos** (15 × nível × Ossos do estágio) e esvazia | B |
| Baú enterrado | F03 | Escondido sob um tile (brilho sutil); ao chegar no fundo: Cobre ×25 do tile **ou** um amuleto ainda não comprado (10%; 20% com F11) | B |
| Raiz | Estágio 3 (2–4 por noite) | Liga 2–4 tiles; enquanto existir, eles levam −50% de dano; a raiz é cavável (HP 5× Pedra) e quebrada solta Cobre ×10 do tile | C |
| Escuridão | Estágio 3 | Fora do raio da lanterna os tiles levam **−50%** de dano (a luz importa; Clarão e Lampião do Seu Damião ajudam) | C |
| Mausoléu 3×3 | CX | Nasce no centro a cada noite: 3 camadas de mármore (HP 3× Barro do estágio), abre como cova ×8 e +3 Almas × estágio | C |
| Baú dos Barões | Estágio 4 (1 por noite) | Baú visível 1×2, HP 5× Mármore; Cobre ×100 do tile ou amuleto (25%) | D |
| Névoa | Estágio 5 | A cada 6 s, 20% dos tiles com camada de Névoa ficam "na névoa" por 3 s: intangíveis (sem dano). A Pá Fantasma os atinge | D |

### 4.9 XP do turno e Epitáfios
- XP por camada quebrada = XP da camada (§4.3); cova = 15.
- XP do nível n → n+1: `10 × 1,45^(n−1) × XP do estágio` (1, 3, 9, 27, 81), arredondada. **Teto: nível 15 por noite.**
- O nível reseta a cada noite. **Marco A:** a barra de XP fica oculta (não há Epitáfios). **A partir do N02 (marco B):** cada nível pausa e mostra 3 Epitáfios (4 com S03); escolher 1. Vários níveis no mesmo pulso viram fila.

### 4.10 Fim do turno
Óleo em 0 → último golpe → "O ÓLEO ACABOU" → Resumo (§15). Tudo é creditado automaticamente; os ícones voando ao HUD são só feedback.

### 4.11 Inquietação e Noite do Chefe (D5)
- Cada estágio tem sua **Inquietação** (0–100%), que sobe a cada cova aberta (§4.6) e **persiste entre noites**.
- **> 80%:** a caveirinha do HUD treme; `unrest_warning` ao cruzar 90%.
- **100%:** ao voltar à Árvore/hub, Dona Ceifa avisa (1º vez por estágio) e aparece a placa **"Enfrentar ‹chefe›"** com a caveira tremendo e "A terra treme…". Enquanto o jogador não for, as noites comuns daquele estágio têm **tremores**: covas dão +25% de Almas (incentivo, não punição).
- **Noite do Chefe:** noite normal (óleo, covas, Epitáfios valem) com o chefe no campo desde o início e a barra dele no HUD (`mus_boss`).
  - **Derrota** (óleo acaba com o chefe vivo): ele foge, o HP **volta cheio**, a Inquietação fica em 100% e a placa continua lá. Nada se perde; o Resumo mostra "Faltaram X de vida".
  - **Vitória:** hit-stop, `boss_defeat` → `jingle_boss_win`, diálogo (2–4 balões), **Resumo especial** (Chave + prêmios), volta ao hub com as revelações (§10.3).
  - **Repetir** um chefe vencido: a Inquietação daquele estágio volta a encher do zero; a revanche dá **20% das Almas** da 1ª vitória e nada mais (farm opcional).

## 5. Recursos e economia

| Recurso | Ícone | Origem | Papel (D3) | Marco |
|---|---|---|---|---|
| **Cobre** | Moeda com furo | Dano por ponto, covas, baús, moeda de ouro, Herança | **Números**: a maioria dos nós P, ativos, construções simples | A |
| **Ossos** | Osso | Quebra de camada (chance), covas, rochas/poças/cruzes, Ossário | **Espaço**: área da pá, campo, covas simultâneas, elementos do tabuleiro, Mascate | A |
| **Almas** | Chama azul com olhinhos | Covas, lápide de cruz, alminhas, fantasmas, chefes | **Regras e personagens**: Raízes-mestras, ajudantes, Epitáfios (S), construções da vila, amuletos raros | A |
| Chave da Cripta I–V | Chave com caveira | 1ª vitória sobre cada chefe | Item: libera o estágio seguinte no seletor (não é moeda) | A |
| ~~Selos Lunares~~ | — | — | Pós-1.0 (Lua Nova) | — |

Regras:
- Nada se perde ao fim do turno (salvo "Abandonar a noite").
- Cada estágio multiplica **Cobre, Ossos e Almas separadamente** (§10.1): os três crescem juntos e nenhuma moeda fica morta.
- Números: até 999.999 por extenso; depois `1,23 mi`, `bi`, `tri`, `qua`, `qui` e notação `aa, ab…`. Tudo em `float` (double); teto prático do v1.0 ~1e14.
- Carteira no topo da Árvore/hub e no Resumo, sempre com as 3 moedas; o HUD do turno mostra o ganho da noite.

## 6. Árvore de Raízes

### 6.1 Apresentação e layout
A árvore é o **sistema de raízes de um ipê velho** em corte de solo. A **superfície** (o topo do mundo) é o cemitério a restaurar: o **hub** (§11).

**Mundo da Árvore v2: 1936 × 1024 px.**
- Superfície (hub): y = 0–176 (grama em y = 176), largura inteira.
- **N00 em (968, 240).** Grade: **x = 968 + 88·k** (k = −9…+9) e **y = 240 + 64·r** (r = 0…10). Último nó em y = 880; solo até 1024.
- **Faixas por ramo** (3 colunas cada; nenhum nó fora da sua faixa; o centro usa só k = 0):

| k | −9 −8 −7 | −6 −5 −4 | −3 −2 −1 | 0 | 1 2 3 | 4 5 6 | 7 8 9 |
|---|---|---|---|---|---|---|---|
| Ramo | **E** Escavação | **L** Lanterna | **S** Almas | **N** Centro | **F** Fortuna | **C** Cemitério | **A** Ajudantes |

- Cada célula (k, r) tem no máximo 1 nó (validado: 100 nós, 0 colisões; todo pré-requisito fica numa linha acima). A caixa de um nó (`TreeLayout.node_rect`, 56 px de largura) cabe na coluna de 88 px, então medalhões, pips e custos não se sobrepõem.
- Encruzilhadas: os dois lados ficam **na mesma linha, em colunas vizinhas**, ligados ao pai por uma raiz em "Y".
- Raízes-mestras ficam no fundo de cada faixa e aparecem **desde o início como silhuetas 40×40** com nome e custo no hover: o objetivo distante.
- **Câmera:** arrastar com inércia nos 2 eixos (já existe); roda = rolar vertical, Shift+roda = horizontal; teclas **1–7** pulam para o topo de cada ramo; **Home/“Centralizar”** volta ao N00; **minimapa** 96×48 no canto inferior esquerdo (faixas coloridas, nós comprados em pontos, retângulo da vista; clique = pular). Sem zoom fracionário (pixel-perfect).
- Câmera inicial: superfície + N00 (o hub e o começo das raízes na mesma vista). Comprar/revelar um nó rola até ele.

### 6.2 Custos e regras
- `custo(nível) = ceil(base × cresc^nível)` (nível = níveis já comprados).
- **Tipos** (moldura própria, DA §10.3): **P** passivo · **At** ativo · **R** regra · **D** desbloqueio · **X** encruzilhada · **M** Raiz-mestra.
- **Raízes-mestras (D4):** as 6 são compráveis e custam **Almas**: `1.500 × 3^(nº de Raízes-mestras já compradas)` → 1.500 · 4.500 · 13.500 · 40.500 · 121.500 · 364.500. A placa da Raiz-mestra mostra o custo atual e "a próxima custará ×3". Simulação: a 1ª sai em ~1 h, todas em ~5 h.
- **Encruzilhadas (escolha 1 de 2):** E12 (Pisão Sísmico × Pisão Ritmado), L07 (Lua Cheia × Breu), C09 (Covas Duplas × Vala Comum). Comprar um lado **sela** o outro (medalhão em pedra com raiz cortada, `seal`).
- **Duas Raízes (N05):** libera o outro lado de todas as encruzilhadas (cada um pelo preço normal). Quem maxa tudo não perde nada.
- **Replantar (N03, D8):** liberado ao vencer o chefe 1. Devolve **100%** de tudo que foi gasto na árvore (nas 3 moedas, inclusive as Raízes-mestras) e solta as encruzilhadas; o contador ×3 das mestras volta a zero. Cada uso custa **5 Almas × maior estágio liberado**. Só na Árvore, com confirmação (UI/UX §16).
- **Revelação:** comprado, inicial, ou filho de nó comprado com o pré-requisito de nível cumprido; filhos aparecem como "?" escuro. Gatilhos especiais: N01 no 2º turno; S01 com a 1ª Alma; A01/N03 após o chefe 1. Nós de estágio k só aparecem com o estágio k liberado (`required_stage`).
- **Totais** (sem Raízes-mestras, que somam 546 mil Almas): A 8,4 mi Cobre + 21,5 mil Ossos + 904 Almas · B 203 mi Cobre + 22 mil Ossos + 2,2 mil Almas · C 91 bi Cobre + 1,4 mi Ossos + 3,8 mil Almas · D 7,1 tri Cobre + 5,4 mi Ossos + 298 mil Almas.

### 6.3 Nós por ramo
Colunas: **Est.** = estágio que precisa estar liberado; **Marco** = em que build o nó entra; **Grade** = (k, r) da §6.1. "Nv" no pré-requisito = nível mínimo do pai.

#### N · Centro

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| N00 | Pá Velha | — | Início. Revela E01, L01, F01 e C01 | — | — | grátis | — | — | 1 | A | (0, 0) |
| N01 | Ficha do Coveiro | D | Painel de stats (Tab) com todos os valores calculados | 1 | Cobre | 5 | — | N00 · 2º turno | 1 | A | (0, 1) |
| N02 | Visita da Vidente | D | Libera os Epitáfios (subir de nível = escolher 1 de 3); mostra a barra de XP; revela S02, S08, S09 | 1 | Cobre | 100.000 | — | N01 | 2 | B | (0, 2) |
| N03 | Replantar | D | Respec: devolve 100% do gasto e solta as encruzilhadas. Cada uso custa 5 Almas × nº do estágio mais alto liberado | 1 | Almas | 5 | — | N01 · após o chefe 1 | 2 | B | (0, 3) |
| N05 | Duas Raízes | R | Libera o outro lado de todas as encruzilhadas (compra-se o 2º lado pelo preço normal) | 1 | Almas | 40.000 | — | N03 | 5 | D | (0, 4) |

#### E · Escavação — “Coveiro Bruto”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| E01 | Lâmina Afiada | P | +1 dano | 10 | Cobre | 8 | 1,45 | N00 | 1 | A | (-8, 1) |
| E02 | Braço Firme | P | −5% no intervalo do golpe (mult.) | 10 | Cobre | 30 | 1,6 | E01 Nv1 | 1 | A | (-9, 2) |
| E03 | Pá Larga | D | +1 passo de área (1×1 → 1×2 → 2×2 → 2×3) | 3 | Ossos | 5 | ×6 | E01 Nv1 | 1 | A | (-7, 2) |
| E04 | Golpe Certeiro | P | +4% de chance de crítico | 8 | Cobre | 80 | 1,6 | E02 Nv1 | 1 | A | (-9, 3) |
| E10 | Pisão | At | Clique/Q/A: golpe ×4 na área; recarga 8 s | 1 | Cobre | 400 | — | E02 Nv3 | 1 | A | (-8, 3) |
| E13 | Cava-Funda | R | O dano que passa da vida da camada continua na camada de baixo (D9) | 1 | Ossos | 120 | — | E03 Nv2 | 1 | A | (-7, 3) |
| E05 | Crítico Brutal | P | +0,5 no multiplicador de crítico | 5 | Ossos | 20 | 1,8 | E04 Nv1 | 1 | A | (-10, 4) |
| E11 | Pisão Pesado | P | −1 s na recarga do Pisão | 4 | Cobre | 1.200 | 2 | E10 | 1 | A | (-8, 4) |
| E06 | Pá de Coveiro | D | +1 passo de área (2×3 → 3×3 → 3×4) | 2 | Ossos | 300 | ×4 | E03 Nv3 + E13 | 1 | A | (-7, 4) |
| E12a | Pisão Sísmico | X | O Pisão também acerta o anel de 1 tile em volta da área, com ×2 | 1 | Cobre | 8.000 | — | E11 Nv1 | 1 | A | (-9, 5) |
| E12b | Pisão Ritmado | X | O Pisão dispara sozinho a cada 8 golpes (acessível, bom no gamepad) | 1 | Cobre | 8.000 | — | E11 Nv1 | 1 | A | (-6, 6) |
| E07 | Cavar Fundo | P | +20% de dano no Barro e nas camadas abaixo dele | 5 | Cobre | 1.500 | 1,8 | E13 | 1 | A | (-6, 5) |
| E08 | Lâmina Temperada | P | +3 dano | 8 | Cobre | 12.000 | 1,75 | E07 Nv2 | 1 | A | (-8, 6) |
| E14 | Pá Larguíssima | D | +1 passo de área (3×4 → 4×4) | 1 | Ossos | 12.000 | — | E06 Nv2 | 1 | A | (-7, 6) |
| E09 | Ombro de Ferro | P | −4% no intervalo do golpe | 6 | Cobre | 25.000 | 1,8 | E08 Nv1 | 1 | A | (-9, 7) |
| EX | Pá do Seu Damião | M | Golpe duplo: cada pulso bate de novo com 50% do dano; +1 passo de área | 1 | Almas | 1.500 ×3ⁿ | — | E09 Nv4 + E14 | 1 | A | (-8, 8) |
| E15 | Ferro Fundido | P | ×1,25 de dano | 5 | Cobre | 500.000 | 2,2 | E09 Nv2 | 2 | B | (-9, 8) |
| E16 | Pá de Bronze | D | +1 passo de área (4×4 → 4×5) | 1 | Ossos | 2.500 | — | E14 | 2 | B | (-7, 7) |
| E17 | Rebolo do Ferreiro | P | +3% de crítico e +0,25 no multiplicador | 5 | Cobre | 90 mi | 2 | E15 Nv1 | 3 | C | (-9, 9) |
| E18 | Mestre Coveiro | P | ×1,3 de dano | 5 | Cobre | 360 mi | 2,5 | E15 Nv2 | 3 | C | (-8, 9) |
| E19 | Pá de Cinco Palmos | D | +1 passo de área (4×5 → 5×5) | 1 | Ossos | 90.000 | — | E16 | 3 | C | (-7, 8) |
| E20 | Terremoto | P | Pisão ×1,5 por nível | 3 | Cobre | 10 bi | ×3 | E18 Nv1 | 4 | D | (-9, 10) |
| E21 | Pá do Ceifador | D | ×1,5 de dano e +1 passo de área (até 6×6) | 1 | Ossos | 1,5 mi | — | E19 | 5 | D | (-7, 9) |

#### L · Lanterna — “Noite Longa”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| L01 | Pavio Longo | P | +2 s de óleo | 10 | Cobre | 8 | 1,42 | N00 | 1 | A | (-5, 1) |
| L02 | Vidro Polido | P | Fogo-fátuo +0,5 s | 4 | Cobre | 100 | 1,8 | L01 Nv1 | 1 | A | (-6, 2) |
| L04 | Óleo de Osso | P | Cova aberta dá +0,5 s de óleo | 3 | Ossos | 15 | 2 | L01 Nv2 | 1 | A | (-4, 2) |
| L03 | Isca de Fogo-fátuo | P | +12% de frequência de fogos-fátuos | 4 | Cobre | 160 | 1,8 | L02 Nv1 | 1 | A | (-6, 3) |
| L10 | Fogo Manso | P | Fogos-fátuos duram +1 s | 3 | Cobre | 250 | 1,8 | L02 Nv1 | 1 | A | (-5, 3) |
| L06 | Segundo Fôlego | R | 1× por turno, ao zerar o óleo, a lanterna volta com 5 s | 1 | Almas | 6 | — | L04 Nv1 | 1 | A | (-4, 3) |
| L08 | Querosene | P | +3 s de óleo | 5 | Cobre | 6.000 | 1,8 | L03 Nv1 | 1 | A | (-3, 4) |
| L09 | Pavio Duplo | P | O óleo queima 5% mais devagar (mult.) | 3 | Cobre | 5.000 | 2 | L10 Nv1 | 1 | A | (-5, 4) |
| LX | Lua que Não se Põe | M | +8 s de óleo e Constelação: pegar 3 fogos-fátuos em menos de 6 s para o óleo por 8 s | 1 | Almas | 1.500 ×3ⁿ | — | L08 Nv5 + L09 Nv3 + L10 Nv3 | 1 | A | (-5, 6) |
| L05 | Clarão | At | Botão direito/E/X: 3 s de luz máxima e +50% de dano nos tiles iluminados; custa 2 s de óleo; recarga 20 s | 1 | Cobre | 750.000 | — | L08 Nv1 | 2 | B | (-6, 5) |
| L11 | Clarão Longo | P | +1 s de duração do Clarão | 3 | Cobre | 1,75 mi | 2 | L05 | 2 | B | (-6, 6) |
| L07a | Lua Cheia | X | +25% de dano enquanto o óleo estiver acima de 50% | 1 | Cobre | 5 mi | — | L05 | 2 | B | (-6, 7) |
| L07b | Breu | X | +40% de Cobre enquanto o óleo estiver abaixo de 25% | 1 | Cobre | 5 mi | — | L05 | 2 | B | (-5, 7) |
| L12 | Querosene Refinado | P | +5 s de óleo | 5 | Cobre | 180 mi | 2,2 | L08 Nv5 | 3 | C | (-4, 5) |
| L13 | Lanterna de Ferro | P | Retorno do fogo-fátuo +0,04 (80% → 84% → 88%) | 2 | Cobre | 675 mi | 2,5 | L12 Nv1 | 3 | C | (-4, 6) |
| L14 | Farol | R | O Clarão chama 2 fogos-fátuos para dentro da luz | 1 | Cobre | 15 bi | — | L11 Nv2 | 4 | D | (-6, 8) |
| L15 | Óleo Santo | P | +8 s de óleo | 3 | Cobre | 60 bi | ×3 | L13 Nv1 | 5 | D | (-4, 7) |

#### S · Almas — “Médium”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| S01 | Descanso Eterno | P | +5% de Cobre, Ossos e Almas | 10 | Almas | 3 | 1,6 | N00 · 1ª Alma | 1 | A | (-2, 1) |
| S04 | Alminhas Errantes | D | +1 alminha vagando no campo; tocar nela = +1 Alma | 3 | Almas | 8 | 2,2 | S01 Nv1 | 1 | A | (-3, 2) |
| S07 | Prece | P | +20% de Almas | 4 | Almas | 15 | 2 | S01 Nv2 | 1 | A | (-1, 2) |
| S02 | Embaralhar | P | +1 nova rolagem de Epitáfios por turno | 3 | Almas | 15 | 2,2 | N02 | 2 | B | (-1, 3) |
| S08 | Carta Marcada | P | +5 no peso de Raro e +1 no de Lendário | 3 | Almas | 20 | 2 | N02 | 2 | B | (-2, 3) |
| S09 | Missa de Sétimo Dia | P | +15% de XP do turno | 5 | Almas | 15 | 1,8 | N02 | 2 | B | (-3, 3) |
| S03 | Bola de Cristal | R | Epitáfios mostram 4 opções | 1 | Almas | 270 | — | S02 Nv1 | 3 | C | (-1, 4) |
| S05 | Prenúncio | R | Começa o turno escolhendo 1 Epitáfio Comum entre 3 | 1 | Almas | 450 | — | S03 | 3 | C | (-1, 5) |
| S06 | Coral | R | Cada Alma coletada no turno dá +1 s de óleo e +2% de dano (acumula) | 1 | Almas | 540 | — | S04 Nv2 | 3 | C | (-3, 4) |
| SX | Madame Ossada | M | Lendários 3× mais frequentes; a cada 5 níveis do turno, escolhe 2 cartas | 1 | Almas | 1.500 ×3ⁿ | — | S05 + S06 | 4 | D | (-2, 6) |
| S11 | Alminha Dourada | R | 1 em cada 10 alminhas errantes é dourada e vale 5 Almas | 1 | Almas | 30.000 | — | S04 Nv3 | 5 | D | (-1, 6) |
| S10 | Finados | P | ×1,25 de Cobre, Ossos e Almas | 3 | Almas | 15.000 | 2,5 | S07 Nv4 | 5 | D | (-3, 5) |

#### F · Fortuna — “Ganancioso”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | Bolso Fundo | P | +8% de Cobre | 15 | Cobre | 12 | 1,38 | N00 | 1 | A | (2, 1) |
| F02 | Faro de Osso | P | +2 p.p. de chance de Osso (Terra, Barro, Ossada e camadas fundas) | 8 | Cobre | 50 | 1,65 | F01 Nv1 | 1 | A | (1, 2) |
| F09 | Moeda de Ouro | D | Uma moeda dourada pula no campo (a cada 20 s, −3 s por nível); tocar = +5% do Cobre do turno | 3 | Cobre | 900 | 2 | F01 Nv2 | 1 | A | (3, 2) |
| F04 | Juros dos Mortos | P | +1% de Cobre por cova aberta no turno (acumula) | 5 | Ossos | 20 | 1,9 | F02 Nv1 | 1 | A | (1, 3) |
| F05 | Herança | P | +5% do Cobre do turno como bônus no Resumo | 6 | Cobre | 2.500 | 1,75 | F02 Nv2 | 1 | A | (2, 3) |
| F10 | Bolso de Couro | P | +12% de Cobre | 10 | Cobre | 8.000 | 1,6 | F05 Nv1 | 1 | A | (2, 4) |
| F08 | Cofre Pesado | P | ×1,25 de Cobre | 4 | Cobre | 150.000 | 2,6 | F10 Nv3 | 1 | A | (2, 5) |
| FX | Tesouro da Paróquia | M | ×1,5 de Cobre; o Campo Limpo vira Chuva de Moedas (+50% em vez de +20%) | 1 | Almas | 1.500 ×3ⁿ | — | F08 Nv2 + F09 Nv2 | 2 | B | (2, 7) |
| F03 | Moeda Enterrada | D | Baús Enterrados: 1% por tile cavado até o fundo (+0,5 p.p. por nível); dão Cobre ×25 ou um amuleto | 5 | Cobre | 350.000 | 1,8 | F05 Nv2 | 2 | B | (3, 4) |
| F06 | Freguês | P | −8% nos preços do Mascate | 3 | Cobre | 1,5 mi | 2 | F03 Nv1 | 2 | B | (3, 5) |
| F11 | Olho de Corvo | R | Baús brilham de longe e têm 2× mais chance de amuleto | 1 | Almas | 180 | — | F03 Nv3 | 3 | C | (3, 6) |
| F12 | Dízimo | P | Cada 100 Cobre do turno vira +0,5 Osso no Resumo (× nível) | 4 | Cobre | 180 mi | 2,4 | F08 Nv3 | 3 | C | (1, 6) |
| F13 | Avareza | P | ×1,4 de Cobre | 5 | Cobre | 540 mi | 2,8 | F08 Nv4 | 3 | C | (2, 8) |
| F14 | Herança dos Barões | P | ×1,3 de Cobre e baús ×2 | 3 | Cobre | 10 bi | ×3 | F13 Nv1 | 4 | D | (1, 9) |
| F15 | Moedas do Barqueiro | P | ×1,3 de Cobre | 5 | Cobre | 50 bi | ×3 | F14 Nv1 | 5 | D | (2, 10) |

#### C · Cemitério — “Zelador”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| C01 | Campo Maior | D | +1 de lado no campo (5 → 10) | 5 | Ossos | 3 | ×3 | N00 | 1 | A | (5, 1) |
| C02 | Mais Covas | P | +1 cova simultânea | 3 | Ossos | 20 | ×4 | C01 Nv1 | 1 | A | (4, 2) |
| C03 | Terra Fofa | P | −10% no tempo de regeneração | 6 | Cobre | 60 | 1,7 | C01 Nv1 | 1 | A | (6, 2) |
| C04 | Lápides Antigas | P | +25% na recompensa das covas | 6 | Ossos | 40 | 1,8 | C02 Nv1 | 1 | A | (4, 3) |
| C10 | Chamado dos Mortos | P | +10% de Inquietação por cova (o chefe chega antes) | 5 | Almas | 3 | 1,7 | C02 Nv1 | 1 | A | (5, 3) |
| C06 | Velas de Finados | D | +1 vela no campo: não é cavável; tiles em volta regeneram 2× mais rápido e rendem +25% | 3 | Ossos | 60 | 2,2 | C03 Nv2 | 1 | A | (6, 3) |
| C08 | Cova Funda | D | Nova camada Ossada no fundo de todos os tiles (14 HP, 42 Cobre, 15% de Osso) | 1 | Ossos | 1.200 | — | C04 Nv2 | 1 | A | (4, 4) |
| C11 | Terreno da Paróquia | D | +2 de lado no campo (10 → 12) | 1 | Ossos | 1.500 | — | C01 Nv5 | 2 | B | (5, 4) |
| C07 | Ossário | D | Ossário 2×2 no campo: cada camada quebrada em volta enche 1%; cheio = chuva de Ossos (15 × nível × estágio) | 3 | Ossos | 1.250 | 2,5 | C08 | 2 | B | (4, 5) |
| C15 | Cruzes Pintadas | D | +1 cruz de madeira no campo (cavável, 3× HP do Barro; quebrada = 3 Ossos × estágio; covas nascem perto) | 3 | Ossos | 750 | 2,2 | C06 Nv1 | 2 | B | (6, 4) |
| C14 | Vigília | P | +1 cova simultânea | 3 | Ossos | 18.000 | ×4 | C02 Nv3 | 3 | C | (5, 5) |
| C09a | Covas Duplas | X | 25% das covas novas são Duplas (2×2, recompensa ×3) | 1 | Ossos | 90.000 | — | C07 Nv1 | 3 | C | (4, 6) |
| C09b | Vala Comum | X | Covas nascem coladas; abrir 2 covas em ≤ 3 s = combo ×2 | 1 | Ossos | 90.000 | — | C07 Nv1 | 3 | C | (5, 6) |
| C12 | Campo Santo | D | +2 de lado no campo (12 → 14) | 1 | Ossos | 67.500 | — | C11 | 3 | C | (6, 5) |
| C16 | Terra Preta | P | −8% no tempo de regeneração | 4 | Ossos | 36.000 | 2,2 | C03 Nv6 | 3 | C | (6, 6) |
| CX | Mausoléu da Família | M | A cada turno nasce um Mausoléu 3×3 (3 camadas de mármore, HP 3× Barro): abre como cova ×8 e dá +3 Almas | 1 | Almas | 1.500 ×3ⁿ | — | C09a ou C09b + C07 Nv2 | 3 | C | (4, 7) |
| C13 | Lápides de Mármore | P | ×1,5 na recompensa das covas | 4 | Ossos | 50.000 | 2,6 | C04 Nv6 | 4 | D | (5, 7) |
| C17 | Campo do Bom Descanso | D | +2 de lado no campo (14 → 16 → 18) | 2 | Ossos | 250.000 | ×4 | C12 | 4 | D | (6, 7) |
| C18 | Jardim Florido | R | Na névoa do Jardim, tiles reaparecem com a camada de cima já rachada (−50% HP) | 1 | Ossos | 1,2 mi | — | C17 Nv1 | 5 | D | (6, 8) |

#### A · Ajudantes — “Mestre dos Bichos”

| Id | Nome | Tipo | Efeito por nível | Máx | Moeda | Base | Cresc. | Pré-requisito | Est. | Marco | Grade (k, r) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| A01 | Toupeira Tita | D | Libera a Tita: a cada 2 s emerge num tile e dá 1 golpe (50% do seu dano); níveis: +10% de dano dela | 10 | Almas | 10 | 1,55 | N00 · após o chefe 1 | 2 | B | (8, 1) |
| A03 | Ração Especial | P | +20% de eficiência de todos os ajudantes | 8 | Cobre | 750.000 | 1,9 | A01 Nv1 | 2 | B | (7, 2) |
| A05 | Toca Funda | P | A Tita emerge 0,25 s mais cedo | 3 | Almas | 20 | 2 | A01 Nv2 | 2 | B | (9, 2) |
| A02 | Gato Breu | D | Libera o Gato: marca 1 tile da sorte a cada 10 s (camadas ali valem ×5); níveis: +1 tile | 5 | Almas | 90 | 1,8 | A01 Nv3 | 3 | C | (8, 3) |
| A06 | Sete Vidas | R | O Gato também marca a cova mais próxima: cova da sorte ×3 | 1 | Almas | 360 | — | A02 Nv1 | 3 | C | (9, 4) |
| AX | Bicharada | M | Cada Pisão ou Clarão acorda os ajudantes: 3 s agindo 3× mais rápido; +1 Toupeira | 1 | Almas | 1.500 ×3ⁿ | — | A06 + A03 Nv3 | 3 | C | (8, 5) |
| A07 | Cão Ossinho | D | Libera o Cão: corre até a cova mais próxima e cava nela a cada 1,5 s (100% do seu dano); níveis: −10% de intervalo | 5 | Almas | 1.000 | 1,8 | A02 Nv2 | 4 | D | (7, 4) |
| A08 | Morcegos Gêmeos | D | Liberam os Morcegos: pegam fogos-fátuos e alminhas num raio de 4 tiles e espantam fantasmas | 3 | Almas | 5.000 | 2 | A07 Nv1 | 5 | D | (7, 6) |
| A09 | Osso de Petisco | P | +30% de eficiência de todos os ajudantes | 3 | Almas | 2.500 | 2,5 | A03 Nv5 | 4 | D | (9, 6) |

**Notas de implementação da tabela**
- "Efeito por nível" é o texto do tooltip; o `.tres` traduz em `StatModifier` (stats em §18.2) e/ou `flags` (regras lidas pelo `RunState`). Ex.: E02 = `pulse_interval MUL 0,95`; E13 = flag `excess_carries`; E10 = flag `stomp`.
- Nós com mais de um pai na coluna "Pré-requisito" (ex.: EX = E09 Nv4 + E14) exigem **todos**. CX aceita C09a **ou** C09b.
- L07a/L07b e C09a/C09b têm efeitos condicionais (óleo > 50%, combo de covas): são flags, não stats fixos.

### 6.4 Builds (como cada ramo muda o jeito de cavar)
| Build | Ramo-guia | Como se joga | Raiz-mestra |
|---|---|---|---|
| Coveiro Bruto | E | Cursor parado nas covas, Pisão no ritmo, buracos abertos em 1–2 golpes com Cava-Funda | EX · Pá do Seu Damião |
| Noite Longa | L | Cursor caçando fogos-fátuos; Clarão na hora certa; com Breu, joga no vermelho | LX · Lua que Não se Põe |
| Ganancioso | F | Moedas de ouro, baús, Herança; o Resumo é o momento alto; Mascate | FX · Tesouro da Paróquia |
| Zelador | C | Lê o tabuleiro: velas, cruzes, ossário, covas em combo; menos clique, mais rota | CX · Mausoléu da Família |
| Mestre dos Bichos | A | Posiciona o cursor para combinar com Tita, Gato e Cão | AX · Bicharada |
| Médium | S | Monta a noite com Epitáfios; alminhas e Coral | SX · Madame Ossada |

Simulação (§14): a 1ª Raiz-mestra sai por volta de 1 h e a ordem natural (mais barata primeiro) é LX → EX → SX → FX → CX → AX; com Replantar o jogador testa outra ponta sem recomeçar.

## 7. Epitáfios (cartas da noite)

Cartas em forma de lápide, apresentadas por Madame Ossada (liberadas pelo **N02**, marco B). Duram **só a noite atual**. Pesos: **Comum 70 · Raro 25 · Lendário 5** (S08 +5 Raro e +1 Lendário por nível; SX ×3 Lendário). "Acumula" = pode ser pego de novo na mesma noite. Capelinha: no nível 5 da noite, 1 das 3 é Rara garantida. Embaralhar (S02): +1 nova rolagem por noite por nível.

| # | Epitáfio | Raridade | Tags | Efeito (só nesta noite) | Marco |
|---|---|---|---|---|---|
| 1 | "Aqui jaz a pressa" | Comum | Pá | −12% no intervalo do golpe (acumula) | B |
| 2 | "Bom de pá" | Comum | Pá | +15% de dano (acumula) | B |
| 3 | "Olho gordo" | Comum | Fortuna | +10 p.p. de chance de Osso | B |
| 4 | "Morreu rico" | Comum | Fortuna | +30% de Cobre; −10% do óleo restante agora | B |
| 5 | "Foi pro buraco" | Comum | Cova, Lanterna | Cova aberta dá +1,5 s de óleo (fora do teto do L04) | B |
| 6 | "Família grande" | Comum | Cova | +1 cova simultânea (acumula até +3; respeita o teto 7) | B |
| 7 | "Pó ao pó" | Raro | Pá | A cada 100 camadas quebradas: +1 passo de área por 5 s | B |
| 8 | "Morte súbita" | Lendário | Pá | 1% por tile por golpe de esvaziar o tile inteiro (camadas de solo; não caixão nem chefe) | B |
| 9 | "Que a terra lhe seja leve" | Comum | Pá | A camada de cima de todo tile tem −50% de HP | C |
| 10 | "Corvo amigo" | Comum | Lanterna | Fogos-fátuos aparecem 2× mais | C |
| 11 | "Herança disputada" | Comum | Fortuna, Pá | Críticos dão ×2 de Cobre | C |
| 12 | "Descansa em pedaços" | Raro | Pá | Quebrar camada dá 1 golpe de 25% nos 4 vizinhos (não encadeia) | C |
| 13 | "Partiu cedo" | Raro | Pá, Lanterna | +60% de dano; o óleo queima 25% mais rápido | C |
| 14 | "Enterrado com honras" | Raro | Cova, Fortuna | A cada 5 covas, a próxima é Dourada (×5 Cobre e Almas) | C |
| 15 | "Saudade eterna" | Raro | Cova | Covas e fantasmas dão +1 Alma × estágio | C |
| 16 | "Ressuscitou" | Lendário | Lanterna | Ao zerar o óleo, volta com 50% do óleo inicial (1×) | C |
| 17 | "Velório animado" | Comum | Ajudante | Ajudantes agem 50% mais rápido | D |
| 18 | "Nunca parou de cavar" | Raro | Pá | +5% de dano por golpe seguido com o cursor no mesmo tile (máx. +100%) | D |
| 19 | "Tropeço" | Raro | Pá | −2 passos de área (mín. 1×1); dano ×3 | D |
| 20 | "Vela de sete dias" | Raro | Lanterna, Cova | O óleo não queima por 5 s após cada cova (no máx. 1× a cada 10 s) | D |
| 21 | "Lua de sangue" | Lendário | Pá, Fortuna | Críticos ×5; chance de crítico pela metade | D |
| 22 | "Coveiro das Arábias" | Lendário | Fortuna | Cobre ×2; não caem Ossos nesta noite | D |
| 23 | "Último desejo" | Lendário | Cova | Inquietação ×2 nesta noite | D |
| 24 | "Bênção da Ceifa" | Lendário | Cova, Pá | O chefe leva +50% de dano nesta noite (só aparece na Noite do Chefe) | D |

Totais: 10 Comuns · 8 Raros · 6 Lendários. Marco B entra com 8 (6 C / 1 R / 1 L); C com 16; D com 24. Cada Epitáfio é um `EpitaphData` (§18.3) com modificadores ou flag; ilustração 32×32 por carta (DA §13).

## 8. Ferramentas e Mascate (pás e amuletos)

O **Mascate** (D6) chega ao cemitério depois do chefe 1 e monta a **Barraca** na superfície (§11). Uma loja só, que vende **pás** (uma equipada por vez) e **amuletos** (equipáveis em espaços). Os amuletos são as **Relíquias** do jogo. Preços em Ossos e Almas (as moedas que sobram); F06 (Freguês) dá −8%/nível. Baús (F03) podem trazer um amuleto ainda não comprado (fica de graça). Equipar/trocar: no Mascate ou na Casa do Coveiro, só entre noites.

**Espaços de amuleto:** 2 (marco B, ao chegar o Mascate) → 3 (vitória sobre o chefe 3) → 4 (Coreto dos Mortos).

### 8.1 Pás (formato da área)
L×A = área atual (passos, §4.4). A Pá Velha é a inicial e grátis.
| Pá | Formato | Dano | Intervalo | Especial | Preço | Marco |
|---|---|---|---|---|---|---|
| Pá Velha | Retângulo L×A | ×1 | ×1 | — | — | A |
| **Pá de Bico** | Retângulo com −2 passos (mín. 1×1) | ×1,6 | ×1 | Bate fundo: boa para covas no começo do estágio | 1.000 Ossos | B |
| **Enxadão** | Linha de (L·A + 1) tiles, gira 90° com a roda / R / LB-RB | ×1,3 | ×0,9 | ×2 em caixão | 2.000 Ossos + 60 Almas | B |
| **Picareta** | Cruz com braços do tamanho do maior lado | ×1,5 | ×1,1 | Ignora o dreno de óleo de obstáculos; ×3 em Pedra, Mármore e Raiz | 30.000 Ossos | C |
| **Pá de Jardineiro** | Retângulo com +2 passos | ×0,6 | ×1 | Tiles cavados com ela regeneram 30% mais rápido | 500 Almas | C |
| **Pá Fantasma** | Losango de raio (maior lado − 1, mín. 1) | ×0,8 | ×0,8 | ×3 em fantasmas e chefes; atinge tiles "na névoa" | 3.000 Almas | D |
| **Pá Benta** | Retângulo L×A | ×0,8 no solo | ×1 | ×2 em covas (caixão) e em chefes | 200.000 Ossos | D |

### 8.2 Amuletos
| Amuleto | Efeito (equipado) | Preço | Disponível | Marco |
|---|---|---|---|---|
| Dentadura de Ouro | +12% de Cobre | 300 Ossos | estágio 2 | B |
| Terço de Contas de Osso | +5 p.p. de crítico | 600 Ossos | estágio 2 | B |
| Retrato Oval Rachado | +1 cova simultânea | 60 Almas | estágio 2 | B |
| Ferradura Velha | Baús ×2 de chance; +10% de Cobre | 30.000 Ossos | estágio 3 | C |
| Vela de Sete Dias | +4 s de óleo | 500 Almas | estágio 3 | C |
| Pé de Coelho | No nível 3 da noite, 1 Epitáfio Raro garantido | 800 Almas | estágio 3 | C |
| Sapato de Defunto | Fantasmas 30% mais lentos; +1 Alma por fantasma | 20.000 Ossos | estágio 3 | C |
| Lampião do Seu Damião | +10% de dano; na Escuridão, tiles fora da luz perdem só 25% | 60.000 Ossos | estágio 3 | C |
| Cálice de Estanho | +15% de Cobre | 200.000 Ossos | estágio 4 | D |
| Chave Mestra | Chefes com −10% de HP | 1 mi Ossos | estágio 4 | D |
| Medalhinha da Vó | +1 passo de área com a Pá Velha | 500.000 Ossos | estágio 4 | D |
| Coroa de Flores de Plástico | Covas dão ×1,5 Almas | 4.000 Almas | estágio 4 | D |
| Ampulheta Parada | +6 s de óleo; o amanhecer vem aos 330 s | 6.000 Almas | estágio 5 | D |
| Óculos da Dona Ceifa | Epitáfios mostram +1 opção | 10.000 Almas | estágio 5 | D |

Total: 6 pás à venda + 14 amuletos = **20 itens** (B 5 · C 12 · D 20). Cada item é um `ItemData` (§18.3).

## 9. Ajudantes

Agentes autônomos no campo durante a noite; não gastam óleo; sprites 16×16 (idle 2 + ação 4). Liberados no ramo A com Almas.

| Ajudante | Nó | Comportamento | Valor base (nível) | Marco |
|---|---|---|---|---|
| **Toupeira Tita** | A01 (revela após o chefe 1) | A cada 2 s (−0,25 s/nível de A05, mín. 0,75 s) emerge num tile não vazio e dá 1 golpe 1×1 | 50% do dano do jogador (+10%/nível) | B |
| **Gato Breu** | A02 (estágio 3) | A cada 10 s marca 1 tile da sorte (brilho 26) por 6 s; camadas quebradas ali valem ×5 | +1 tile simultâneo por nível | C |
| **Cão Ossinho** | A07 (estágio 4) | Corre até a cova mais próxima e cava nela a cada 1,5 s | 100% do dano do jogador; −10% de intervalo/nível | D |
| **Morcegos Gêmeos** | A08 (estágio 5) | Pegam fogos-fátuos, moedas e alminhas num raio de 4 tiles do cursor e espantam fantasmas | +1 tile de raio por nível | D |
| Espantalho | — | Pós-1.0 (Ramo Lunar) | — | — |

A03/A09 (eficiência) multiplicam dano e frequência de todos; AX acorda os ajudantes a cada ativo. Sons: `helper_mole`, `helper_cat`, `helper_dog`, `helper_bats` (06, áudio).

## 10. Estágios e chefes

Cada estágio é um **diorama** com paleta, camadas, props, fundo, música e chefe próprios (DA §6). Vencer o chefe dá a **Chave da Cripta** e libera o estágio seguinte no **seletor de estágios** (§11.2). Dá para voltar a qualquer estágio liberado (farm). Tudo é dado: `StageData` + `BossData` (§18.3).

### 10.1 Tabela de estágios
| # | Estágio | Camadas (topo → fundo; + Ossada com C08) | HP × | Cobre × | Ossos × | Almas × | XP × | Obstáculo | Novidade de jogo | Inquietação: covas para 100% | Música | Marco |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Cemitério da Paróquia** | Grama · Terra · Barro | 1 | 1 | 1 | 1 | 1 | Rocha (0–2) | Base: covas, lápides com efeito, velas, moeda de ouro, alminhas | 900 | `mus_area1` | A |
| 2 | **Campo dos Indigentes** | Grama rala · Terra · Lama · Barro | 50 | 7 | 5 | 4 | 3 | Poça de lama (0–3) | Lama; fantasmas travessos tapam buracos; cruzes de madeira | 480 | `mus_area2` | B |
| 3 | **Catacumbas de Pedra** | Terra · Pedra · Barro · Pedra | 250 | 40 | 25 | 16 | 9 | Rocha (2–5) | **Escuridão** (a luz importa) e raízes | 300 | `mus_area3` | C |
| 4 | **Necrópole dos Barões** | Grama aparada (= Grama) · Mármore · Terra · Barro | 1.000 | 180 | 100 | 64 | 27 | Rocha (0–2) | Baú dos Barões; lápide de anjo; mármore pesado | 230 | `mus_area4` | D |
| 5 | **Jardim das Almas** | Névoa · Terra · Névoa · Barro | 4.000 | 800 | 400 | 256 | 81 | Rocha (0–1) | **Névoa** (tiles somem e voltam); lápides flutuantes; 3 fantasmas | 110 | `mus_area5` | D |

- "Covas para 100%" já considera que covas ficam mais raras nos estágios altos (HP maior): a simulação abre ~45 covas/noite no fim do estágio 1 e 8–30 nos estágios 3–5. C10 (+10%/nível) e a Torre do Sino (+25%) aceleram.
- O campo, a área, a árvore e os itens são globais: trocar de estágio só troca o diorama, as camadas e os multiplicadores.
- Entrar num estágio novo pela 1ª vez: diálogo curto (Dona Ceifa) e `stinger_stage_unlock`.

### 10.2 Chefes (Noite do Chefe, §4.11)
Todos reaproveitam o modelo de campo: o chefe é uma entidade que ocupa tiles (`BossData.cells`), recebe o dano dos golpes que acertam esses tiles (cada tile da área sobre ele conta 1 vez; crítico e Pisão valem) e tem um **comportamento** escolhido por enum. HP em pontos de dano absolutos.

| # | Chefe | Ocupa | HP | Comportamento (`BossData.behavior`) | Prêmio da 1ª vitória | Revanche | Marco |
|---|---|---|---|---|---|---|---|
| 1 | **O Caixão Fujão** | 2×2 | **35.000** | `HOP`: a cada **4 s** afunda (0,6 s invulnerável, `boss_sink`) e reaparece num lugar livre (`boss_emerge`). Os tiles onde estava viram Buraco | **Chave I**, 25 Almas, 60 Ossos; libera o **estágio 2**, o **hub** (Mascate e construções), **Replantar** e a **Toupeira Tita**; revela os nós do estágio 2 | 5 Almas | A |
| 2 | **Seu Damião** (coveiro fantasma) | 1×1 andando | **250.000** | `TRAIL`: anda 1 tile/s e **tapa os buracos** por onde passa; cada tile que ele pisa fica **marcado** (brilho ecto) por 3 s; o dano no chefe é o dano útil causado em tiles marcados (não dá para golpeá-lo direto) | **Chave II**, 60 Almas, 600 Ossos; libera o **estágio 3**, o **Gato Breu** e a Picareta/Pá de Jardineiro no Mascate; Damião passa a morar no hub | 12 Almas | B |
| 3 | **A Raiz-Mãe** | núcleo 2×2 + 4 bulbos 1×1 | **800.000** (4 bulbos × 100.000 + núcleo 400.000) | `BULBS`: raízes ligam os bulbos ao núcleo; tiles com raiz levam −50% de dano; enquanto houver bulbo vivo o núcleo é imune; cada bulbo destruído corta a raiz dele | **Chave III**, 150 Almas, 5.000 Ossos; libera o **estágio 4**, o **3º espaço de amuleto** e o Cão Ossinho na árvore | 30 Almas | C |
| 4 | **O Mausoléu Vivo** | 4×4 | **3 mi** (3 fases de 1 mi) | `PHASES`: cada fase é uma "camada" de mármore; ao trocar de fase (`boss_phase`) solta 3 **herdeiros** (fantasmas, 1 golpe cada) que curam o chefe em 2% do HP máx. por segundo enquanto vivos | **Chave IV**, 350 Almas, 40.000 Ossos; libera o **estágio 5**, os Morcegos e a Pá Fantasma | 70 Almas | D |
| 5 | **A Cova da Dona Ceifa** | 3×6 | **9 mi** (6 camadas de 1,5 mi: Grama → Terra → Barro → Pedra → Mármore → Névoa) | `CYCLE`: a camada de cima regenera 10% se ficar 6 s sem levar dano; quebrar a 6ª abre a cova | **Final** (§13.3), 800 Almas, marco "Férias Merecidas", "Continuar cavando" | 160 Almas | D |

- O HUD mostra a barra do chefe com ícone (UI/UX §13.2). Derrota não custa nada; o HP volta cheio.
- Pós-vitória: o hub "revela" em sequência curta (câmera): a Chave voa para o seletor, o estágio novo destranca, os nós novos brotam na árvore (UI/UX §15).

### 10.3 Acesso aos estágios
O destino **Próxima Noite** inicia o estágio atual. A escolha de estágio pertence a esse destino e só aparece quando houver mais de um estágio jogável. No Marco A, existe apenas a Paróquia; não mostrar um painel com lanternas de fases futuras.
## 11. Pátio do Bom Descanso (D7)
A superfície da Árvore é o **Pátio do Bom Descanso**, um hall de navegação integrado ao cenário. Não há painel central com cinco lanternas. Na tela inicial, quatro estações levam a **Raízes/Talentos**, **Próxima Noite**, **Loja** e **Fazenda**. No Marco A, Árvore e Próxima Noite são funcionais; Loja e Fazenda aparecem bloqueadas com indicação do marco futuro. “Próxima Noite” inicia a Paróquia em uma ação. A Árvore de Raízes continua sendo uma tela navegável, com retorno fixo ao Pátio.
### 11.1 Construções
| Construção | Custo | Efeito permanente | Libera | Marco |
|---|---|---|---|---|
| **Barraca do Mascate** | grátis | Abre a loja (§8) | Vitória sobre o chefe 1 | B |
| **Portão Consertado** | 1.500 Cobre | +10% de Cobre | Chefe 1 | B |
| **Casa do Coveiro** | 6.000 Cobre + 150 Ossos | +3 s de óleo; armário para trocar pá e amuletos fora do Mascate | Chefe 1 | B |
| **Capelinha** | 40 Almas | Madame Ossada se muda: no nível 5 da noite, 1 Epitáfio Raro garantido | Chefe 1 + N02 | B |
| **Poço Velho** | 200 mi Cobre | +5 s de óleo | Chefe 2 | C |
| **Canteiro de Crisântemos** | 400 Almas | +25% de XP da noite | Chefe 2 | C |
| **Torre do Sino** | 800 Almas | +25% de Inquietação; revanches dão +50% de Almas | Chefe 2 | C |
| **Galinheiro da Dona Ceifa** | 3.000 Almas | +10% de todo recurso; a galinha bota 1 "ovo" no início da noite (sorteio: +5 s de óleo, 1 Epitáfio Comum ou +1 cova) | Chefe 3 | D |
| **Jazigo da Família** | 30 bi Cobre + 300.000 Ossos | ×1,25 de todo recurso | Chefe 3 | D |
| **Coreto dos Mortos** | 8.000 Almas | ×1,15 de Cobre, **4º espaço de amuleto**, música do coreto e falas extras | Chefe 4 | D |

Construção restaurada: animação de obra (poeira + 3 marteladas, `build_complete`), autosave.

### 11.2 Elementos fixos da superfície
- **Ipê-roxo** no centro (x = 968), sobre o N00.
- Estações do Pátio (§10.3); **Enfrentar ‹chefe›** aparece junto à Próxima Noite só com Inquietação 100%.
- Personagens que vão chegando: Tião (A), Mascate (B), Madame Ossada na Capelinha (B), Seu Damião (C), Dona Ceifa (final).
- Posições, tamanhos e estados: UI/UX §10 e DA §13.
### 11.3 Ganho offline
**Fora do v1.0** (contraria o pilar 4). O antigo F07 "Cofre do Coveiro" saiu da árvore.

## 12. Prestígio: Lua Nova (pós-1.0)
Fora do v1.0 por escopo. O Replantar (N03) e as encruzilhadas cobrem o replay de build. Registro para o pós-1.0: Selos Lunares = `floor(sqrt(Almas da Lua / 50))`; reseta moedas e árvore; mantém estágios, construções, amuletos e marcos; Ramo Lunar (~12 nós, com o Espantalho e +1 opção de Epitáfio).

## 13. Marcos, final e pós-final

### 13.1 Marcos (conquistas internas, estilo Nodebuster)
Baratos de fazer (contadores no save); cada um dá um prêmio pequeno e imediato, aparece num **toast** e fica no **painel de Marcos** (UI/UX §17), aberto pela plaqueta do Tião no hub.
| # | Marco | Condição | Prêmio | Marco de produção |
|---|---|---|---|---|
| 1 | Primeira Cova | Abrir 1 cova | 5 Almas | C |
| 2 | A Fila Andou | 100 covas | +2% de Almas | C |
| 3 | Coveiro de Ofício | 1.000 covas | +5% de Almas | C |
| 4 | Cemitério Inteiro | 10.000 covas | +10% de Almas | C |
| 5 | Mão na Massa | 1.000 camadas quebradas | +2% de Cobre | C |
| 6 | Terra Revolvida | 100.000 camadas | +5% de Cobre | C |
| 7 | Fundo do Poço | 1.000 Ossadas quebradas | +5% de Ossos | C |
| 8 | Campo Limpo | 1º Campo Limpo | 10 Almas | C |
| 9 | Noite em Claro | Noite de 120 s | +2 s de óleo | C |
| 10 | Até o Sol Nascer | Chegar ao amanhecer (300 s) | +3 s de óleo | C |
| 11 | Pisoteio | 500 Pisões | −0,5 s na recarga do Pisão | C |
| 12 | Caça-Fogos | 200 fogos-fátuos | +0,5 s por fogo-fátuo | C |
| 13 | Golpe de Sorte | Um crítico de 10.000 de dano | +2 p.p. de crítico | C |
| 14 | Cofre Cheio | 1 mi de Cobre de uma vez | +5% de Cobre | C |
| 15 | Raízes Profundas | Comprar 1 Raiz-mestra | 50 Almas | C |
| 16 | Faxina Geral | Campo Limpo num campo 14×14 ou maior | +5% de Cobre | D |
| 17 | Sem Pisão | Vencer um chefe sem usar o Pisão | 100 Almas | D |
| 18 | Colecionador | Ter 10 amuletos | +5% de todo recurso | D |
| 19 | Árvore Frondosa | 100 nós no máximo | +5% de todo recurso e título "Jardineiro do Ipê" | D |
| 20 | Férias Merecidas | Ver o final | Selo na tela-título | D |

As 5 Chaves da Cripta aparecem no painel como uma fileira à parte (não são marcos novos). `MilestoneData` em §18.3.

### 13.2 Fim de capítulo (marcos A, B, C)
Builds A, B e C terminam com a tela **"Fim do Capítulo N"** depois da vitória sobre o chefe N: diálogo de Dona Ceifa, cartão do capítulo com estatísticas (tempo, covas, nós, chefe) e os estágios seguintes em silhueta, **Créditos** e **Continuar cavando** (o jogo segue, com tudo o que o build tem). No build D, os capítulos 1–4 não mostram essa tela (só o diálogo e o Resumo especial).

### 13.3 Final e pós-final (marco D)
Vencer **A Cova da Dona Ceifa** → diálogo (6–8 balões) → **cena de encerramento** (UI/UX §19): Dona Ceifa deita na cova, agradece, entrega a foice; o Coveiro olha a fila, que agora é dele; as almas sobem; amanhece pela primeira vez → **créditos** (pergaminho rolando, `mus_ending`) → tela **"Fim"** com estatísticas e o selo "Férias Merecidas" → **Continuar cavando**: o jogo segue sem fim, todos os estágios liberados, revanches abertas, árvore e marcos por completar. A tela-título passa a mostrar Dona Ceifa de chapéu de praia no monte (DA §13). Noites Eternas: pós-1.0.

## 14. Balanceamento e ritmo (simulação)

### 14.1 Método
Simulação em Python (fora do repositório, scratchpad da sessão de design) que reimplementa `run_state.gd` + `field_model.gd` com as regras desta versão: camadas por tile com HP e Cobre por ponto, Cava-Funda, crítico por tile, Pisão, covas com lápides de efeito, velas, Ossada, fogos-fátuos com retorno de 80% e teto de óleo de cova, regeneração, Campo Limpo, amanhecer, Noite do Chefe (60% dos golpes no chefe), 5 estágios, construções e Mascate. **Jogador modelado:** cursor guloso (melhor bloco pelo valor esperado), 25% dos golpes "em trânsito", pega ~85% dos fogos-fátuos, usa o Pisão em 85% das recargas, compra sempre o que custa menos turnos de renda, ~12 s entre noites + 0,6 s por compra. Aproximações: Epitáfios = +2% de dano e Cobre por nível (até 10); ajudantes e amuletos como multiplicadores médios. É um jogador **atento**; um jogador relaxado leva ~20–30% mais tempo.

### 14.2 Resultado (mediana de 5 sementes; faixa entre parênteses)
| Marco de jogo | Tempo | Alvo |
|---|---|---|
| 1º turno | 17 s, **24 Cobre** | 15–25 Cobre (D3) ✔ |
| 1º nó comprado | **27–29 s** | ~30 s ✔ |
| 1ª cova aberta | 1–2 min | 1º–4º turno ✔ |
| Área 1×2 / 2×2 | 2 min / 7 min | — |
| Pisão (E10) | 8 min | 8–10 min ✔ |
| Noite ≥ 60 s | 12 min | ~15 min ✔ |
| Cava-Funda (E13) | 16 min | — |
| Área 3×3 | **34,2 min (33,1–35,0)** | 25–35 min (plano do Marco A) |
| Ossada (C08) | 32 min | — |
| **Chefe 1 · Caixão Fujão** | **40,3 min (39,2–41,4)** | 35–45 ✔ |
| Clarão (L05) | 46 min | — |
| **1ª Raiz-mestra** | **59 min (58–1h03)** | ~1 h ✔ |
| Área 4×4 | 1h05 | — |
| **Chefe 2 · Seu Damião** | **1h23 (1h20–1h29)** | ~1h20 ✔ |
| Área 5×5 · campo 14×14 | 1h50 · 1h51 | — |
| **Chefe 3 · Raiz-Mãe** | **2h13 (2h12–2h19)** | ~2h05 ✔ (+8) |
| **Chefe 4 · Mausoléu Vivo** | **2h55 (2h50–3h00)** | ~2h50 ✔ |
| **Chefe 5 · Final** | **3h46 (3h43–3h49)** | 3–4 h ✔ |
| Campo 18×18 · área 6×6 | 3h50 · 4h14 | — |
| Todas as 6 Raízes-mestras · **árvore inteira no máximo** | **~5h00 (4h57–5h03)** | 5–6 h ✔ (limite de baixo) |
| Maior trecho sem compra | **3–4 noites** | < 5 ✔ |

Duração por estágio: **40,3** · 45 · 50 · 42 · 51 min. Renda por noite (semente 1, entrada → saída do estágio): est. 1: 26 → 450 mil Cobre · est. 2: 0,8 mi → 10 mi · est. 3: 48 mi → 120 mi · est. 4: 330 mi → 540 mi · est. 5: 1 bi → 1,9 tri. Ossos na saída: 1 mil · 5,7 mil · 30 mil · 55 mil · 3 mi. Almas na saída: 200 · 450 · 550 · 1,9 mil · 79 mil por noite.

**Marco A isolado** (só estágio 1 e os 44 nós A): no `tests/sim_campaign.gd`, com 900 covas para a Inquietação e E06 por 300 Ossos, a amostra de cinco sementes libera o 3×3 em 33,1–35,0 min (mediana 34,2) e o chefe em 39,2–41,4 min (mediana 40,3). LX logo depois (com as Almas do chefe); tudo do capítulo exceto a 2ª Raiz-mestra até ~1h05. A 2ª Raiz-mestra (4.500 Almas) fica como meta longa de "Continuar cavando" (> 2 h), aceitável para um capítulo. Os três playtests humanos do §19.1 ainda precisam confirmar a cadência na interface real.

### 14.3 Regras de ajuste (playtest)
1. Chefe 1 antes de 32 min na mediana → +20% em N do estágio 1 e no HP do Caixão; depois de 50 → −20%.
2. Mais de 2 Noites do Chefe perdidas seguidas na mediana → −15% no HP daquele chefe.
3. Alerta "5 noites sem compra" (`game.gd`, telemetria) entre chefes → inserir 1 nó de reforço (+X% barato) no estágio, ou baixar 25% o próximo nó caro.
4. 1ª Raiz-mestra antes de 45 min → subir a base de 1.500 Almas; depois de 1h20 → baixar.
5. Árvore inteira antes de 4h30 → subir as bases do estágio 5 (COST ×1,5); depois de 6h → baixar.
6. **Sensibilidade observada:** nós multiplicativos de dano (E15, E18) são os que mais mudam o ritmo; ×1,25 a mais por nível num único nó encurta o jogo inteiro em ~1 h. Mexer neles por último e com cuidado.

### 14.4 Limites de sanidade
- Intervalo mínimo 0,15 s; área máx. 6×6; covas máx. 7; campo máx. 18×18; nível da noite máx. 15; dano sem teto.
- Números flutuantes: máx. 40 por pulso; acima disso, agregar num número grande no centro.
- Óleo: fogos-fátuos com 80% (soma ≤ 5× o 1º), óleo de cova com teto, Constelação 1× a cada 3 fogos.

## 15. Telas, fluxo e UI

Fonte da verdade: [03_UI_UX.md](03_UI_UX.md) §10–§20. Resumo do fluxo do v1.0:
```
Título ─Novo Jogo─► 1º TURNO ─► Resumo ─► ÁRVORE/HUB (superfície + raízes)
   └─Continuar──────────────────────────► ÁRVORE/HUB
PÁTIO ─Próxima Noite────────────► TURNO (estágio atual) ─► Resumo ─► PÁTIO
           ─Enfrentar ‹chefe›────► NOITE DO CHEFE ─perdeu─► Resumo ("fugiu") ─► ÁRVORE/HUB
                                                   └venceu─► Diálogo ─► Resumo especial ─► revelação no hub
           ─Barraca─► Loja do Mascate (painel) · ─Construção─► painel de obra · ─Tião─► Marcos
           ─Tab─► Ficha do Coveiro · ─N03─► Replantar (confirmação) · ─Esc─► Pausa
Chefe 5 vencido ─► Diálogo final ─► Cena de encerramento ─► Créditos ─► "Fim" ─► Continuar cavando (ÁRVORE/HUB)
(Builds A–C: chefe N vencido ─► Diálogo ─► Resumo especial ─► "Fim do Capítulo N" ─► Continuar cavando / Créditos)
```
- Um turno novo fica sempre a **1 clique** (Cavar ▶; Espaço/Start). No Resumo, **Árvore** e **Mais uma noite** são os dois botões grandes.
- Telas e overlays novos: hub (§10), Mascate (§11), Epitáfio (§12), HUD v2 (§13), diálogo (§14), Resumo pós-chefe (§15), Replantar (§16), marcos (§17), seletor/Enfrentar (§10.3–10.4), fim de capítulo e final (§19), fluxo com transições (§20).

## 16. Controles e acessibilidade

| Ação | Mouse/Teclado | Gamepad | Marco |
|---|---|---|---|
| Mover a área | Mouse | Analógico esquerdo (aceleração; R3 = fino) | A (mouse) · D (gamepad completo) |
| **Pisão** | Clique esquerdo / Q | A | A |
| **Clarão** | Clique direito / E | X | B |
| Girar Enxadão | Roda / R | LB / RB | B |
| Escolher Epitáfio | 1/2/3(/4) ou clique · Embaralhar: Z | D-pad + A · Y | B |
| Pausa | Esc | Start | A |
| Árvore: mover · ramo · centralizar · Ficha | Arrastar/roda/Shift+roda · 1–7 · Home · Tab | Analógico · LB/RB · R3 · Select | A |
| Cavar ▶ / Enfrentar | Espaço / F | Start / Y | A |
| Avançar diálogo | Clique / Espaço / Enter | A | A |

Acessibilidade: volume por canal, reduzir flashes, tremor 0–100%, reduzir movimento, tamanho dos números, pausa ao perder o foco (já existem); **auto-pisão** (A); **pausa automática no Epitáfio sem limite de tempo** (B); **modo daltônico** (letra 3×5 ao lado de cada número de moeda, DA §10.2) e **gamepad completo** (D); legendas dos balões sempre visíveis (são texto).

## 17. Áudio

Direção em UI/UX §8; contratos em `assets/AUDIO_MANIFEST.md`. A trilha e os efeitos do Marco A, incluindo `stomp_ready`, `boss_flee`, `key_get`, `stage_select`, `jingle_chapter_end`, `constellation` e `second_wind`, estão entregues e listados no manifesto. Também estão produzidos (leva 3): `mus_area2..5`, `mus_boss`, `mus_shop`, `mus_ending`, `jingle_boss_win`, `stinger_boss_appear`, `stinger_stage_unlock`, Pisão/Clarão, golpes por material (`dig_bone/mud/stone/marble/mist`), chefe (`boss_*`), cartas (`card_*`), loja (`shop_*`), tabuleiro (`coin_gold`, `chest_open`, `bone_rain`, `soul_wander`, `tombstone_effect`), árvore (`seal`, `respec`, `milestone`, `build_complete`), ajudantes (`helper_mole`, `helper_cat`), vozes (`dialog_blip_*`) e `unrest_warning`. **Ids que faltam para marcos posteriores** (lista completa em 06 §8): `boss_phase`, `card_reroll`, `flare_ready`, `ghost_appear`, `ghost_fill`, `ghost_pop`, `root_break`, `cross_break`, `combo`, `coin_rain`, `mist_fade`, `heir_spawn`, `ceifa_layer`, `helper_dog`, `helper_bats`, `dialog_blip_damiao`, `amb_catacomb`, `amb_mist`, `amb_field`, `ui_toast`, `shop_equip`, `credits_roll` (variação de `mus_title`).
Regra anti-fadiga mantida: pitch ±6%, 3–4 variações, máx. 6 vozes por id.

## 18. Arquitetura técnica (Godot 4.7)

### 18.1 Projeto
Configuração da v1.1 mantida (640×360, integer, Nearest, snap). Campo desenhado por atlas próprio (`field_view.gd`), não `TileMapLayer` (divergência aceita).

### 18.2 Stats e flags
`StatSheet` agrega `(base + Σadd) × Πmul` de fontes nomeadas: `tree`, `items` (pá + amuletos), `hub` (construções), `milestones`, `night` (Epitáfios da noite). **Stats novos/alterados** (base em `BalanceData`):

| Stat | Base | Limites | Uso |
|---|---|---|---|
| `area_step` (substitui `radius`) | 0 | 0–10 | Passos de área (§4.4); `ToolData.cells(anchor, w, h, rot)` |
| `field_size` | **5** | 5–18 | Lado do campo |
| `regen_time` | **18** | ≥ 5 | — |
| `grave_count` | **1** | ≤ 7 | — |
| `oil_burn` | 1 | — | Multiplicador de queima (L09) |
| `wisp_oil` · `wisp_rate` · `wisp_life` · `wisp_decay` | 2 · 1 · 5 · **0,8** | decay ≤ 0,92 | §4.5 |
| `oil_per_grave` | 0 | teto 3 s/nível/noite | L04 |
| `deep_mult` | 1 | — | E07 (Barro e abaixo: camadas com `deep = true`) |
| `stomp_cd` · `stomp_mult` · `flare_time` | 8 · 4 · 3 | cd ≥ 4 | Ativos |
| `copper_mult` · `bone_chance` · `soul_mult` · `all_mult` | 1 · 0 · 1 · 1 | — | Moedas (`all_mult` multiplica as 3) |
| `grave_reward` · `grave_interest` · `inheritance` · `unrest_mult` | 1 · 0 · 0 · 1 | — | Covas, F04, F05, C10 |
| `candles` · `crosses` · `ossuary` · `wanderers` · `gold_coin` · `chest_chance` | 0 | — | Elementos do tabuleiro |
| `helper_tita/cat/dog/bats` · `helper_mult` · `tita_speed` | 0 · 1 · 0 | — | Ajudantes |
| `xp_mult` · `rerolls` · `rare_weight` · `epitaph_options` | 1 · 0 · 0 · 3 | opções ≤ 5 | Epitáfios |
| `amulet_slots` · `shop_discount` · `boss_damage` | 2 · 0 · 1 | — | Mascate, chefes |

**Flags de regra** (`SkillNodeData.flags`, `ItemData.flags`, `EpitaphData.flags`): `stat_sheet`, `epitaphs`, `respec`, `both_sides`, `stomp`, `stomp_ring`, `stomp_auto`, `excess_carries`, `double_hit`, `flare`, `flare_wisps`, `second_wind`, `constellation`, `ossuary_layer`, `coin_rain`, `crow_eye`, `mausoleum`, `garden`, `cat_grave`, `menagerie`, `choir`, `omen`, `epitaph_4`, `seer_master`, `golden_wanderer`. O `RunState` lê as flags do snapshot no início da noite.

### 18.3 Dados (`data/`, um `.tres` por item)
| Tipo | Pasta | Campos principais | Marco |
|---|---|---|---|
| `SkillNodeData` (ampliado) | `skill_nodes/` | + `kind` (P/At/R/D/X/M), `exclusive_group`, `requires: Array[{id, level}]` (substitui a topologia só por `children`; `children` continua para desenhar as raízes), `reveal_trigger` (`turn_2`, `first_soul`, `boss_1`…), `required_stage` (renomeia `required_area`), `flags`, `grid: Vector2i` (k, r; `tree_position` passa a ser calculado) | A |
| `LayerData` (ampliado) | `areas/layers/` | + `deep: bool`, `xp` por camada, `sfx_key` novos | A |
| `StageData` (renomeia/estende `AreaData`) | `stages/stage_N.tres` | camadas, `hp_mult`, `copper_mult`, `bones_mult`, `souls_mult`, `xp_mult`, `obstacle` (`BoardElementData`), `elements` (lista com pesos/quantidade), `tomb_weights` (7 tipos), `graves_for_unrest`, `boss` (`BossData`), atlas/fundo/bloco/música | A (1) · B (2) · C (3) · D (4–5) |
| `BossData` | `bosses/` | `id`, `display_name`, `cells` (Vector2i), `hp`, `behavior` (`HOP`, `TRAIL`, `BULBS`, `PHASES`, `CYCLE`), parâmetros do comportamento (dicionário), prêmios (moedas, `unlocks: Array[StringName]`), revanche, sprite/ícone, diálogos de início/vitória | A (1) … D (5) |
| `BoardElementData` | `board/` | `id`, `kind` (obstáculo, bloqueado, cavável, móvel), `size`, `hp_rule`, `rewards`, `aura` (raio, regen_mult, copper_mult), `spawn` (nó/estágio, quantidade), sprite | A |
| `EpitaphData` | `epitaphs/` | `id`, nome, raridade, tags, `modifiers`, `flags`, `stacks`, `max_stacks`, `boss_only`, ilustração | B |
| `ItemData` | `items/` | `id`, `slot` (`SHOVEL`/`AMULET`), custo `{moeda: v}`, `required_stage`, `modifiers`, `flags`, `shape` (pás), ícone | B |
| `BuildingData` | `hub/` | `id`, custo, `unlock` (chefe), `modifiers`, posição na superfície, sprites ruína/restaurada | B |
| `MilestoneData` | `milestones/` | `id`, contador (`graves`, `layers`, `ossada`, `stomps`, `wisps`, `crit_max`, `copper_peak`, `night_len`, `field_clear_size`, `masters`, `maxed_nodes`, `amulets`, `boss_no_stomp`, `ending`), alvo, prêmio | C |
| `DialogueData` | `dialogue/` | `id`, gatilho, lista de `{personagem, retrato, texto}`, `once` | A |
| `BalanceData` (ampliado) | `balance.tres` | bases da §18.2, `grave_copper` 30, `grave_bones` 2–5, `coffin_hp_mult` **1,5**, `grave_open_time` 3, `field_clear_bonus` 0,20 (desde o último), `wisp_decay` 0,8, `oil_grave_cap` 3, XP `10 × 1,45^(n−1)`, `max_night_level` 15, `master_base` **1.500** e `master_growth` **3**, `respec_cost_per_stage` 5, `unrest_tremor_souls` 0,25 | A |

### 18.4 Modelo do campo e do turno
- `FieldModel.Kind` ganha: `CANDLE`, `CROSS`, `PUDDLE`, `OSSUARY`, `ROOT`, `CHEST`, `BOSS`, `MAUSOLEUM` (cada um com regra no `RunState`); entidades móveis (fantasma, alminha, moeda, Damião, herdeiros) ficam numa lista própria como os fogos-fátuos.
- `apply_damage(cell, amount, carry: bool)`: com `carry` o excedente desce em cascata (Cava-Funda) e o `useful` soma por camada.
- `ToolData.cells(anchor, w, h, rotation)` com formas `RECT`, `LINE`, `CROSS`, `DIAMOND`.
- `RunState` ganha: ativos (`use_stomp()`, `use_flare()`, recargas), fila de Epitáfios com pausa, chefe (`BossState` por comportamento), elementos do tabuleiro, tipos de lápide, teto de óleo de cova, Campo Limpo "desde o último".
- Ordem do pulso (v2): 1. tiles da área (pá + passos + âncora); 2. por tile: crítico → dano (carry) → Cobre por ponto → quebra (XP, Osso, eventos); 3. chefe; 4. covas completas (tipo de lápide); 5. elementos (ossário, cruz, raiz); 6. dreno de obstáculo; 7. Campo Limpo; 8. VFX/SFX agregados.

### 18.5 Save v2
- `user://save.json` com `version: 2`. Novos blocos: `progress.stage_unlocked`, `progress.bosses` (vitórias, tentativas), `unrest` por estágio, `items` (comprados, equipados), `hub` (construções), `milestones` (contadores, concluídos), `dialogue_seen`, `tree.masters_bought`, `respec_count`, `chapter_end_seen`.
- **Migração v1 → v2** (saves da demo/M0): devolve 100% do que foi gasto na árvore antiga em Cobre/Ossos, zera a árvore (ids mudaram), mantém moedas, opções e telemetria; Inquietação zerada.
- **Compatibilidade entre marcos:** um save do build A abre no B, C e D sem perda (campos novos com padrão; ids de nós estáveis; nós novos aparecem como novidade "!"). Teste automático por marco (`tests/test_save_compat.tscn`).

## 19. Marcos jogáveis e escopo

Cada marco é um **build completo**: do título ao fim do capítulo, sem placeholder visível no que entra, sem crash, save compatível com o marco anterior. Dentro de cada marco o trabalho corre em **ondas** (W1 código de regras → W2 conteúdo/estágio → W3 meta → W4 noite → W5 polimento), detalhadas em [06_PLANO_V1.md](06_PLANO_V1.md).

### 19.1 Marco A · "Capítulo 1: O Cemitério da Paróquia" (~40–60 min)
- **Conteúdo:** título → estágio 1 com a economia nova (§4.3–4.7, D1–D3, D10); árvore de **44 nós** (todos os A), com **EX e LX** (Raízes-mestras em Almas), encruzilhada E12, **Pisão**, **Cava-Funda**, Ossada; lápides com efeito (3 tipos), velas, moeda de ouro, alminhas; Ficha do Coveiro; câmera nova da Árvore (atalhos, Centralizar, minimapa); Inquietação → **Enfrentar o Caixão Fujão** (ação na estação Próxima Noite do Pátio) → Noite do Chefe → vitória → diálogo com retrato (Dona Ceifa, Tião) → Resumo especial → **"Fim do Capítulo 1"** com Créditos e Continuar cavando; pausa com Abandonar/Voltar ao título; auto-pisão; save v2 com migração.
- **Fora do A:** hub com construções, Mascate, Epitáfios (barra de XP oculta), ajudantes, estágio 2.
- **Pronto quando:** chefe 1 aos 35–45 min (playtest interno, 3 pessoas); 1º nó ≤ 40 s; nenhuma sequência de 5 noites sem compra; nenhum asset placeholder no que entra; testes headless verdes (`test_core`, `test_economy_v2`, `test_boss_hop`, `test_boss_outcomes`, `test_save_migration`, `test_hall_skill_panel_runtime`, `test_dialogue_runtime`, `test_chapter_end_runtime`, `test_chapter_end_flow`).

### 19.2 Marco B · "Capítulo 2: O Campo dos Indigentes" (~1h20–1h30)
- **Conteúdo:** hub na superfície (Portão, Casa do Coveiro, Capelinha + Barraca do Mascate), **seletor de estágios**, **Mascate** com 5 itens (Pá de Bico, Enxadão, Dentadura, Terço, Retrato) e 2 espaços; **estágio 2** (diorama, lama, fantasmas, cruzes, poça de lama, lápide rachada) + **Seu Damião**; árvore **64 nós** (+20 B: FX, L07, Clarão, N02, N03…); **Epitáfios: 8**; **Replantar**; **Toupeira Tita**; baús e Ossário; retratos Mascate e Madame Ossada; "Fim do Capítulo 2".
- **Pronto quando:** chefe 2 a ~1h20 (±15 min); save do A abre e continua; cada noite do estágio 2 oferece ≥ 2 decisões (Epitáfio, amuleto/pá); loja, hub e Epitáfios com arte e som finais.

### 19.3 Marco C · "Capítulo 3: As Catacumbas de Pedra" (~2h10–2h20)
- **Conteúdo:** **estágio 3** (escuridão, raízes, pedra) + **A Raiz-Mãe**; árvore **84 nós** (+20 C: CX, AX, C09, E17–E19…); Mascate com **12 itens** e 3º espaço; **Epitáfios: 16**; **Gato Breu**; construções +3 (Poço, Canteiro, Torre); **15 marcos** com toast e painel; lápide com coroa; Mausoléu 3×3 (CX); "Fim do Capítulo 3".
- **Pronto quando:** chefe 3 a ~2h10 (±15); saves do A e do B compatíveis; marcos disparam sem custo de desempenho (contadores no fim do pulso).

### 19.4 Marco D · v1.0 (~3h30–4h até o final; ~5 h para 100%)
- **Conteúdo:** **estágios 4 e 5** + **Mausoléu Vivo** e **Cova da Dona Ceifa**; **final** (cena + créditos + "Fim" + Continuar cavando); árvore **100 nós** com **Duas Raízes** e SX; Mascate **20 itens** e 4º espaço (Coreto); **Epitáfios: 24**; **4 ajudantes** (+Cão, Morcegos); **9 construções**; **20 marcos**; Baú dos Barões, névoa, lápides de anjo e flutuante; gamepad completo, modo daltônico; balanceamento final pela §14.3; revisão de texto.
- **Pronto quando:** final aos 3h30–4h e árvore inteira a ~5–6 h (mediana de 5 testadores ±20%); zero bloqueio de progressão; desempenho estável com campo 18×18 e área 6×6 (60 fps no hardware-alvo); saves de A–C compatíveis.

### 19.5 Fora de todos os marcos (pós-1.0)
Lua Nova e Ramo Lunar (§12), Codex completo (Relíquias/Bestiário; no v1.0 os amuletos aparecem no Mascate e os marcos no painel), localização EN, Steam (página, conquistas, nuvem), ganho offline, Noites Eternas, hub como cena separada, modos desafio, "árvore embaralhada".

## 20. Riscos

| Risco | Mitigação |
|---|---|
| Ritmo sensível a nós multiplicativos (§14.3.6) | Números em `.tres`; teste de campanha em Godot (`tests/sim_campaign.gd`, W1 do A) reproduzindo a simulação; ajustar por último E15/E18 |
| Inquietação lenta para quem abre menos covas | Medir covas/noite na telemetria; N do estágio em `StageData`; Torre e C10 aceleram; tremores dão incentivo, não punição |
| Árvore grande ilegível | Faixas por ramo, atalhos 1–7, minimapa, silhuetas das mestras, estado selado distinto |
| Interrupção excessiva por Epitáfios | Teto de 15 níveis por noite, XP do estágio ×3 por estágio; medir picks/noite (alvo 4–10) |
| Escopo de arte (5 dioramas + 5 chefes) | Mesmos layouts de atlas por estágio (já provado no estágio 2); chefes com comportamento por enum e poucos frames; produção por estágio em paralelo |
| Saves quebrando entre marcos | Save v2 com migração e teste de compatibilidade por marco |
| Desempenho com 324 tiles e área 36 | Pulso já é O(área); VFX agregados; teto de números; perfilar no D |

## 21. Glossário
**Turno/noite**: uma run, limitada pelo óleo. **Pulso/golpe**: tick de dano da área. **Passo de área**: +1 de lado alternado (1×1 → 1×2 → 2×2…). **Camada**: um nível de HP de um tile. **Buraco**: tile sem camadas. **Cova**: alvo de 2 tiles marcado por lápide. **Lápide com efeito**: tipo de lápide com regra própria. **Inquietação**: medidor por estágio que libera a Noite do Chefe. **Noite do Chefe**: noite com o chefe no campo, escolhida pelo jogador. **Chave da Cripta**: prêmio do chefe que libera o próximo estágio. **Epitáfio**: carta da noite. **Raízes**: árvore de habilidades. **Raiz-mestra**: nó-ponta de um ramo (Almas, ×3 cada). **Encruzilhada**: par de nós, escolha 1 (Duas Raízes libera o outro). **Replantar**: respec. **Mascate**: loja de pás e amuletos. **Amuleto**: item equipável (as Relíquias do jogo). **Hub**: a superfície da Árvore. **Marco**: conquista interna com prêmio pequeno (e também: build jogável A–D, §19).
