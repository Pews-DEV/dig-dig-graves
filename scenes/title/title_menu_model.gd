class_name TitleMenuModel
extends RefCounted
## Regras do menu principal (UI/UX §9.4), puras e testáveis: quais botões existem, em que
## ordem, qual começa em foco, a descrição de cada um e a confirmação de "Novo Jogo".

const CONTINUE := &"continue"
const NEW_GAME := &"new_game"
const OPTIONS := &"options"
const CREDITS := &"credits"
const QUIT := &"quit"
const ORDER: Array[StringName] = [CONTINUE, NEW_GAME, OPTIONS, CREDITS, QUIT]

const LABELS: Dictionary = {
	CONTINUE: "Continuar",
	NEW_GAME: "Novo Jogo",
	OPTIONS: "Opções",
	CREDITS: "Créditos",
	QUIT: "Sair",
}

## Confirmação "Enterrar o progresso atual?": o foco começa em "Voltar".
const BURY := &"bury"
const BACK := &"back"
const CONFIRM_ORDER: Array[StringName] = [BURY, BACK]
const CONFIRM_FOCUS := BACK
const CONFIRM_TEXT := "Enterrar o progresso atual?"
const CONFIRM_LABELS: Dictionary = {BURY: "Enterrar", BACK: "Voltar"}

## Destinos ao começar: Continuar → Árvore; Novo Jogo → 1º turno.
const DEST_TREE := &"tree"
const DEST_RUN := &"run"


## Botões na ordem da tela. "Continuar" só existe com save.
static func entries(has_save: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in ORDER:
		if id == CONTINUE and not has_save:
			continue
		out.append(id)
	return out


## Com save, "Continuar" vira o botão em foco; sem save, "Novo Jogo".
static func initial_focus(has_save: bool) -> StringName:
	return CONTINUE if has_save else NEW_GAME


static func label(id: StringName) -> String:
	return String(LABELS.get(id, ""))


## Descrição em m5x7 embaixo do botão em foco (ex.: "Noite 7 · 1.234" + ícone de Cobre).
static func description(id: StringName, has_save: bool, nights: int, copper: float) -> String:
	if id == CONTINUE:
		return "Noite %d · %s" % [nights, NumberFormat.format(copper)]
	if id == NEW_GAME:
		return "Enterra o progresso atual" if has_save else "A primeira noite do coveiro"
	if id == OPTIONS:
		return "Som, tremor e acessibilidade"
	if id == CREDITS:
		return "Quem cavou este jogo"
	if id == QUIT:
		return "Apagar a lanterna por hoje"
	return ""


## A descrição leva o ícone de Cobre (◉) no fim?
static func shows_copper(id: StringName) -> bool:
	return id == CONTINUE


## "Novo Jogo" com save existente pede confirmação.
static func needs_confirm(id: StringName, has_save: bool) -> bool:
	return id == NEW_GAME and has_save


static func destination(id: StringName) -> StringName:
	return DEST_TREE if id == CONTINUE else DEST_RUN


## Próximo índice com volta (teclado/gamepad).
static func step(index: int, direction: int, count: int) -> int:
	if count <= 0:
		return 0
	return posmod(index + direction, count)
