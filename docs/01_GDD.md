# Dig Dig Graves — Game Design Document

> Versão 1.0 · 26/10/2026 · Engine: Godot 4.7 (GL Compatibility) · Status: pré-produção
> Documentos irmãos: [00_PESQUISA_SUPERREAP.md](00_PESQUISA_SUPERREAP.md) (referência) e [02_DIRECAO_DE_ARTE.md](02_DIRECAO_DE_ARTE.md) (visual, paleta, especificação de sprites).
> Todos os números deste documento são **valores iniciais de balanceamento**: o formato das fórmulas é decisão de design, os coeficientes são para ajustar em playtest.

---

## Sumário
1. Ficha técnica
2. Visão e pilares
3. Mundo, tom e personagens
4. Mecânica principal: o Turno da Noite
5. Recursos e economia
6. Árvore de habilidades: as Raízes
7. Epitáfios (cartas da run)
8. Ferramentas
9. Ajudantes
10. Áreas e chefes
11. Meta: restaurar o Cemitério
12. Prestígio: Lua Nova
13. Relíquias, conquistas e final
14. Balanceamento e ritmo
15. Telas, fluxo e UI
16. Controles e acessibilidade
17. Áudio
18. Arquitetura técnica (Godot)
19. Escopo e marcos
20. Riscos
21. Glossário

---

## 1. Ficha técnica

| Item | Definição |
|---|---|
| Título | **Dig Dig Graves** (PT-BR: "Cava Cava Covas" como subtítulo de marketing) |
| Gênero | Incremental ativo com árvore de habilidades e elementos roguelite (cartas por run) |
| Referências | SuperReap (estrutura, cartas, fazenda→cemitério), Nodebuster (área do cursor em pulsos, árvore, chefes), Stardew Valley (tom acolhedor) |
| Câmera | 2D isométrica (proporção 2:1), fixa, sem rotação |
| Arte | Pixel art, resolução interna 640×360, escala inteira |
| Plataforma | PC (Windows; Linux/Steam Deck como alvo secundário) via Steam |
| Controles | Mouse (principal), gamepad completo |
| Duração alvo | 5–7 h até o final, +3–5 h para 100% |
| Preço alvo | US$ 4,99 (R$ 15–20 com preço regional) |
| Idiomas no lançamento | PT-BR e EN |
| Público | Fãs de incrementais curtos e "satisfatórios" (Nodebuster, SuperReap, Cookie Clicker, Vampire Survivors light), 16+, sessões de 5–60 min |
| Classificação | Livre/10+: tema de morte tratado com humor, sem sangue |

**Pitch em uma frase:** você é o novo coveiro do Cemitério do Bom Descanso e, a cada noite, até a lanterna apagar, passa a pá por um terreno enorme abrindo covas para as almas que esperam na fila — cada pá de terra vira moeda, cada moeda vira raiz na sua árvore de habilidades.

## 2. Visão e pilares

### 2.1 Fantasia do jogador
Começar com uma pá enferrujada que mal arranha a grama e terminar revolvendo um campo inteiro em segundos, numa chuva de torrões, ossos e almas subindo para o céu.

### 2.2 Pilares (critério de corte para toda decisão)
1. **Cavar tem que ser gostoso.** Cada golpe tem retorno visual e sonoro: torrão voando, número subindo, buraco ficando mais fundo. Se uma feature atrapalha a leitura do campo, ela sai.
2. **Sempre há um próximo nó.** Ao fim de toda noite o jogador consegue comprar pelo menos uma coisa ou vê exatamente quanto falta. Nada de "noite perdida".
3. **Macabro aconchegante.** Cemitério à noite, mas com velas, flores, bichinhos e humor. Esqueletos fofos, nunca gore.
4. **Ativo, não AFK.** O jogador mira; o jogo recompensa atenção (covas, fogos-fátuos, chefes). Automação existe só no fim e nunca substitui o turno ativo.
5. **Curto e respeitoso.** Turnos curtos, final claro, nenhuma parede de grind maior que ~10 min sem novidade.

### 2.3 Diferenciais em relação à referência
| SuperReap / Nodebuster | Dig Dig Graves |
|---|---|
| Campo "plano": cortou, sumiu | **Profundidade**: cada tile tem camadas (grama → terra → barro → …); o buraco fica visivelmente mais fundo |
| Alvos isolados | **Covas**: objetivos de 2 tiles marcados por lápides, que pagam muito mais e alimentam o chefe |
| Área sempre quadrada | **Ferramentas mudam o formato da área** (quadrado, cruz, linha, losango) |
| Timer genérico | **Óleo da lanterna**, que também é a luz quente do cursor: o tempo da run é visível no próprio campo |
| Árvore abstrata | Árvore de **raízes** crescendo no subsolo, coerente com o tema |

## 3. Mundo, tom e personagens

### 3.1 Cenário
**Vila do Bom Descanso**, um vilarejo fictício de interior, inspirado em cemitérios brasileiros antigos: cruzes de madeira, lápides com foto oval, velas de Finados, crisântemos, cata-ventos coloridos, muro caiado. Sempre noite, lua grande.

### 3.2 Premissa
O antigo coveiro, Seu Damião, sumiu há anos. Sem covas, as almas do vilarejo não têm onde descansar e formam uma **fila** cada vez maior na porta do cemitério. A própria Morte, **Dona Ceifa**, cansada de esperar, contrata você. Cada cova aberta deixa uma alma descansar. O objetivo final de Dona Ceifa (revelado no fim) é que você abra uma cova para *ela*: quer finalmente tirar férias.

### 3.3 Elenco
| Personagem | Função | Tom |
|---|---|---|
| **O Coveiro** (jogador) | Avatar no hub; em jogo é representado pela pá-cursor | Silencioso, chapéu de palha furado, lanterna |
| **Dona Ceifa** | Contratante; entrega marcos/objetivos e narra o início e fim de cada área | Burocrática, cansada, engraçada; foice usada como bengala |
| **Madame Ossada** | Vidente esqueleto; libera e apresenta os **Epitáfios** (cartas) | Dramática, fala por enigmas e trocadilhos |
| **Tião, o Corvo** | Tutorial, dicas, Codex de Relíquias | Fofoqueiro e ganancioso por brilho |
| **Seu Damião** | Antigo coveiro, agora fantasma; chefe da Área 2, depois vira aliado no hub | Rabugento, competitivo |
| Ajudantes | Toupeira Tita, Gato Breu, Cão Ossinho, Morcegos Gêmeos, Espantalho (ver §9) | Mascotes |

