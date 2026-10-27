# Dig Dig Graves — Registro de decisões (em discussão)

> Rascunho de decisões de design tomadas em conversa com o dono do jogo, a partir da §7 do [04_REVISAO_E_ROADMAP.md](04_REVISAO_E_ROADMAP.md).
> **Nada aqui está implementado nem foi passado ao GDD ainda.** Quando o martelo for batido, cada item aprovado entra no [01_GDD.md](01_GDD.md) (e na DA/UI-UX quando couber) e vira tarefa do M0.5 em diante.

Legenda de status: ✅ **Aprovado** (o dono do jogo concordou) · 🟡 **Proposto** (recomendação do designer-chefe, aguardando o "ok") · ❓ **Em aberto** (falta escolher).

---

## D0 · Rumo do projeto: jogo completo, não só a demo — ✅ Aprovado
- O desenvolvimento segue mirando o **jogo completo**, sem esperar uma demo "fechada" antes.
- A versão atual (tela-título, Área 1, Árvore, fundo da mata escura) foi congelada na branch **`demo`** (commit `ccb1c14`), para publicar no **itch.io**. Ela **não** é mergeada na `main`; correções pontuais da demo são feitas nela e, se servirem, portadas para a `main`.
- Onde este documento fala em "demo de ~60 min", leia como o **arco do primeiro estágio** (estágio 1 + chefe), que continua sendo a meta de ritmo do início do jogo. O escopo de estágios (D12) passa a ser pensado para o jogo completo.

## D1 · Pá e campo começam pequenos — ✅ Aprovado
- **Pá:** começa em **1×1** e cresce com melhorias da árvore.
- **Campo:** também começa **menor** (proposta: **5×5**) e cresce com nós próprios até 18×18.
- Os dois crescem **em paralelo**: cada compra é um passo visível no tabuleiro.
- A definir no balanceamento: em que pontos da árvore ficam cada tamanho de pá e de campo (os maiores, 4×4/5×5 de pá, em pontas distantes).

## D2 · A pá cresce por lado, não por raio — ✅ Aprovado
- Sequência proposta: 1×1 → 1×2 → 2×2 → 2×3 → 3×3 → … → 5×5.
- Impacto técnico (para depois): `ToolData` passa de raio para largura × altura; o contorno da área e a rotação do Enxadão precisam aceitar retângulos.

## D3 · Valor do Cobre — 🟡 Proposto (o dono do jogo delegou ao designer-chefe)
Preocupação do dono do jogo: o jogo não pode ficar monótono nem "travado".
- **Não** usar "1 Cobre por ponto de dano" igual para tudo (deixa o jogo plano).
- **Cada camada vale mais quanto mais funda:** grama paga pouco, terra mais, barro mais ainda; a camada nova **Ossada** paga Ossos. Cavar fundo vira o objetivo, não um custo.
- **Números começam pequenos** (1º turno ≈ 15–25 Cobre) e crescem por multiplicadores da árvore ("número subindo" é parte da graça do gênero).
- **Picos de valor** quebram a rotina: crítico, moeda dourada rara, bônus de Campo Limpo.
- Papéis das moedas (da revisão §3.4): **Cobre** compra números, **Ossos** compram espaço (pá, campo, elementos), **Almas** compram regras e personagens.
- Valores exatos: a definir no M0.5 com a simulação de 60 min.

## D4 · Árvore com escolhas, mas maxável com dedicação — ✅ Aprovado (com ajuste)
Pedido do dono do jogo: o jogador escolhe uma direção, mas quem tiver tempo e dedicação consegue maximizar tudo; "não deixar tão travado".
- **Raízes-mestras** (nós-ponta de cada ramo): **todas compráveis**, mas cada uma custa **3× a anterior**. Em ~1 h o jogador pega uma; com ~3–4 h, todas.
- **Encruzilhadas "escolha 1 de 2":** só **2 ou 3** na árvore inteira (a revisão propunha 6).
- **Nó tardio "Duas Raízes":** caro; libera o outro lado de cada encruzilhada. Quem maxar tudo não perde nada.
- Mantém o respec ("Replantar") como forma de testar outra build sem recomeçar.
- Substitui a regra "uma Raiz-mestra por partida" da revisão §4.3.

## D5 · Chefes como portão de estágio — ✅ Aprovado (conceito) · 🟡 implementação proposta
**Aprovado:** cada estágio (área) termina num **chefe**; derrotá-lo libera o estágio seguinte. É o modelo do GDD §10 (Chave da Cripta) e o mesmo papel do chefe no Nodebuster e no SuperReap.

**Referências do gênero:**
- **Nodebuster:** inimigo roxo grande no fim de cada fase; derrotá-lo dá um *core* (moeda rara) e libera a fase seguinte. É um **portão de progresso**, não um combate elaborado. Crítica comum: dá pouca recompensa (lição: a recompensa do nosso chefe tem que ser grande e visível).
- **SuperReap:** chefe ao fim de cada estágio, liberando pontos especiais e o próximo nível (fonte: [00_PESQUISA_SUPERREAP.md](00_PESQUISA_SUPERREAP.md)).
- **Legion Breaker** (mesmo nicho): demo de 30–60 min com 3 chefes pequenos, para dar ritmo de marcos.

