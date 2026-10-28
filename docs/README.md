# Documentação viva

Este diretório reúne as especificações, decisões e registros de design e produção do projeto. Comece pelos documentos de produto e consulte o índice abaixo conforme o assunto.

## Produto e design

- [GDD — regras, sistemas e arquitetura](core/01_GDD.md)
- [Direção de arte](design/02_DIRECAO_DE_ARTE.md)
- [UI/UX, interface, animação e áudio](design/03_UI_UX.md)
- [Paleta Lua de Cova](design/palette/)
- [História e direção narrativa](narrative/07_HISTORIA.md)

## Planejamento e decisões

- [Revisão e roadmap](review/04_REVISAO_E_ROADMAP.md)
- [Decisões de design](decisions/05_DECISOES_PENDENTES.md)
- [Plano de produção v1](planning/06_PLANO_V1.md)
- [Roteiro de playtest do Marco A](playtests/08_PLAYTEST_MARCO_A.md)

## Pesquisa

- [Pesquisa sobre SuperReap](research/00_PESQUISA_SUPERREAP.md)

## Documentação operacional mantida junto ao código e aos assets

Estes arquivos ficam nos caminhos atuais porque o jogo, os testes ou o fluxo de produção os leem diretamente:

- `../assets/MANIFEST.md` — contrato de sprites e arte; consumido por `AssetManifest` e pelo fluxo de arte.
- `../assets/AUDIO_MANIFEST.md` — catálogo/allowlist de áudio; consumido por `Audio`.
- `../CREDITS.md` e `../assets/AUDIO_CREDITS.md` — conteúdo do painel de créditos do jogo.
- `../CLAUDE.md` e `../.claude/agents/` — instruções de trabalho reconhecidas pelas ferramentas de agente.

Os documentos de produto e design acima são a fonte da verdade para regras e direção. Atualize o GDD quando uma decisão for aprovada; use a revisão e as decisões pendentes como histórico e processo, não como substitutos do GDD.