### 3.4 Narrativa entregue em pílulas
Sem cutscenes longas: 2–4 balões de diálogo ao desbloquear cada área, ao derrotar cada chefe e no final. Total estimado: ~80 falas.

## 4. Mecânica principal: o Turno da Noite

### 4.1 Visão geral do turno (a "run")
1. O jogador sai do hub e começa um **Turno** numa área escolhida.
2. O **Óleo da Lanterna** começa a queimar (segundos).
3. Onde o cursor estiver, a pá golpeia automaticamente em **pulsos**: todos os tiles dentro da **área de escavação** levam dano.
4. Camadas quebradas soltam **Cobre**, às vezes **Ossos**, e dão **XP do Turno**.
5. Subir de nível no turno → **escolher 1 de 3 Epitáfios** (bônus que duram só essa noite).
6. **Covas** abertas dão **Almas** e enchem a **Inquietação**; quando ela chega a 100%, aparece o **chefe** da área.
7. O óleo acaba (ou o sol nasce) → **Resumo do Turno** → **Árvore de Habilidades** → próximo turno.

Duração: 15 s no primeiro turno, 60–120 s no meio do jogo, **teto absoluto de 300 s** ("o sol nasce"). O teto existe para impedir que o fim de jogo vire espera passiva (crítica nº 1 do Nodebuster).

### 4.2 O campo
- Grade isométrica de **N×N tiles** (losango 32×16 px). Área 1 começa em 12×12 e cresce até 18×18 via árvore.
- Câmera fixa e o campo inteiro sempre visível (até 18×18 = 576×288 px dentro de 640×360).
- Elementos do campo: **tiles de solo**, **covas** (lápide + 2 tiles), **obstáculos** (rochas, raízes), **eventos** (fogos-fátuos, fantasmas, baús).
- Bordas decorativas (muro, árvores, cercas) ficam fora da grade jogável.

### 4.3 Tiles e camadas
Cada tile tem uma pilha de camadas. O dano sempre atinge a camada do topo; o excedente **não** passa para a camada de baixo (evita one-shots precoces; o Epitáfio "Morte Súbita" quebra essa regra de propósito).

| Camada | Aparece em | HP base | Cobre | XP | Chance de Osso |
|---|---|---|---|---|---|
| Grama | Área 1–4 | 2 | 1 | 1 | 0% |
| Terra | Todas | 4 | 2 | 2 | 3% |
| Barro | Todas | 8 | 4 | 3 | 6% |
| Lama | Área 2+ | 12 | 6 | 4 | 6% |
| Pedra | Área 3+ | 20 | 10 | 6 | 8% |
| Mármore | Área 4+ | 32 | 16 | 8 | 10% |
| Névoa | Área 5 | 40 | 20 | 10 | 12% |

- HP e recompensas de cada área são multiplicados pelo **multiplicador da área** (§14.2).
- **Cobre é pago por ponto de dano causado** (Cobre da camada ÷ HP da camada, por ponto; frações acumulam no turno). Dano acima do HP restante da camada não paga. **Ossos e XP** são pagos só quando a camada quebra. Assim nenhum golpe é perdido e jogar ativo nunca rende menos que ficar parado (decisão v1.1, após a simulação do M0).
- Tile sem camadas = **Buraco**. Visualmente, cada camada removida deixa o buraco mais escuro e mais fundo (ver Direção de Arte §7).
- **Ordem das camadas por área:** Área 1: Grama/Terra/Barro. Área 2: Grama/Terra/Lama/Barro. Área 3: Terra/Pedra/Barro/Pedra. Área 4: Grama/Mármore/Terra/Barro. Área 5: Névoa/Terra/Névoa/Barro.

### 4.4 Área de escavação e pulso
| Stat | Valor inicial (Pá Velha) |
|---|---|
| Dano por golpe | 1 |
| Intervalo entre golpes | 1,00 s (mínimo absoluto 0,15 s) |
| Raio | 1 → quadrado de 3×3 tiles na grade (visualmente um losango) |
| Chance de crítico | 0% |
| Multiplicador de crítico | ×2 |

- O pulso é automático e global (um relógio único), não depende de clique. Visual: o losango da área "pisca" e a pá desce.
- O centro da área é o tile sob o cursor (conversão tela→grade em §18.4). A área é recortada nas bordas do campo.
- Crítico é rolado **por tile**, não por golpe (vários números pequenos amarelos = mais satisfatório).
- **Pisão** (habilidade ativa, nó E10): clique/botão A → golpe de dano ×4 na área atual, recarga 8 s. Opcional: o jogo é jogável sem clicar.

### 4.5 Óleo da Lanterna (o timer)
- Começa em **15 s** e queima 1 s/s.
- **Rochas** (obstáculos) drenam 0,5 s de óleo por pulso em que estiverem dentro da área, a menos que a ferramenta seja a Picareta.
- **Fogos-fátuos** aparecem aleatoriamente (1 a cada ~12 s no início); passar o cursor por eles dá **+2 s** de óleo. Somem após 5 s.
- O **raio de luz** quente ao redor do cursor encolhe à medida que o óleo acaba: o tempo é lido no próprio campo, não só no HUD. Raio pela fração do óleo inicial: > 75% → 4, > 50% → 3, > 25% → 2, senão 1 (círculo de raio r+0,5 na grade, anel em xadrez até r+1,5).
- Recursos do turno são creditados ao fim do turno; abandonar o turno pela pausa os perde.
- **Amanhecer:** aos 300 s de turno o sol nasce, independentemente do óleo restante. Óleo sobrando vira bônus de Cobre no resumo (1 s = 2% do Cobre do turno).

