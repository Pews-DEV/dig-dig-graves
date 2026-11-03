class_name SkillNodeButton
extends Control
## Medalhão 32×32 de um nó da Árvore de Raízes (UI/UX §7.3, MANIFEST tree_medallions32,
## tree_pips, tree_node_icons, fx_tree_new_badge). Clique compra; segurar repete a cada 0,1 s
## (GDD §6.1). Estados animados: respirar (comprável), parado (sem dinheiro), "?" oscilando
## (oculto), pips com o último brilhando (parcial) e estrela cintilando (máximo).

signal buy_requested(id: StringName)
signal hovered(id: StringName)

const SIZE := 32
const HALF := 16
const HOLD_DELAY := 0.3
const HOLD_REPEAT := 0.1
const BREATH := 0.6  # MANIFEST: linha 0 ↔ linha 1 a cada 600 ms
const MAX_FRAMES: Array[float] = [1.2, 0.1, 0.15]
const HOVER_LIFT := 2
const BADGE_FRAME := Vector2(8, 10)

const MEDALLIONS_PATH := "res://assets/ui/tree/medallions32.png"
const ICONS_PATH := "res://assets/ui/tree/node_icons.png"
const PIPS_PATH := "res://assets/ui/tree/pips.png"
const BADGE_PATH := "res://assets/ui/tree/fx_new_badge.png"
## ART-A2 (MANIFEST frame_*): sobreposições por tipo, lado selado e Raízes-mestras.
const FRAME_AT_PATH := "res://assets/ui/tree/frame_at.png"
const FRAME_R_PATH := "res://assets/ui/tree/frame_r.png"
const FRAME_D_PATH := "res://assets/ui/tree/frame_d.png"
const FRAME_SEALED_PATH := "res://assets/ui/tree/frame_sealed.png"
const FRAME_MASTERS_PATH := "res://assets/ui/tree/frame_masters.png"
## frame_masters: células 40×40; canto = centro do nó − (20, 20) = canto do medalhão 32 − (4, 4).
const MASTER_SIZE := 40
const MASTER_INSET := Vector2(4, 4)
const MASTER_COLUMN: Dictionary = {
	SkillNodeData.Branch.CENTER: 0,
	SkillNodeData.Branch.DIG: 0,
	SkillNodeData.Branch.LANTERN: 1,
	SkillNodeData.Branch.FORTUNE: 2,
	SkillNodeData.Branch.CEMETERY: 3,
	SkillNodeData.Branch.HELPERS: 4,
	SkillNodeData.Branch.SOULS: 5,
	SkillNodeData.Branch.LUNAR: 0,
}
const MASTER_COL_SHADOW := 6
const MEDALLION_COLUMN: Dictionary = {
	SkillNodeData.Branch.CENTER: 0,
	SkillNodeData.Branch.DIG: 0,
	SkillNodeData.Branch.LANTERN: 1,
	SkillNodeData.Branch.FORTUNE: 2,
	SkillNodeData.Branch.CEMETERY: 3,
	SkillNodeData.Branch.HELPERS: 4,
	SkillNodeData.Branch.SOULS: 5,
	SkillNodeData.Branch.LUNAR: 6,
}
const COL_HIDDEN := 7
const COL_MAX := 8
## Placeholder por código (sem arte): moldura por ramo [escuro, claro] (DA §10.3).
const BRANCH_COLORS: Dictionary = {
	SkillNodeData.Branch.CENTER: [16, 17],
	SkillNodeData.Branch.DIG: [16, 17],
	SkillNodeData.Branch.LANTERN: [25, 26],
	SkillNodeData.Branch.FORTUNE: [26, 23],
	SkillNodeData.Branch.CEMETERY: [11, 12],
	SkillNodeData.Branch.HELPERS: [5, 6],
	SkillNodeData.Branch.SOULS: [30, 23],
	SkillNodeData.Branch.LUNAR: [8, 26],
}

static var _medallions: Texture2D
static var _icons: Texture2D
static var _pips: Texture2D
static var _badge: Texture2D
static var _frame_kinds: Dictionary = {}  # kind (StringName) -> Texture2D
static var _frame_sealed: Texture2D
static var _frame_masters: Texture2D
static var _checked: bool = false

