# Pesquisa de referência — SuperReap (e o gênero "Nodebuster-like")

> Documento de apoio ao GDD de **Dig Dig Graves**. Pesquisa feita em 26/10/2026.
> Separação rígida entre **confirmado** (há fonte pública) e **inferido** (dedução nossa a partir do gênero). Não há GDD público do SuperReap; o que existe são páginas de loja, demo e discussões de jogadores.

---

## 1. Ficha

| Campo | Valor | Fonte |
|---|---|---|
| Nome | SuperReap | Steam |
| Estúdio | ZoomGames Studio (dev e publisher) | Steam / itch.io |
| Engine | Unity | itch.io |
| Plataforma | Windows (Steam), demo gratuita no Steam e itch.io | Steam / itch.io |
| Gênero | Incremental ativo de colheita, "cozy", pixel art | Steam / IncrementalDB |
| Tags | Incremental, Idler, Farming Sim, Roguelite, Pixel Graphics, Resource Management, "Nodebuster-like", "Branching upgrade tree" | Steam / IncrementalDB |
| Controles | Mouse, controle Xbox, qualquer gamepad | itch.io |
| Lançamento | **Datas conflitantes**: Steam mostrou 10/11/2026 e 01/12/2026 em acessos diferentes; SteamDB 11/11/2026; IncrementalDB marca "02/09/2026 / Finished". Tratar como "Q4 2026". | várias |

## 2. Mecânicas confirmadas

1. **Ação principal:** o jogador "passa a foice" por plantações extremamente crescidas; a colheita ocupa a tela inteira ("full-screen harvesting"). O controle é por mouse (área do cursor), sem exigir clique a cada golpe.
2. **Economia:** recursos colhidos → vendidos por **moedas** → moedas compram melhorias de ferramenta, equipamento e itens.
3. **Árvore de habilidades ramificada** que cresce com o progresso: mais plantas por campo, novas variedades de cultura, ferramentas melhores, novas armas, itens e "amigos" (animais).
4. **Cartas de talento:** cada sorteio oferece **3 cartas, escolhe-se 1** ("combinações que definem a build"). Talentos são revelados por uma **bruxa cartomante**.
5. **Recursos interligados:** culturas básicas continuam úteis no fim do jogo.
6. **Meta-progressão de fazenda:** restaurar uma fazenda abandonada, plantar, criar galinhas, conhecer personagens. A fazenda **produz enquanto o jogador está fora** (offline).
7. **Artefatos** colecionáveis (citados por jogadores como objetivo de "colecionar todos").
8. **Nível do jogador** desbloqueia acesso a partes da árvore; a demo tem teto de nível 25.
9. **Tem final** (IncrementalDB: "Has an ending").

## 3. O que NÃO está documentado publicamente (inferido)

| Ponto | Inferência | Base |
|---|---|---|
| Estrutura de "run" | Sessões curtas limitadas por um recurso (tempo/energia) e volta para a tela de melhorias | Tag *Roguelite* + classificação *Nodebuster-like* |
| Formato da área do cursor | Área fixa ao redor do cursor que causa dano em pulsos | Padrão do Nodebuster |
| Inimigos | Não mencionados; o tom "cozy" sugere ausência de combate real | Página da loja |

## 4. Referência de gênero: Nodebuster (Godot, 2025)

- Cursor com **área quadrada**; tudo que estiver dentro dela no momento do **pulso** automático leva dano. Não precisa clicar: o jogador **mira**.
- **Vida drena com o tempo** e com dano recebido → é o "timer" da run. Acabou a vida, volta para a árvore.
- Várias moedas (bits comuns → nodes raros) compram nós de uma **árvore grande**.
- Chefe ao fim de cada estágio libera pontos especiais e o próximo nível; prestígio = dificuldade crescente.
- Duração típica: **2 a 7 horas** para zerar com conquistas.

### O que os jogadores elogiam
- Loop viciante de "ficar mais forte" visível a cada run; preço baixo; relaxante; partículas satisfatórias.

### O que os jogadores criticam (e o SuperReap herdou parte)
| Crítica | Fonte | Resposta no Dig Dig Graves |
|---|---|---|
| Fim de jogo vira grind AFK repetitivo | Nodebuster | Teto de duração do turno ("o sol nasce"), Epitáfios por run, chefes com mecânica própria |
| Balanceamento: começo lento, depois tudo fica fácil demais | Nodebuster / SuperReap demo ("zerei em 20 min, recompensas altas demais") | Curvas de custo/HP documentadas no GDD §14 e metas de ritmo por área |
| Respawn de plantas bugado / campo sempre cheio | SuperReap demo | Regra explícita de regeneração por tile com teto de densidade (GDD §4.7) |
| Árvore confusa de navegar, falta tela de estatísticas | Nodebuster | Árvore com zoom/pan, busca por ramo, painel "Ficha do Coveiro" com todos os stats |
| Flashes e tremor de tela cansativos | Nodebuster | Opções de reduzir flash e tremor desde o MVP |
| Pouca variedade | ambos | 5 áreas com camadas de solo próprias, 4 ferramentas com formato de área diferente, Epitáfios |

## 5. Telas típicas do gênero (base para o nosso fluxo)
1. Título → 2. Hub/meta (fazenda) → 3. Run (campo + HUD: moedas, timer/energia, nível) → 4. Escolha de carta (overlay 3 cartas) → 5. Resumo do fim da run → 6. Árvore de habilidades (canvas com pan/zoom) → 7. Coleção (artefatos) → 8. Configurações.

## Fontes
- [SuperReap — Steam](https://store.steampowered.com/app/4714820/SuperReap/)
- [SuperReap Demo — Steam](https://store.steampowered.com/app/4946910/SuperReap_Demo/)
- [SuperReap — Comunidade Steam](https://steamcommunity.com/app/4714820)
- [SuperReap — IncrementalDB](https://www.incrementaldb.com/game/superreap)
- [SuperReap — itch.io (ZoomGames)](https://zoomgamesstudio.itch.io/super-reap)
- [SuperReap — SteamDB](https://steamdb.info/app/4714820/charts/)
- [Nodebuster — resumo de reviews (Vaporlens)](https://vaporlens.app/app/3107330/nodebuster.md)
- [Nodebuster review — The Mancunion](https://mancunion.com/2025/05/08/nodebuster-review-a-short-and-sweet-incremental-game/)