### 4.6 Covas
- Uma **lápide** marca uma cova de **2 tiles** (orientação aleatória NE ou NO). Os tiles de cova têm todas as camadas da área **mais** a camada **Caixão** (HP = 2× a camada mais dura da área; v1.0 dizia 5×, o que empurrava a 1ª cova para o 3º turno). Caixão e rochas não pagam Cobre por ponto: a recompensa da cova é o pacote da abertura.
- O tile da lápide é **bloqueado**: não é cavável, não conta para o CAMPO LIMPO e volta a ser solo normal quando a cova fecha. Covas surgem só sobre tiles intactos, com 1 tile de folga entre elas.
- Quando os 2 caixões quebram → **Cova Aberta**: uma alma sobe (VFX), hit-stop de 2 frames e:
  - Cobre = 25 × multiplicador da área
  - **1 Alma** (garantida)
  - 2–5 Ossos (garantidos)
  - 15 XP × multiplicador de XP da área
  - **+10% de Inquietação**
- Após 3 s, a cova aberta se fecha (vira 2 tiles normais regenerando) e uma nova lápide surge em outro lugar livre.
- Covas simultâneas: 2 no início, até 7 via árvore (C01).
- Variantes desbloqueáveis: **Cova Dupla** (2×2, recompensa ×3) e **Mausoléu** (3×3, recompensa ×8, Área 4).

### 4.7 Regeneração (regra anti-bug, ver pesquisa §4)
- Só tiles **totalmente cavados (Buraco)** regeneram. Um tile parcialmente cavado nunca recupera camadas.
- Tempo para regenerar: **25 s** (mínimo 6 s via árvore). Ao regenerar, o tile volta com todas as camadas, com uma animação de terra "fechando".
- **Campo Limpo:** se 100% dos tiles estiverem como Buraco ao mesmo tempo, aparece "CAMPO LIMPO!", o jogador ganha +20% do Cobre do turno e todo o campo regenera instantaneamente. É um momento de pico intencional para o meio/fim de cada área.
- Não existe "spawn" de tiles: o número de tiles é sempre N×N. A densidade não pode passar de 100% nem ficar travada cheia.

### 4.8 Obstáculos e eventos
| Elemento | Área | Comportamento |
|---|---|---|
| Rocha | 1+ (raras), 3 (comuns) | Ocupa um tile e não dá recompensa; drena óleo (§4.5); HP 30× camada base; ao quebrar, solta 1 Osso |
| Raiz | 3+ | Liga 2–4 tiles; enquanto existir, esses tiles levam −50% de dano; quebrá-la solta Cobre ×10 |
| Fogo-fátuo | Todas | +2 s de óleo ao tocar |
| Fantasma Travesso | 2+ | Flutua devagar; se passar por cima de um Buraco, "tapa" o buraco (regenera na hora). Toma dano como um tile (HP baixo) e solta Almas ×0,5 (acumula frações) |
| Baú Enterrado | Todas (raro) | Aparece embaixo de um tile (brilho sutil); ao chegar no fundo: Cobre ×25 ou **Relíquia** (§13.1) |

### 4.9 XP do turno e Epitáfios
- XP necessária do nível n para n+1: `10 × 1,35^(n−1)`, arredondada.
- O nível reseta a cada turno. Ao subir de nível, o jogo **pausa** e mostra 3 Epitáfios; o jogador escolhe 1.
- Liberado pelo nó **"Visita da Vidente"** (custo baixo, perto do centro) a partir do 2º turno, para os primeiros turnos ficarem simples.
- Se vários níveis sobem no mesmo pulso, as escolhas ficam numa fila (uma tela por vez).

### 4.10 Fim do turno
O óleo chega a 0 → a pá dá um último golpe → fade para a tela **Resumo do Turno** (§15). Todo recurso coletado é creditado automaticamente: não existe drop que precise ser "pego". Os ícones voam até o HUD só como feedback.

## 5. Recursos e economia

| Recurso | Ícone | Origem | Uso |
|---|---|---|---|
| **Cobre** | Moeda com furo | Toda camada quebrada, covas, baús | Maioria dos nós da árvore e construções do hub |
| **Ossos** | Osso | Chance por camada; covas (garantido); rochas | Nós de área/raio/ferramentas e construções |
| **Almas** | Chama azul com olhinhos | Covas (1 cada), fantasmas, chefes | Ajudantes, ramo Almas, construções avançadas |
| **Selos Lunares** | Lua em selo de cera | Prestígio (§12) | Ramo Lunar |
| Chave da Cripta | Chave | Chefe de cada área | Item de desbloqueio da próxima área (não é moeda) |

Regras:
- Nenhum recurso é perdido ao fim do turno.
- Números grandes: até 999.999 por extenso; depois `1,23 mi`, `bi`, `tri`, `qua` e, a partir daí, notação `aa, ab…` (EN: K, M, B, T, aa…). O jogo usa `float` (double): a escala de um incremental curto não exige BigNum (teto prático ~1e30).

## 6. Árvore de habilidades: as Raízes

### 6.1 Apresentação
A árvore é literalmente o **sistema de raízes** de um ipê velho no centro do cemitério, visto em corte de solo. O nó central é a **Pá Velha**. Comprar um nó faz a raiz crescer até os vizinhos e os revela (nós não revelados aparecem como "?" escurecido, com custo oculto).

- Navegação: arrastar para mover, roda para zoom (3 níveis), botão "Centralizar", filtro por ramo, **busca** por nome.
- Cada nó: ícone 16×16 dentro de medalhão 24×24, nível atual/máximo, custo do próximo nível, descrição com o valor **antes → depois**.
- Painel lateral **Ficha do Coveiro**: todos os stats calculados (resposta à crítica do Nodebuster).
- Comprar: clique (segurar = compra repetida a cada 0,1 s).

### 6.2 Custo
`custo(nível) = base × crescimento^nível` (nível = níveis já comprados), arredondado para cima. Os 1.0 têm ~120 nós; a tabela abaixo define os ~70 nós estruturais. Os restantes são "nós de reforço" (+X% de um stat) que preenchem os caminhos entre eles, com base = média dos vizinhos.

### 6.3 Ramos