var node_id: StringName
## Só moldura + ícone (painel de informações): sem custo, pips, foco ou clique.
var preview_only: bool = false
var focused: bool = false
var _holding: bool = false
var _hold_t: float = 0.0
var _next_repeat: float = 0.0
var _t: float = 0.0
var _hover: bool = false
var _lift: float = 0.0
var _pip_flash: float = 0.0


static func _load_textures() -> void:
	if _checked:
		return
	_checked = true
	_medallions = AssetManifest.texture(MEDALLIONS_PATH)
	_icons = AssetManifest.texture(ICONS_PATH)
	_pips = AssetManifest.texture(PIPS_PATH)
	_badge = AssetManifest.texture(BADGE_PATH)
	_frame_kinds = {
		&"At": AssetManifest.texture(FRAME_AT_PATH),
		&"R": AssetManifest.texture(FRAME_R_PATH),
		&"D": AssetManifest.texture(FRAME_D_PATH),
	}
	_frame_sealed = AssetManifest.texture(FRAME_SEALED_PATH)
	_frame_masters = AssetManifest.texture(FRAME_MASTERS_PATH)


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = Vector2(HALF, HALF)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_t = randf() * 2.0  # fases diferentes: nem todos respiram juntos


func _ready() -> void:
	_load_textures()
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(func() -> void: _hover = false)


func _on_enter() -> void:
	_hover = true
	if not preview_only:
		Juice.pop(self, 0.1, 0.14)  # UI/UX §7.3: 1,0 → 1,1 → 1,0 em 140 ms
		Audio.play(&"ui_hover")
	hovered.emit(node_id)


func _gui_input(event: InputEvent) -> void:
	if preview_only:
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_holding = true
		_hold_t = 0.0
		_next_repeat = HOLD_DELAY
		buy_requested.emit(node_id)
	else:
		_holding = false
	accept_event()


func is_holding() -> bool:
	return _holding and _hold_t >= HOLD_DELAY


func _process(delta: float) -> void:
	_t += delta
	if _holding:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_holding = false
		else:
			_hold_t += delta
			while _hold_t >= _next_repeat:
				_next_repeat += HOLD_REPEAT
				buy_requested.emit(node_id)
	var target := float(HOVER_LIFT) if _hover and not preview_only else 0.0
	_lift = move_toward(_lift, target, delta * 25.0)
	if _pip_flash > 0.0:
		_pip_flash -= delta
	queue_redraw()


## Compra: squash no clique (pops menores ao segurar) e o último pip pisca.
func bought(small: bool) -> void:
	if small:
		Juice.pop(self, 0.06, 0.1)
	else:
		Juice.squash(self, Vector2(1.18, 0.82), 0.06, 0.16)
	_pip_flash = 0.3


