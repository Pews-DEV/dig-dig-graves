# Dig Dig Graves — Registro de decisões (em discussão)

> Rascunho de decisões de design tomadas em conversa com o dono do jogo, a partir da §7 do [04_REVISAO_E_ROADMAP.md](04_REVISAO_E_ROADMAP.md).
> **Nada aqui está implementado nem foi passado ao GDD ainda.** Quando o martelo for batido, cada item aprovado entra no [01_GDD.md](01_GDD.md) (e na DA/UI-UX quando couber) e vira tarefa do M0.5 em diante.

Legenda de status: ✅ **Aprovado** (o dono do jogo concordou) · 🟡 **Proposto** (recomendação do designer-chefe, aguardando o "ok") · ❓ **Em aberto** (falta escolher).

---

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

## D5 · Chefe e duração da demo — ❓ Em aberto
**O que é chefe nesse gênero:**
- **Nodebuster:** inimigo roxo grande no fim de cada fase; derrotá-lo dá um *core* (moeda rara) e libera a fase seguinte. É um **portão de progresso**, não um combate elaborado. Crítica comum: dá pouca recompensa.
- **SuperReap:** chefe ao fim de cada estágio, liberando pontos especiais e o próximo nível (fonte: [00_PESQUISA_SUPERREAP.md](00_PESQUISA_SUPERREAP.md)).
- **Legion Breaker** (mesmo nicho): demo de 30–60 min com 3 chefes pequenos, para dar ritmo de marcos.

**O nosso (GDD §10):** **o Caixão Fujão.** A Inquietação sobe a cada cova aberta; em 100% surge um caixão 2×2 com barra de vida que a cada 4 s afunda e reaparece em outro lugar (o jogador o persegue com a pá). Derrotado: Chave da Cripta (abre a próxima área) e Almas.

**Opções para a demo:**
| Opção | Como funciona | Prós | Contras |
|---|---|---|---|
| A. Chefe automático (como no GDD) | Inquietação em 100% → o chefe aparece no meio da noite | Surpresa, tensão | Pode chegar com o jogador fraco e frustrar |
| **B. Noite do Chefe** (recomendada) | Com 100% de Inquietação aparece "Enfrentar o Caixão Fujão" na Árvore; o jogador escolhe quando ir; se perder, volta mais forte | Jogador controla o momento; meta clara | Menos surpresa |
| C. Sem chefe na demo | Só marcos ("abrir 100 covas" etc.) | Mais simples | Sem clímax nem fim claro |

**Duração (depende da escolha acima).** Com a opção B:
- 0–30 min: crescer pá, campo e build.
- 30–40 min: o chefe vira a meta.
- 40–60 min: a recompensa libera a segunda metade da árvore; fim da demo com a Dona Ceifa mostrando as próximas áreas.

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
1. Escolher a opção do chefe (D5) e confirmar a duração.
2. Dar o "ok" em D3.
3. Bater o martelo: passar D1–D5 para o GDD e abrir o **M0.5 · Economia nova** (revisão §6) numa branch separada.