**Centro**
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| N00 | Pá Velha | Início. Libera os 3 primeiros nós | — | grátis | — | — |
| N01 | Visita da Vidente | Libera Epitáfios ao subir de nível | 1 | 50 | — | Cobre |
| N02 | Ficha do Coveiro | Libera o painel de stats | 1 | 30 | — | Cobre |

**Ramo E — Escavação (força da pá)** · cor: terra
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| E01 | Lâmina Afiada | +1 dano | 10 | 10 | 1,45 | Cobre |
| E02 | Braço Firme | −6% intervalo do golpe (multiplicativo) | 8 | 25 | 1,55 | Cobre |
| E03 | Pá Larga | +1 raio | 3 | 15 | ×6 por nível | Ossos |
| E04 | Golpe Certeiro | +5% chance de crítico | 6 | 60 | 1,6 | Cobre |
| E05 | Crítico Brutal | +0,5 no mult. de crítico | 5 | 20 | 1,8 | Ossos |
| E06 | Abalo | 10% de chance de, ao quebrar camada, dar 1 golpe nos 4 vizinhos | 5 | 200 | 1,7 | Cobre |
| E07 | Cavar Fundo | +25% de dano em Barro e camadas inferiores | 5 | 300 | 1,6 | Cobre |
| E08 | Lâmina Temperada | +3 dano | 10 | 2.000 | 1,5 | Cobre |
| E09 | Ombro de Ferro | −4% intervalo | 10 | 5.000 | 1,6 | Cobre |
| E10 | Pisão | Habilidade ativa: ×4 dano, recarga 8 s (níveis: −1 s de recarga) | 4 | 150 | 2,0 | Cobre |
| E11 | Picareta | Libera a ferramenta Picareta (§8) | 1 | 40 | — | Ossos |
| E12 | Enxadão | Libera o Enxadão | 1 | 200 | — | Ossos |
| E13 | Pá Fantasma | Libera a Pá Fantasma | 1 | 25 | — | Almas |
| E14 | Mestre Coveiro | ×1,25 dano global | 5 | 1e6 | 3,0 | Cobre |

**Ramo L — Lanterna (tempo)** · cor: âmbar
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| L01 | Pavio Longo | +3 s de óleo | 10 | 15 | 1,5 | Cobre |
| L02 | Vidro Polido | Fogo-fátuo +1 s | 5 | 80 | 1,7 | Cobre |
| L03 | Isca de Fogo-fátuo | +15% frequência de fogos-fátuos | 5 | 120 | 1,7 | Cobre |
| L04 | Óleo de Osso | Cova aberta dá +1 s de óleo | 5 | 10 | 1,8 | Ossos |
| L05 | Luva Grossa | Rochas drenam −15% | 5 | 25 | 1,6 | Ossos |
| L06 | Segundo Fôlego | 1× por turno, ao zerar o óleo, recupera 5 s (níveis: +2 s) | 3 | 15 | 2,5 | Almas |
| L07 | Lua Cheia | +10% de dano enquanto o óleo estiver acima de 50% | 5 | 800 | 1,8 | Cobre |
| L08 | Querosene | +8 s de óleo | 10 | 3.000 | 1,55 | Cobre |

**Ramo F — Fortuna (saque)** · cor: ouro
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| F01 | Bolso Fundo | +10% de Cobre | 10 | 20 | 1,5 | Cobre |
| F02 | Faro de Osso | +2 p.p. de chance de Osso | 10 | 40 | 1,55 | Cobre |
| F03 | Moeda Enterrada | +0,5% de chance de Baú Enterrado | 5 | 150 | 1,8 | Cobre |
| F04 | Juros dos Mortos | +1% de Cobre por cova aberta no turno (acumula) | 5 | 30 | 1,9 | Ossos |
| F05 | Herança | +5% do Cobre do turno como bônus no resumo | 5 | 500 | 1,7 | Cobre |
| F06 | Olho de Corvo | Baús mostram brilho mais forte; +1 Relíquia possível por área | 1 | 10 | — | Almas |
| F07 | Cofre do Coveiro | Libera ganho offline (§11.2) | 1 | 1.000 | — | Cobre |
| F08 | Avareza | ×1,5 Cobre global | 5 | 5e5 | 3,0 | Cobre |

**Ramo C — Cemitério (campo)** · cor: verde
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| C01 | Mais Covas | +1 cova simultânea | 5 | 30 | 1,9 | Cobre |
| C02 | Terra Fofa | −12% do tempo de regeneração | 6 | 60 | 1,6 | Cobre |
| C03 | Campo Maior | +2 de lado no campo (12→18) | 3 | 30 | ×5 por nível | Ossos |
| C04 | Covas Duplas | 25% das novas covas são Duplas | 1 | 3 | — | Almas |
| C05 | Lápides Antigas | +25% de recompensa das covas | 5 | 50 | 1,8 | Ossos |
| C06 | Inquietação | +2 p.p. de Inquietação por cova | 5 | 5 | 1,7 | Almas |
| C07 | Mausoléus | Libera Mausoléus (Área 4) | 1 | 40 | — | Almas |
| C08 | Vala Comum | Covas aparecem 30% mais próximas umas das outras | 1 | 400 | — | Cobre |

**Ramo A — Ajudantes** · cor: lilás (detalhes em §9)
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| A01 | Toupeira Tita | Libera; níveis: +1 dano dela | 10 | 3 | 1,6 | Almas |
| A02 | Gato Breu | Libera; níveis: +1 tile da sorte | 5 | 8 | 1,8 | Almas |
| A03 | Cão Ossinho | Libera; níveis: −10% intervalo | 5 | 12 | 1,8 | Almas |
| A04 | Morcegos Gêmeos | Libera; níveis: +velocidade | 3 | 20 | 2,0 | Almas |
| A05 | Ração Especial | +20% de eficiência de todos os ajudantes | 5 | 2.000 | 1,9 | Cobre |

**Ramo S — Almas (fim de jogo leve)** · cor: ciano
| ID | Nó | Efeito/nível | Máx | Base | Cresc. | Moeda |
|---|---|---|---|---|---|---|
| S01 | Descanso Eterno | +5% de todo recurso | 10 | 10 | 1,6 | Almas |
| S02 | Bola de Cristal | Epitáfios oferecem 4 opções | 1 | 60 | — | Almas |
| S03 | Embaralhar | +1 nova rolagem de Epitáfios por turno | 3 | 20 | 2,2 | Almas |
| S04 | Prenúncio | Começa o turno com 1 Epitáfio Comum aleatório escolhido entre 3 | 1 | 100 | — | Almas |
| S05 | Romaria | Almas de covas ×2 | 1 | 150 | — | Almas |