**Chefe do estágio 1 (GDD §10): o Caixão Fujão.** Caixão 2×2 com barra de vida; a cada 4 s afunda e reaparece em outro lugar (o jogador o persegue com a pá). Derrotado: Chave da Cripta (abre o estágio 2), Almas e a liberação dos nós do estágio seguinte.

**Implementação recomendada pelo designer-chefe: opção B, "Noite do Chefe".**
1. A **Inquietação** sobe a cada cova aberta e persiste entre noites (já existe no código; hoje não faz nada em 100%).
2. Em 100%, a Árvore mostra o botão **"Enfrentar o Caixão Fujão"** (com a caveira tremendo e a frase "A terra treme…"). O jogador escolhe **quando** ir.
3. A Noite do Chefe é uma noite normal com o chefe no campo desde o início (as covas comuns continuam pagando). Se o óleo acabar com o chefe vivo, ele foge, o HP dele **volta cheio**, e o botão continua lá: o jogador volta mais forte e tenta de novo, sem perder nada.
4. Vitória: diálogo curto (2–4 balões), Resumo especial com a Chave, e na Árvore se revela a segunda metade dos nós + o estágio 2 no seletor de estágios (D12).
5. Repetir o chefe depois dá só Almas (farm opcional), como no GDD.

Alternativas descartadas por ora: **A** (chefe aparece sozinho no meio da noite: pode frustrar quando o jogador está fraco) e **C** (sem chefe: a demo fica sem clímax).

**Duração da demo com a opção B** (alvo, a confirmar no balanceamento):
- 0–30 min: crescer pá, campo e build no estágio 1.
- 30–40 min: o Caixão Fujão vira a meta.
- 40–60 min: a recompensa libera a segunda metade da árvore; fim da demo (D12 define se o estágio 2 entra na demo).

## D12 · Mais estágios (outros dioramas) — ✅ Aprovado (direção) · ❓ escopo da demo em aberto
**Estado atual:** o jogo tem **um único estágio**, o campo da Área 1 (Cemitério da Paróquia). Não existe seletor de estágios nem outro diorama.

**Pedido do dono do jogo:** outros dioramas, **com outras cores e outros elementos aparecendo**, liberados pelos chefes (D5).

**O que o GDD já prevê** (GDD §10 e Direção de Arte §6), cada um com paleta, camadas, props e chefe próprios:
| # | Estágio | Cara do diorama | Novidade de jogo | Chefe |
|---|---|---|---|---|
| 1 | Cemitério da Paróquia | Grama verde, terra, lápides, velas (o atual) | Base: covas, rochas | Caixão Fujão |
| 2 | Campo dos Indigentes | Grama rala, névoa baixa, lama esverdeada, cruzes sem nome | Lama, fantasmas travessos, Enxadão | Seu Damião (coveiro fantasma) |
| 3 | Catacumbas de Pedra | Mais escuro, pedra, raízes, nichos com crânios | A luz da lanterna importa de verdade | A Raiz-Mãe |
| 4 | Necrópole dos Barões | Mármore, ouro, mausoléus, vitrais | Baús ricos, Pá Fantasma | O Mausoléu Vivo |
| 5 | Jardim das Almas | Ecto/ciano, flores luminosas, lápides flutuantes | Névoa (tiles somem e reaparecem) | A Cova da Dona Ceifa (final) |

**Propostas a decidir:**
- **Escopo da demo:** (a) só o estágio 1 + o chefe, com os outros estágios aparecendo como silhuetas trancadas no final (como na revisão §5.5); ou (b) estágio 1 + **estágio 2 jogável** como prêmio do chefe, para o jogador ver um diorama novo antes da demo acabar. Recomendação: **(b)**, se couber no prazo; é o que melhor mostra a promessa "cada chefe abre um mundo novo".
- **Como trocar de estágio:** um seletor simples na Árvore (ao lado de "Cavar ▶"), com os estágios liberados e os trancados em silhueta; dá para voltar a qualquer estágio liberado (útil para farm, como no GDD §10).
- **Produção por estágio:** tileset + atlas `_lit`, bloco do diorama, fundo próprio (como o fundo da mata escura do estágio 1), props com efeito, chefe e música da área.

## D6–D11 · Ainda não discutidas (não bloqueiam o M0.5)
Da §7 da revisão; ficam para o M0.6 em diante:
- **D6** Uma loja só na demo (Mascate: pás e amuletos em 2 espaços) e se os amuletos viram as Relíquias do jogo completo.
- **D7** Hub fora da demo; no jogo completo, como superfície da Árvore em vez de cena separada.
- **D8** Respec ("Replantar"): grátis (100%) ou com custo (ex.: devolve 80%).
- **D9** Nó de regra "Cava-Funda" (o dano que sobra passa para a camada de baixo).
- **D10** Fogo-fátuo com retorno decrescente (cada um da mesma noite vale 80% do anterior), para evitar noite infinita.
- **D11** Quais elementos de tabuleiro entram na demo (lápides com efeito, vela, cruz, ossário, baú, alminhas) ou cortar para 4.

---

## Próximo passo
1. Dar o "ok" na implementação do chefe (D5, opção B) e em D3.
2. Decidir o escopo de estágios da demo (D12: só o estágio 1 ou estágio 1 + 2).
3. Bater o martelo: passar D1–D5 e D12 para o GDD e abrir o **M0.5 · Economia nova** (revisão §6) numa branch separada.
