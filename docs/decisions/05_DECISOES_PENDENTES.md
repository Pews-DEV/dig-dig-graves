# Dig Dig Graves — Registro de decisões (em discussão)

> Rascunho de decisões de design tomadas em conversa com o dono do jogo, a partir da §7 do [04_REVISAO_E_ROADMAP.md](../review/04_REVISAO_E_ROADMAP.md).
> **Nada aqui está implementado nem foi passado ao GDD ainda.** Quando o martelo for batido, cada item aprovado entra no [01_GDD.md](../core/01_GDD.md) (e na DA/UI-UX quando couber) e vira tarefa do M0.5 em diante.

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

## D3 · Valor do Cobre — ✅ Aprovado
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

## D5 · Chefes como portão de estágio — ✅ Aprovado (conceito e implementação: "Noite do Chefe")
**Aprovado:** cada estágio (área) termina num **chefe**; derrotá-lo libera o estágio seguinte. É o modelo do GDD §10 (Chave da Cripta) e o mesmo papel do chefe no Nodebuster e no SuperReap.

**Referências do gênero:**
- **Nodebuster:** inimigo roxo grande no fim de cada fase; derrotá-lo dá um *core* (moeda rara) e libera a fase seguinte. É um **portão de progresso**, não um combate elaborado. Crítica comum: dá pouca recompensa (lição: a recompensa do nosso chefe tem que ser grande e visível).
- **SuperReap:** chefe ao fim de cada estágio, liberando pontos especiais e o próximo nível (fonte: [00_PESQUISA_SUPERREAP.md](../research/00_PESQUISA_SUPERREAP.md)).
- **Legion Breaker** (mesmo nicho): demo de 30–60 min com 3 chefes pequenos, para dar ritmo de marcos.

**Chefe do estágio 1 (GDD §10): o Caixão Fujão.** Caixão 2×2 com barra de vida; a cada 4 s afunda e reaparece em outro lugar (o jogador o persegue com a pá). Derrotado: Chave da Cripta (abre o estágio 2), Almas e a liberação dos nós do estágio seguinte.

**Implementação recomendada pelo designer-chefe: opção B, "Noite do Chefe".**
1. A **Inquietação** sobe a cada cova aberta e persiste entre noites (já existe no código; hoje não faz nada em 100%).
2. Em 100%, a Árvore mostra o botão **"Enfrentar o Caixão Fujão"** (com a caveira tremendo e a frase "A terra treme…"). O jogador escolhe **quando** ir.
3. A Noite do Chefe é uma noite normal com o chefe no campo desde o início (as covas comuns continuam pagando). Se o óleo acabar com o chefe vivo, ele foge, o HP dele **volta cheio**, e o botão continua lá: o jogador volta mais forte e tenta de novo, sem perder nada.
4. Vitória: diálogo curto (2–4 balões), Resumo especial com a Chave, raízes novas reveladas no Pátio/Árvore e próximo estágio adicionado ao destino Próxima Noite quando estiver implementado.
5. Repetir o chefe depois dá só Almas (farm opcional), como no GDD.

Alternativas descartadas por ora: **A** (chefe aparece sozinho no meio da noite: pode frustrar quando o jogador está fraco) e **C** (sem chefe: a demo fica sem clímax).

**Duração da demo com a opção B** (alvo, a confirmar no balanceamento):
- 0–30 min: crescer pá, campo e build no estágio 1.
- 30–40 min: o Caixão Fujão vira a meta.
- 40–60 min: a recompensa libera a segunda metade da árvore; fim da demo (D12 define se o estágio 2 entra na demo).