**Ramo Lunar** (aparece só após a primeira Lua Nova; ver §12)

### 6.4 Desbloqueio por área
Alguns nós só aparecem quando a área correspondente é desbloqueada (ex.: E11 Picareta na Área 3, C07 na Área 4). Isso controla o tamanho percebido da árvore e garante novidades durante todo o jogo.

## 7. Epitáfios (cartas da run)

Cartas em forma de lápide, apresentadas por Madame Ossada. Duram **só o turno atual**. Cada uma tem raridade e uma ou mais **tags** de sinergia: [Pá] [Lanterna] [Fortuna] [Cova] [Ajudante].

Pesos de raridade: Comum 70 · Raro 25 · Lendário 5 (S01–S05 e Relíquias podem alterar). O mesmo Epitáfio pode ser pego mais de uma vez quando marcado como "acumula".

| Epitáfio | Raridade | Tags | Efeito |
|---|---|---|---|
| "Aqui jaz a pressa" | Comum | Pá | −15% intervalo do golpe (acumula) |
| "Bom de pá" | Comum | Pá | +2 dano (acumula) |
| "Que a terra lhe seja leve" | Comum | Pá | A camada superior de todos os tiles tem HP 1 |
| "Olho gordo" | Comum | Fortuna | +15 p.p. de chance de Osso |
| "Morreu rico" | Comum | Fortuna | +40% Cobre, −10% óleo máximo |
| "Foi pro buraco" | Comum | Cova, Lanterna | Cova aberta dá +3 s de óleo |
| "Família grande" | Comum | Cova | +2 covas simultâneas neste turno |
| "Corvo amigo" | Comum | Lanterna | Fogos-fátuos aparecem 2× mais |
| "Velório animado" | Comum | Ajudante | Ajudantes +50% de velocidade |
| "Herança disputada" | Comum | Fortuna, Pá | Críticos dão ×2 de Cobre |
| "Pó ao pó" | Raro | Pá | A cada 100 camadas quebradas: +1 raio por 5 s |
| "Descansa em pedaços" | Raro | Pá | Quebrar camada causa 1 golpe em raio 1 (não encadeia) |
| "Partiu cedo" | Raro | Pá, Lanterna | +60% dano, o óleo queima 25% mais rápido |
| "Nunca parou de cavar" | Raro | Pá | +5% dano por pulso seguido com o cursor parado (máx. +100%) |
| "Tropeço" | Raro | Pá | −1 raio (mín. 0), ×3 dano |
| "Enterrado com honras" | Raro | Cova, Fortuna | A cada 5 covas, a próxima é Dourada (×5) |
| "Saudade eterna" | Raro | Cova | Fantasmas e covas dão +1 Alma |
| "Vela de sete dias" | Raro | Lanterna | O óleo não queima nos primeiros 7 s após cada cova |
| "Morte súbita" | Lendário | Pá | 1% de chance por golpe de esvaziar o tile inteiro |
| "Ressuscitou" | Lendário | Lanterna | Ao zerar o óleo, volta com 50% (1×) |
| "Lua de sangue" | Lendário | Pá, Fortuna | Críticos ×5; chance de crítico pela metade |
| "Coveiro das Arábias" | Lendário | Fortuna | Todo Cobre ×2; Ossos não caem neste turno |
| "Último desejo" | Lendário | Cova | A Inquietação sobe ×2 neste turno |

Meta para o 1.0: **40 Epitáfios** (20 C / 14 R / 6 L). Epitáfios novos são desbloqueados por área e por conquistas e ficam registrados na coleção.

## 8. Ferramentas

Uma ferramenta equipada por turno (escolha na tela "Sair para o Turno"). Todas usam os stats da árvore e cada uma aplica seu modificador.

| Ferramenta | Formato da área (raio r) | Dano | Intervalo | Especial | Desbloqueio |
|---|---|---|---|---|---|
| **Pá** | Quadrado (2r+1)² | ×1 | ×1 | — | Início |
| **Picareta** | Cruz com braços de r+1 | ×2 | ×1,1 | Ignora o dreno das rochas; ×3 contra Pedra e Mármore | E11 (Área 3) |
| **Enxadão** | Linha 1×(2r+3), girada 90° com roda/botão direito | ×1,5 | ×0,9 | Ótima para covas | E12 (Área 2) |
| **Pá Fantasma** | Losango de raio r+2 (distância de Manhattan) | ×0,6 | ×0,8 | Atinge fantasmas com ×3 | E13 (Área 4) |

## 9. Ajudantes

Agentes autônomos no campo durante o turno. Não consomem óleo. Sprites 16×16 com animação simples.

| Ajudante | Comportamento | Valor base |
|---|---|---|
| **Toupeira Tita** | A cada 2 s emerge num tile aleatório não vazio e dá 1 golpe em área 1×1 | Dano = 50% do dano do jogador (+1 por nível) |
| **Gato Breu** | Marca 1 tile da sorte a cada 10 s (brilho); camadas quebradas nele valem ×5 | +1 tile simultâneo por nível |
| **Cão Ossinho** | Corre até a cova mais próxima e cava nela a cada 1,5 s | Dano = 100% do dano do jogador |
| **Morcegos Gêmeos** | Coletam fogos-fátuos automaticamente e espantam fantasmas | Raio de busca 4 tiles |
| **Espantalho** (Ramo Lunar) | Segunda área de escavação fixa, posicionada antes do turno | 40% do dano, raio −1 |

## 10. Áreas e chefes

Cada área tem multiplicadores, paleta, camadas e chefe próprios. Uma área é desbloqueada com a **Chave da Cripta** do chefe anterior. O jogador pode jogar qualquer área já liberada (útil para farm de recursos específicos).