## Novo nó: brota do chão (escala 0 → 1,15 → 1), UI/UX §7.3.
func sprout(delay: float = 0.0) -> void:
	scale = Vector2.ZERO
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(self, "scale", Vector2.ONE * 1.15, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _draw() -> void:
	var tree := Game.tree
	var d := tree.get_node_data(node_id)
	if d == null:
		return
	var off := Vector2(0, -roundf(_lift))
	if not tree.is_revealed(node_id):
		# Oculto: silhueta com "?" que oscila levemente (±1 px).
		var wobble := Vector2(0, roundf(sin(_t * 2.0)) * (1.0 if not Juice.reduce_motion() else 0.0))
		if tree.is_master(node_id):
			# Silhueta 40×40 da Raiz-mestra (UI/UX §18.1): frame_master_shadow, sem ícone.
			if _draw_master_frame(MASTER_COL_SHADOW, off + wobble):
				return
			_draw_master_ring(off + wobble, Palette.NIGHT, Palette.BG)
		_draw_medallion(COL_HIDDEN, 0, d, off + wobble)
		return
	if tree.is_sealed(node_id) and not preview_only:
		_draw_sealed(off)
		return
	var maxed := tree.is_maxed(node_id)
	var affordable := not maxed and tree.can_buy(node_id, Economy.balances)
	var col := int(MEDALLION_COLUMN.get(d.branch, 0))
	var row := 0
	if maxed:
		var f := TreeArt.frame_at(_t, MAX_FRAMES)
		col = COL_MAX if f == 0 else (7 if f == 1 else 8)
		row = 0 if f == 0 else 1
	elif affordable and not preview_only and int(_t / BREATH) % 2 == 1:
		row = 1  # halo de respirar
	# Raiz-mestra: frame_masters substitui o medalhão 32 (ícone em (12, 12) da célula 40).
	var master_drawn: bool = d.kind == &"M" and _draw_master_frame(int(MASTER_COLUMN.get(d.branch, 0)), off)
	if not master_drawn:
		if d.kind == &"M":
			_draw_master_ring(off, Palette.COFFIN_DARK, Palette.COFFIN_LIGHT)
		_draw_medallion(col, row, d, off)
	_draw_icon(d, off)
	_draw_kind(d.kind, off)
	if preview_only:
		return
	var lvl := tree.level_of(node_id)
	var pips := lvl > 0 and not maxed and d.max_level > 1
	if pips:
		_draw_pips(lvl, d.max_level, off)
	if not maxed and d.base_cost > 0.0:
		# TreeLayout: a caixa do custo é a mesma que o layout e as raízes respeitam.
		var text := NumberFormat.format(tree.next_cost(node_id)) + _currency_suffix(d.currency)
		_draw_centered_text(text, HALF + TreeLayout.label_baseline(pips), Palette.color(Palette.BONE if affordable else Palette.DANGER))
	if not Game.seen_nodes.has(node_id) and not d.starts_owned:
		_draw_badge(off)
	if focused:
		_draw_focus_corners(off)


func _draw_medallion(col: int, row: int, d: SkillNodeData, off: Vector2) -> void:
	if _medallions != null:
		draw_texture_rect_region(_medallions, Rect2(off, Vector2(SIZE, SIZE)), Rect2(col * SIZE, row * SIZE, SIZE, SIZE))
		return
	# Placeholder por código: octógono com aro na cor do ramo e miolo 03.
	var o := off
	_oct(Rect2(o, Vector2(32, 32)), Palette.OUTLINE)
	if col == COL_HIDDEN:
		_oct(Rect2(o + Vector2(1, 1), Vector2(30, 30)), Palette.BG)
		_draw_centered_text("?", 21, Palette.color(Palette.MOONSHADOW), o)
		return
	var colors: Array = BRANCH_COLORS.get(d.branch, [7, 8])
	var dark := Palette.LANTERN_BRIGHT if col >= COL_MAX - 1 and Game.tree.is_maxed(d.id) else int(colors[0])
	_oct(Rect2(o + Vector2(1, 1), Vector2(30, 30)), dark)
	draw_rect(Rect2(o + Vector2(4, 2), Vector2(24, 1)), Palette.color(int(colors[1])))
	draw_rect(Rect2(o + Vector2(7, 7), Vector2(18, 18)), Palette.color(Palette.OUTLINE))
	draw_rect(Rect2(o + Vector2(8, 8), Vector2(16, 16)), Palette.color(Palette.NIGHT))
	if row == 1:
		for k: int in range(0, 32, 2):
			draw_rect(Rect2(o + Vector2(k, -2), Vector2.ONE), Palette.color(int(colors[1])))
			draw_rect(Rect2(o + Vector2(k + 1, 33), Vector2.ONE), Palette.color(int(colors[1])))


## Célula de frame_masters no lugar do medalhão. false = sem a arte (usa o fallback).
func _draw_master_frame(col: int, off: Vector2) -> bool:
	if _frame_masters == null:
		return false
	var cell := Vector2(MASTER_SIZE, MASTER_SIZE)
	draw_texture_rect_region(_frame_masters, Rect2(off - MASTER_INSET, cell), Rect2(Vector2(col * MASTER_SIZE, 0), cell))
	return true


## Molduras por tipo (UI/UX §18.1, DA §10.3): frame_at/r/d por cima do medalhão do ramo e do
## ícone, no mesmo canto (o quadrado do ícone é transparente). Sem a arte, desenho por código.
func _draw_kind(kind: StringName, off: Vector2) -> void:
	var overlay: Texture2D = _frame_kinds.get(kind, null) as Texture2D
	if overlay != null:
		draw_texture(overlay, off)
		return
	match kind:
		&"At":
			# Aro com 4 raios de luz 26 nas diagonais: "botão novo".
			var c := Palette.color(Palette.LANTERN_BRIGHT)
			for corner: Vector2 in [Vector2(2, 2), Vector2(29, 2), Vector2(2, 29), Vector2(29, 29)]:
				var dir := Vector2(-1.0 if corner.x < HALF else 1.0, -1.0 if corner.y < HALF else 1.0)
				for k: int in range(1, 4):
					draw_rect(Rect2(off + corner + dir * k, Vector2.ONE), c)
		&"R":
			# Aro rúnico: pontos 28 nas 8 direções.
			var c := Palette.color(Palette.ECTO)
			var o := Palette.color(Palette.OUTLINE)
			for i: int in 8:
				var a := TAU * float(i) / 8.0
				var p := (off + Vector2(HALF, HALF) + Vector2(cos(a), sin(a)) * 17.0).floor()
				draw_rect(Rect2(p - Vector2.ONE, Vector2(3, 3)), o)
				draw_rect(Rect2(p, Vector2.ONE), c)
		&"D":
			# Cadeado aberto 8×8 no topo: "coisa nova no campo".
			var p := off + Vector2(12, -7)
			draw_rect(Rect2(p + Vector2(0, 3), Vector2(8, 5)), Palette.color(Palette.OUTLINE))
			draw_rect(Rect2(p + Vector2(1, 4), Vector2(6, 3)), Palette.color(Palette.LANTERN))
			draw_rect(Rect2(p + Vector2(1, 4), Vector2(6, 1)), Palette.color(Palette.LANTERN_BRIGHT))
			draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 4)), Palette.color(Palette.STONE_LIGHT))
			draw_rect(Rect2(p + Vector2(1, 0), Vector2(4, 1)), Palette.color(Palette.STONE_LIGHT))
			draw_rect(Rect2(p + Vector2(4, 0), Vector2(1, 2)), Palette.color(Palette.STONE_LIGHT))


