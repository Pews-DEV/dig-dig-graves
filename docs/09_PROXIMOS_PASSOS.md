# Dig Dig Graves — Próximos passos

Itens combinados e ainda não feitos. Ao concluir um item, marque com ✔ e o commit; quando virar regra, ele sai daqui e entra no GDD, na DA ou na UI/UX.

## Fechar o Marco A
- [ ] Rodar a suíte de testes e o `sim_campaign`. As regras novas (musgo, tremores, Herança, Segundo Fôlego, Constelação) mexem no ritmo, e `test_core`/`test_grave_types` mudaram com as regras.
- [ ] Testes que já falham (vistos na entrega do modo dev):
  - `test_core` espera regeneração mínima de 6 s, mas o GDD §4.7 diz 5 s: corrigir o teste.
  - `test_chapter_end_flow` falha em "Continuar cavando": investigar.
- [ ] 3 playtests com o `08_PLAYTEST_MARCO_A.md` e o build `builds/Dig Dig Graves.exe`.
- [ ] Ajuste de ritmo pelas fichas (GDD §14.3): 1º nó ≤ 40 s, chefe aos 35–45 min, nenhuma sequência de 5 noites sem compra.
- [ ] Conferir com o jogo aberto:
  - Árvore: encaixe do `root_y` em E11 → E12a/E12b, molduras e selado, Raízes-mestras, parallax do céu nos cantos.
  - Pátio: balão do Tião sobre o título e clique no Tião acionando a Próxima Noite.
  - Falas que cabem no balão em ja/ko/ru/de.
- [ ] Unificar nomes no `translations.csv`: "Caixão Fujão" em alemão (ficar com *Flüchtiger Sarg*, não *Ausreißer-Sarg*) e "Campo dos Indigentes" sem tradução em italiano.
- [ ] Abrir no Aseprite os `.aseprite` da ART-A2, que foram gravados por script, e confirmar que abrem.
- [ ] `devlog/devlog01.md` e parada para revisão.

## Idioma inicial automático
Hoje o jogo sempre abre em `pt_BR` (`autoload/game_settings.gd`).

- **1ª abertura (sem idioma salvo):**
  1. Usar o idioma da Steam, se o jogo estiver rodando pela Steam.
  2. Se não estiver, usar o idioma do sistema (`OS.get_locale()`), se ele bater com um dos 10 idiomas do jogo.
  3. Se não bater com nenhum, usar `en`.
- **Correspondência de idiomas:** pela língua, ignorando a região (`pt_PT` → `pt_BR`, `es_MX` → `es_ES`, `zh_TW`/`zh_HK` → `zh_CN`, `en_GB` → `en`).
- **Depois que o jogador escolhe nas Opções:** a escolha salva vale sempre, e a detecção não roda mais.
- **Quando:**
  - O idioma do sistema pode entrar a qualquer momento: é uma tarefa pequena para o `godot-dev`, com um ponto de extensão para a Steam.
  - O idioma da Steam entra junto com a integração do SDK (GodotSteam: `getCurrentGameLanguage()`, que devolve nomes como `brazilian`, `english` e `schinese`, a converter para os nossos códigos), no Marco D, com conquistas e nuvem.