| # | Área | Novidade | Chefe | Mecânica do chefe |
|---|---|---|---|---|
| 1 | **Cemitério da Paróquia** | Base, covas simples, rochas raras | **O Caixão Fujão** | Caixão 2×2 com barra de HP; a cada 4 s afunda e reaparece em outro lugar. HP 400 |
| 2 | **Campo dos Indigentes** | Lama, fantasmas travessos, Enxadão | **Seu Damião** (coveiro fantasma) | Ele anda pelo campo **tapando buracos**; o dano é causado cavando os tiles que ele pisa enquanto estão marcados. Ao perder, vira aliado no hub |
| 3 | **Catacumbas de Pedra** | Pedra, raízes, campo escuro (luz da lanterna importa), Picareta | **A Raiz-Mãe** | Raiz que se espalha tile a tile; destruir os 4 bulbos expõe o núcleo |
| 4 | **Necrópole dos Barões** | Mármore, Mausoléus, baús ricos, Pá Fantasma | **O Mausoléu Vivo** | Construção 4×4 com fases; cada fase solta "herdeiros" (fantasmas) que curam o chefe |
| 5 | **Jardim das Almas** | Névoa (tiles somem e reaparecem), todas as mecânicas | **A Cova da Dona Ceifa** | Cova 3×6 com camadas cíclicas; é a "cova final". Final do jogo |

Regras gerais de chefe:
- O chefe aparece quando a Inquietação da área chega a 100%. A Inquietação **persiste entre turnos** daquela área (o jogador não perde progresso se o óleo acabar).
- Se o turno acabar com o chefe vivo, ele some, a Inquietação fica em 90% e o HP dele é restaurado na próxima aparição.
- Chefe derrotado: Chave da Cripta (1ª vez), 10 × nº da área de Almas, diálogo e liberação dos nós da área seguinte. Repetir o chefe dá só Almas.

## 11. Meta: restaurar o Cemitério

### 11.1 Hub — Cemitério do Bom Descanso
Uma tela isométrica estática (o "lar"), mostrando o cemitério sendo restaurado. Construções com custo único e bônus permanente:

| Construção | Custo | Efeito | Libera em |
|---|---|---|---|
| Portão Consertado | 200 Cobre | +5% Cobre; visual de entrada | Após o 3º turno |
| Casa do Coveiro | 1.000 Cobre, 20 Ossos | Tela de loadout (ferramenta/ajudantes) | Área 1 |
| Capelinha | 5 Almas, 5.000 Cobre | Madame Ossada se muda: +1 Epitáfio raro garantido por turno no nível 5 | Área 1 chefe |
| Ossário | 200 Ossos | Ganho offline também gera Ossos | Área 2 |
| Canteiro de Crisântemos | 30 Almas | +10% de XP do turno | Área 2 |
| Poço Velho | 50.000 Cobre | +5 s de óleo inicial | Área 3 |
| Torre do Sino | 100 Almas | Inquietação +20% | Área 3 |
| Galinheiro da Dona Ceifa | 150 Almas | Galinhas pretas botam ovos (bônus aleatório no início do turno) | Área 4 |
| Jazigo da Família | 1e7 Cobre, 500 Ossos | ×1,25 todos os recursos | Área 4 |
| Coreto dos Mortos | 500 Almas | Música nova + diálogos extras + Selos +10% | Área 5 |

O hub é **estático e clicável**: cada construção é um sprite com estado "ruína" e estado "restaurado". Não há construção livre (fora de escopo).

### 11.2 Ganho offline (Cofre do Coveiro, F07)
- Ganho = **10% da média de Cobre/s das últimas 5 noites** × segundos ausente; teto de 8 h (12 h e 24 h no Ramo Lunar).
- Com o Ossário: Ossos na mesma proporção.
- Mostrado num pop-up "Enquanto você dormia…" ao abrir o jogo.

## 12. Prestígio: Lua Nova

- Liberado após derrotar o chefe da Área 3. Opcional, mas o caminho ideal até o final usa 1–2 Luas Novas.
- **Selos Lunares** ganhos = `floor( sqrt( Almas obtidas nesta Lua / 50 ) )`.
- **Reseta:** Cobre, Ossos, Almas, todos os nós (exceto Ramo Lunar), Inquietação.
- **Mantém:** áreas desbloqueadas (os chefes podem ser refeitos por Almas), construções do hub, Relíquias, coleção de Epitáfios, conquistas.
- **Ramo Lunar** (~12 nós): ×1,5 Cobre (acumula), começar com 500 Cobre, Prenúncio grátis, Espantalho, teto offline 12/24 h, +1 opção de Epitáfio, nós da árvore 10% mais baratos, primeiro chefe de cada área com −30% de HP.

## 13. Relíquias, conquistas e final

### 13.1 Relíquias (20 no 1.0, 4 por área)
Encontradas em Baús Enterrados (chance) e catalogadas por Tião no **Codex**. Cada uma dá um bônus permanente pequeno. Exemplos:
| Relíquia | Área | Bônus |
|---|---|---|
| Dentadura de Ouro | 1 | +5% Cobre |
| Terço de Contas de Osso | 1 | +3% de chance de crítico |
| Retrato Oval Rachado | 2 | +1 cova simultânea |
| Sapato de Defunto | 2 | Fantasmas 10% mais lentos |
| Lampião do Seu Damião | 3 | +5 s de óleo |
| Cálice de Estanho | 4 | Baús ×2 |
| Ampulheta Parada | 5 | Amanhecer em 330 s em vez de 300 s |

### 13.2 Conquistas (Steam, ~30)
Exemplos: "Primeira Cova", "Pá de Aço" (dano 10), "Campo Limpo", "Coveiro Notívago" (turno de 300 s), "Fila Andou" (100 almas), cada chefe, "Coleção Completa" (Relíquias), "Lua Nova", "Férias Merecidas" (final), "Sem Pisão" (derrotar um chefe sem usar o Pisão). Todas alcançáveis jogando normalmente (elogio recorrente ao Nodebuster).

### 13.3 Final e pós-final
Derrotar "A Cova da Dona Ceifa" → cena curta: Dona Ceifa deita, agradece e entrega a foice ao Coveiro ("agora a fila é sua"). Créditos. Depois: modo **Noites Eternas**: Área 5 com multiplicador crescente a cada chefe e recorde de "maior noite" local.