## Raiz-mestra: raízes abraçando um medalhão de 40×40 (4 px além dos 32 da célula).
func _draw_master_ring(off: Vector2, dark: int, light: int) -> void:
	var o := off - Vector2(4, 4)
	_oct(Rect2(o, Vector2(40, 40)), Palette.OUTLINE)
	_oct(Rect2(o + Vector2(1, 1), Vector2(38, 38)), dark)
	var l := Palette.color(light)
	for y: int in range(8, 32, 6):
		draw_rect(Rect2(o + Vector2(1, y), Vector2(2, 3)), l)
		draw_rect(Rect2(o + Vector2(37, y + 3), Vector2(2, 3)), l)
	for x: int in range(9, 32, 7):
		draw_rect(Rect2(o + Vector2(x, 1), Vector2(3, 2)), l)
		draw_rect(Rect2(o + Vector2(x + 3, 37), Vector2(3, 2)), l)


## Selado (UI/UX §18.1): pedra fria 06/07, sem respirar, raiz cortada e "×" 8×8.
func _draw_sealed(off: Vector2) -> void:
	if _frame_sealed != null:
		draw_texture(_frame_sealed, off)  # MANIFEST frame_sealed: no lugar do medalhão, sem ícone
		return
	_oct(Rect2(off, Vector2(32, 32)), Palette.OUTLINE)
	_oct(Rect2(off + Vector2(1, 1), Vector2(30, 30)), Palette.STONE_DARK)
	_oct(Rect2(off + Vector2(4, 4), Vector2(24, 24)), Palette.STONE)
	draw_rect(Rect2(off + Vector2(5, 3), Vector2(18, 1)), Palette.color(Palette.STONE_LIGHT))
	var x := Palette.color(Palette.OUTLINE)
	for i: int in 8:
		draw_rect(Rect2(off + Vector2(12 + i, 12 + i), Vector2(1, 1)), x)
		draw_rect(Rect2(off + Vector2(19 - i, 12 + i), Vector2(1, 1)), x)
	# Toco da raiz cortada saindo por baixo, com a falha do corte.
	draw_rect(Rect2(off + Vector2(15, 30), Vector2(2, 2)), Palette.color(Palette.COFFIN_DARK))
	draw_rect(Rect2(off + Vector2(15, 35), Vector2(2, 3)), Palette.color(Palette.COFFIN_DARK))