## D12 · Mais estágios (outros dioramas) — ✅ Aprovado: o estágio 2 vem logo depois do estágio 1 + chefe
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
- **Decidido (D0 + resposta do dono do jogo):** o próximo estágio a construir é o **2 · Campo dos Indigentes**, logo depois de fechar o estágio 1 com o Caixão Fujão. Opções originais, para registro: (a) só o estágio 1 + o chefe, com os outros estágios aparecendo como silhuetas trancadas no final (como na revisão §5.5); ou (b) estágio 1 + **estágio 2 jogável** como prêmio do chefe, para o jogador ver um diorama novo antes da demo acabar. Recomendação: **(b)**, se couber no prazo; é o que melhor mostra a promessa "cada chefe abre um mundo novo".
- **Como trocar de estágio:** a seleção fica dentro do destino Próxima Noite, quando mais de um estágio estiver jogável; fases futuras não aparecem como opções selecionáveis.
- **Produção por estágio:** tileset + atlas `_lit`, bloco do diorama, fundo próprio (como o fundo da mata escura do estágio 1), props com efeito, chefe e música da área.

## D11 · Elementos de tabuleiro: começar pelas lápides com efeito — ✅ Aprovado
- Primeiro elemento novo do campo: **lápides com efeito por tipo** (cada tipo de lápide tem uma regra própria; ex.: com foto dá Almas, rachada quebra e solta Ossos, cruz bloqueia mas dá bônus ao redor). Lista final de tipos e números a definir.
- Velas, ossário, baú e alminhas errantes ficam para depois (não descartados).

## D6 · Loja: o Mascate, com pás e amuletos — ✅ Aprovado
- **Uma loja só**, o **Mascate** (vendedor ambulante que aparece no cemitério).
- Vende **pás** (ferramentas com formato/efeito diferente) e **amuletos** (bônus equipáveis em **2 espaços** no início; mais espaços depois).
- Os amuletos **viram as Relíquias** do jogo completo.
- Gasta principalmente Ossos e Almas (moedas que hoje sobram).
- Fica no hub (D7). Itens, preços e espaços a definir no balanceamento.

## D7 · Pátio de navegação na superfície da Árvore — ✅ Aprovado
- A superfície da Árvore é o **Pátio do Bom Descanso**, um hall visual integrado ao cenário, com estações para Árvore/Talentos, Próxima Noite, Loja e Fazenda.
- No Marco A, Árvore e Próxima Noite funcionam; Loja e Fazenda ficam bloqueadas e indicam seus marcos futuros. A escavação permanece a um clique.
- A escolha do estágio entra dentro de Próxima Noite quando houver mais de um estágio jogável. Marco A mostra somente a Paróquia, sem painel de lanternas futuras.
- Fluxo: Título/Resumo → Pátio → Árvore ou Noite → Resumo → Pátio. Atualiza GDD §4, §10–11 e UI/UX §10.
## D8 · Respec ("Replantar") grátis após o chefe — ✅ Aprovado
- Liberado ao vencer o **1º chefe** (Caixão Fujão).
- Devolve **100%** do que foi gasto (e solta as encruzilhadas); custa só algumas Almas por uso; só na Árvore.

## D9 · Nó "Cava-Funda" — ✅ Aprovado
- Nó-chave do ramo **Escavação**: o dano que passa da vida da camada **passa para a camada de baixo** (hoje é perdido).
- Sem o nó, o excedente continua perdido (é isso que dá peso ao nó). Exceção registrada à DA/GDD §4.3.

## D10 · Fogo-fátuo com retorno decrescente — ✅ Aprovado
- Cada fogo-fátuo coletado na **mesma noite** vale **80%** do anterior; o valor volta ao normal na noite seguinte.
- Corrige o risco de "noite infinita" com os nós de Lanterna no máximo (revisão §3).

---

## Próximo passo
1. **Bater o martelo:** passar D0–D12 para o GDD (§4, §7, §10, §11, §14, §15, §19) e reescrever os marcos: M0.5 Economia nova → M0.6 Ativos e regras → estágio 1 completo (lápides com efeito + Noite do Chefe) → estágio 2.
2. Abrir o **M0.5 · Economia nova** (revisão §6) numa branch separada.