## 14. Balanceamento e ritmo

### 14.1 Simulação do primeiro turno (sanidade dos números)
15 s de óleo, 1 golpe/s, área 3×3 → no máximo 135 de dano. Com ~75% de aproveitamento: ~100 de dano. Todas as camadas da Área 1 pagam 0,5 Cobre por ponto de dano (§4.3) → **~50–60 Cobre** e ~35–40 XP (XP só na quebra). Nós iniciais custam 10 (E01), 15 (L01) e 20 (F01): o jogador compra **2–3 nós** depois do primeiro turno. ✔ Pilar 2.

### 14.2 Multiplicadores por área
| Área | HP × | Recompensas × | XP × |
|---|---|---|---|
| 1 | 1 | 1 | 1 |
| 2 | 12 | 9 | 2 |
| 3 | 144 | 81 | 4 |
| 4 | 1.728 | 729 | 8 |
| 5 | 20.736 | 6.561 | 16 |

HP cresce mais rápido que a recompensa de propósito: a árvore (multiplicadores globais E14, F08, S01, Lunar) fecha a diferença. Assim, uma área nova sempre começa "difícil" e vira "fácil" antes do chefe.

### 14.3 Metas de ritmo (tempo de jogo acumulado)
| Marco | Alvo |
|---|---|
| 1º nó comprado | 0:30 |
| Epitáfios liberados | 2:00 |
| 1ª Cova Aberta | 1º–2º turno |
| Turno de 60 s | ~15 min |
| Chefe Área 1 | 35–45 min |
| Chefe Área 2 | 1:30 h |
| Chefe Área 3 / 1ª Lua Nova | 2:30–3:00 h |
| Chefe Área 4 | 4:00 h |
| Final | 5:00–6:30 h |

**Regra de telemetria interna (playtest):** registrar por turno: duração, Cobre ganho, nós comprados, área. Se um jogador ficar mais de **5 turnos seguidos sem conseguir comprar nada**, isso é bug de balanceamento.

### 14.4 Limites de sanidade
- Intervalo mínimo do golpe 0,15 s; raio máximo 4 (9×9); dano sem teto.
- Números flutuantes: no máximo 40 por pulso na tela; acima disso, agregar ("+1.234" por tile vira um número grande no centro).

## 15. Telas, fluxo e UI

### 15.1 Fluxo
```
Título ─► Hub (Cemitério) ─► Sair p/ Turno (loadout: área, ferramenta) ─► TURNO
   ▲             ▲  │                                                      │
   │             │  ├─► Árvore de Raízes ◄── Resumo do Turno ◄────────────┘
   │             │  ├─► Codex (Relíquias, Epitáfios, Bestiário)
   │             │  ├─► Construções (clique no hub)
   │             └──┴─► Lua Nova (no Ramo Lunar / Torre do Sino)
   └── Configurações / Pausa (de qualquer lugar)
```
Atalho principal: no Resumo do Turno, **"Árvore"** e **"Mais uma noite"** são os dois botões grandes. Um turno novo deve estar a **1 clique** de distância da árvore (botão fixo "Cavar ▶" no canto).

### 15.2 Turno (HUD) — wireframe 640×360
```
┌──────────────────────────────────────────────────────────────┐
│ ◉ 1.234  🦴 56  ✦ 3        [Lv 4 ████████░░ XP]   INQUIET. ▓▓▓░ │
│                                                              │
│                         ◇◇◇◇◇◇◇◇                              │
│                      ◇◇◇◇◇◇◇◇◇◇◇◇◇◇   ✝                        │
│                   ◇◇◇◇◇◇[▓▓▓]◇◇◇◇◇◇◇◇◇                         │
│                      ◇◇◇◇◇◇◇◇◇◇◇◇◇◇                            │
│                         ◇◇◇◇◇◇◇◇                              │
│ 🏮 ████████████░░░░ 12s                     PISÃO [■■■□] Q/Clk│
└──────────────────────────────────────────────────────────────┘
```
Topo: recursos do turno (só o que foi ganho nesta noite) · nível/XP · Inquietação. Base: barra de óleo com segundos e recarga do Pisão. O campo ocupa o centro; o HUD nunca cobre a grade.

### 15.3 Escolha de Epitáfio (overlay, jogo pausado)
3 lápides-carta 64×88 lado a lado; Madame Ossada no canto falando uma frase; botões "Embaralhar (1)" quando houver. Teclas 1/2/3 ou clique.

### 15.4 Resumo do Turno
Lista animada contando: Cobre, Ossos, Almas, covas abertas, camadas quebradas, maior crítico, bônus (óleo restante, Herança). Barra mostrando o nó mais barato ainda não comprado: "Faltam 34 ◉ para Lâmina Afiada Nv 4".

### 15.5 Árvore de Raízes
Canvas em corte de solo, com o ipê no topo da tela (superfície) e as raízes descendo. Painel inferior com a descrição do nó em foco; painel lateral com a Ficha do Coveiro (abre/fecha com Tab).

### 15.6 Outras telas
Título (lua, lápide com o logo, "Novo Jogo / Continuar / Opções / Sair"), Hub, Codex (abas), Opções (áudio, vídeo, acessibilidade, idioma, controles), Pausa, pop-up de ganho offline, diálogos (balão com retrato 48×48).

## 16. Controles e acessibilidade

| Ação | Mouse/Teclado | Gamepad |
|---|---|---|
| Mover a área | Mouse | Analógico esquerdo (velocidade com aceleração; R3 alterna velocidade fina) |
| Pisão | Clique esquerdo / Q | A |
| Girar Enxadão | Roda / clique direito | LB/RB |
| Escolher Epitáfio | 1/2/3 ou clique | D-pad + A |
| Pausa | Esc | Start |
| Árvore: mover/zoom | Arrastar / roda | Analógico / gatilhos |

Acessibilidade (desde o MVP): volume por canal, **reduzir flashes**, **intensidade do tremor de tela (0–100%)**, tamanho dos números flutuantes, **modo daltônico** (moedas diferenciadas por forma, não só por cor), pausa automática ao perder o foco da janela e "auto-pisão" (o Pisão dispara sozinho quando recarrega) para quem não pode clicar repetidamente.