func _oct(r: Rect2, idx: int) -> void:
	var c := Palette.color(idx)
	draw_rect(Rect2(r.position + Vector2(3, 0), Vector2(r.size.x - 6, r.size.y)), c)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, r.size.y - 2)), c)
	draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(r.size.x, r.size.y - 6)), c)


func _draw_icon(d: SkillNodeData, off: Vector2) -> void:
	if _icons != null and d.icon_cell.x >= 0:
		draw_texture_rect_region(_icons, Rect2(off + Vector2(8, 8), Vector2(16, 16)), Rect2(Vector2(d.icon_cell) * 16.0, Vector2(16, 16)))
		return
	_draw_centered_text(String(node_id), 20, Palette.color(Palette.BONE), off)


## MANIFEST tree_pips: células 4×4 com passo de 3 px; topo 1 px abaixo do medalhão.
func _draw_pips(level: int, max_level: int, off: Vector2) -> void:
	var w := 3 * max_level + 1
	var x0 := float((SIZE - w) >> 1)
	var y := HALF + TreeLayout.PIPS_TOP
	for i: int in max_level:
		var col := 0
		if i < level:
			col = 1
			if i == level - 1 and (int(_t * 2.0) % 2 == 0 or _pip_flash > 0.0):
				col = 2  # o último pip preenchido brilha
		var p := off + Vector2(x0 + i * 3, y)
		if _pips != null:
			draw_texture_rect_region(_pips, Rect2(p, Vector2(4, 4)), Rect2(col * 4, 0, 4, 4))
		else:
			draw_rect(Rect2(p, Vector2(4, 4)), Palette.color(Palette.OUTLINE))
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(2, 2)), Palette.color([Palette.NIGHT_VIOLET, Palette.LANTERN_BRIGHT, Palette.BONE_BRIGHT][col]))


## "!" de novidade até o primeiro hover (MANIFEST fx_tree_new_badge: topo-esq. em centro + (10, −22)).
func _draw_badge(off: Vector2) -> void:
	var pos := off + Vector2(HALF + 10, HALF - 22)
	var f := int(_t / 0.3) % 2
	if _badge != null:
		draw_texture_rect_region(_badge, Rect2(pos, BADGE_FRAME), Rect2(f * BADGE_FRAME.x, 0, BADGE_FRAME.x, BADGE_FRAME.y))
	else:
		UiTheme.draw_outlined(self, UiTheme.title_font(), pos + Vector2(1, 12 - f), "!", UiTheme.SIZE_TITLE, Palette.color(Palette.LANTERN_BRIGHT))


## Cantoneiras 3×3 em 26, 2 px fora do medalhão.
func _draw_focus_corners(off: Vector2) -> void:
	var c := Palette.color(Palette.LANTERN_BRIGHT)
	var a := -3.0
	var b := float(SIZE) + 2.0
	for corner: Vector2 in [Vector2(a, a), Vector2(b, a), Vector2(a, b), Vector2(b, b)]:
		var sx := 1.0 if corner.x < 0.0 else -1.0
		var sy := 1.0 if corner.y < 0.0 else -1.0
		var p := corner + off
		draw_rect(Rect2(p, Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(sx, 0), Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(2 * sx, 0), Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(0, sy), Vector2(1, 1)), c)
		draw_rect(Rect2(p + Vector2(0, 2 * sy), Vector2(1, 1)), c)


static func _currency_suffix(currency: StringName) -> String:
	match currency:
		&"bones":
			return " os"
		&"souls":
			return " al"
	return ""


func _draw_centered_text(text: String, baseline: float, color: Color, off: Vector2 = Vector2.ZERO) -> void:
	var font := UiTheme.body_font()
	var fs := UiTheme.SIZE_BODY
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	UiTheme.draw_outlined(self, font, off + Vector2(roundf(HALF - w * 0.5), baseline), text, fs, color)