## 17. Áudio

- **Música:** lo-fi "seresta assombrada": violão de nylon, caixinha de música, órgão de igreja suave e assovio. Um tema por área (≈2 min em loop), tema do hub e tema de chefe. Mixagem baixa, nada que canse em sessões longas.
- **SFX prioritários:** golpe de pá por camada (grama = farfalhar, terra = "tuf", barro = "chlap", pedra = "tinc", mármore = "clank"), quebra de camada, cova aberta (sino + coro curto), alma subindo, fogo-fátuo (brilho), óleo acabando (chama tremulando, a partir de 3 s), nível subindo, carta virando, compra de nó (raiz crescendo).
- **Regra anti-fadiga:** variação aleatória de pitch (±6%) e de 3–4 amostras por SFX repetitivo; limite de vozes simultâneas por SFX (máx. 6).

## 18. Arquitetura técnica (Godot 4.7)

### 18.1 Configuração do projeto (aplicar ao iniciar a implementação)
| Configuração | Valor |
|---|---|
| `display/window/size/viewport_width` × `viewport_height` | 640 × 360 |
| `display/window/size/window_width_override` × `window_height_override` | 1280 × 720 |
| `display/window/stretch/mode` | `viewport` |
| `display/window/stretch/scale_mode` | `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | true |
| Renderer | GL Compatibility (já configurado) |

### 18.2 Estrutura
```
res://
  autoload/      Game.gd (estado), Economy.gd, Stats.gd, SaveManager.gd, Events.gd (barramento de sinais), Audio.gd
  data/          skill_nodes/*.tres, epitaphs/*.tres, areas/*.tres, tools/*.tres, relics/*.tres  (Resources tipados)
  scenes/        title/, hub/, run/ (Field, DigCursor, Hud, Boss*), tree/, ui/
  assets/        sprites/, tiles/, ui/, fonts/, sfx/, music/
```
- **Dados guiados por Resource:** cada nó/Epitáfio/área é um `.tres` com id, custo, curva e lista de modificadores `{stat, op (add/mul), valor}`. Designers ajustam sem tocar em código.
- **Stats.gd** agrega modificadores (árvore + relíquias + hub + Epitáfios do turno) e recalcula sob demanda (cache invalidado por sinal).
- **Campo:** modelo de dados separado da visualização: arrays por tile (camada atual, HP atual, tipo, timer de regeneração). Visual via `TileMapLayer` isométrico (tile shape Isometric, layout Diamond Down, tamanho 32×16, Y-Sort ligado), com atlas por estágio de escavação; objetos (lápides, chefes, ajudantes) como `Node2D` com y-sort.
- **Partículas:** `CPUParticles2D` em pool (compatível e previsível no renderer Compatibility).
- **Save:** `user://save.json` com campo `version` e migrações; autosave no fim de cada turno, ao comprar construção e a cada 60 s no hub. Steam Cloud sincroniza esse arquivo.

### 18.3 Ordem de processamento do pulso
1. Calcular os tiles da área (ferramenta + raio + centro). 2. Para cada tile: rolar crítico → aplicar dano na camada do topo → se quebrou: creditar recursos, XP, eventos (`Events.layer_broken`). 3. Resolver covas completas. 4. Aplicar dreno de rocha. 5. Disparar VFX/SFX agregados (1 som por tipo de camada por pulso, não 1 por tile).

### 18.4 Conversão tela ↔ grade (tile 32×16)
`tela = ((gx − gy) × 16, (gx + gy) × 8)` · inversa: `gx = (sx/16 + sy/8)/2`, `gy = (sy/8 − sx/16)/2` (com `floor`, coordenadas relativas à origem do campo). Na prática, usar `TileMapLayer.local_to_map()`.

## 19. Escopo e marcos

| Marco | Conteúdo | Critério de pronto |
|---|---|---|
| **M0 Protótipo cinza** | Campo iso, cursor, pulso, 3 camadas, óleo, resumo, 10 nós, save | "Cavar já é gostoso" com placeholders; 1º turno = 50–60 Cobre |
| **M1 Vertical slice (Demo Steam)** | Área 1 completa com arte final, covas, chefe Caixão Fujão, ~40 nós, 12 Epitáfios, Toupeira + Gato, hub com 3 construções, opções e acessibilidade, PT/EN | 40–50 min de jogo, playtest com 5+ pessoas |
| **M2 Conteúdo** | Áreas 2–4, 4 ferramentas, 4 ajudantes, Relíquias, Lua Nova | Ritmo da §14.3 batendo ±20% |
| **M3 1.0** | Área 5, final, Noites Eternas, ~120 nós, 40 Epitáfios, conquistas, polimento | Zero bloqueios de progressão; 5–7 h |
| Pós-lançamento | Modos desafio (pedido da comunidade do SuperReap), mais idiomas, Steam Deck verificado | — |

## 20. Riscos

| Risco | Mitigação |
|---|---|
| Leitura do campo iso: camadas difíceis de distinguir | Profundidade por **valor** (cada camada mais escura), validar em escala 1× e em tons de cinza (Direção de Arte §3.4) |
| Balanceamento quebrado (demo do SuperReap) | Fórmulas centralizadas em Resources, simulação da §14.1 para cada área antes da arte final, telemetria local |
| Grind de fim de jogo | Teto de 300 s, chefes com mecânica, Epitáfios, final definido |
| Excesso de partículas/números | Limites da §14.4 e opção de reduzir flashes |
| Escopo da arte (5 áreas) | As áreas reutilizam a mesma base de tile com troca de paleta; só props e chefes são exclusivos |

## 21. Glossário
**Turno**: uma run, limitada pelo óleo. **Pulso/golpe**: tick de dano da área. **Camada**: um nível de HP de um tile. **Buraco**: tile sem camadas. **Cova**: alvo de 2 tiles marcado por lápide. **Inquietação**: medidor que invoca o chefe. **Epitáfio**: carta temporária do turno. **Raízes**: árvore de habilidades. **Lua Nova**: prestígio. **Relíquia**: colecionável com bônus permanente.
