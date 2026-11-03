class_name HubTiao
extends Control
## Tião empoleirado na estação Próxima Noite (UI/UX §10.2, "Personagens na superfície"):
## idle do título (TitleTiao) e, no clique, um balão de Dica curto e não bloqueante (UI/UX §14.1).

## Falas que alternam a cada clique (chaves do translations.csv).
const LINES: Array[String] = [
	"Fogo-fátuo é óleo de graça, patrão. Não deixa escapar!",
	"Cova aberta, alma em paz. E um trocadinho pra mim!",
	"Terra tremendo? É o Caixão Fujão. Que medo, craá!",
]
## UI/UX §14.1: some sozinho em 3,5 s ou no clique.
const TIP_TIME := 3.5
const BUBBLE_W := 160
const BUBBLE_MIN_H := 32
const LINE_H := 9
const TAIL_PATH := "res://assets/ui/kit/balao_rabicho.png"
const BUBBLE_PATH := "res://assets/ui/kit/balao.png"
## Tamanho da área clicável; o pivô do Tião (pés) fica no meio da base.
const HIT_SIZE := Vector2(20, 18)

static var _next_line: int = 0

var _tiao: TitleTiao
var _bubble: Control
var _bubble_text: Label
var _tip_left: float = 0.0


func _ready() -> void:
	size = HIT_SIZE
	custom_minimum_size = HIT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_tiao = TitleTiao.new()
	_tiao.position = Vector2(floorf(HIT_SIZE.x * 0.5), HIT_SIZE.y - 1.0)
	add_child(_tiao)
	_build_bubble()


func _build_bubble() -> void:
	_bubble = Control.new()
	_bubble.z_index = 20
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.visible = false
	_bubble.gui_input.connect(_on_bubble_input)
	add_child(_bubble)
	var bubble_tex := AssetManifest.texture(BUBBLE_PATH)
	if bubble_tex != null:
		var patch := NinePatchRect.new()
		patch.texture = bubble_tex
		patch.patch_margin_left = 4
		patch.patch_margin_top = 4
		patch.patch_margin_right = 4
		patch.patch_margin_bottom = 5
		patch.set_anchors_preset(Control.PRESET_FULL_RECT)
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bubble.add_child(patch)
	else:
		# Placeholder: pergaminho 22 com contorno 01 (só cores da paleta).
		var frame := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.color(Palette.BONE)
		style.border_color = Palette.color(Palette.OUTLINE)
		style.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", style)
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bubble.add_child(frame)
	_bubble_text = Label.new()
	_bubble_text.theme_type_variation = &"ParchmentLabel"
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_bubble_text)
	var tail_tex := AssetManifest.texture(TAIL_PATH)
	if tail_tex != null:
		# MANIFEST balao_rabicho: coluna 0 = para baixo, ponta em (2, 6) da célula 10×10.
		var atlas := AtlasTexture.new()
		atlas.atlas = tail_tex
		atlas.region = Rect2(0, 0, 10, 10)
		var tail := TextureRect.new()
		tail.texture = atlas
		tail.name = "Tail"
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bubble.add_child(tail)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			accept_event()
			say_next()


func _on_bubble_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			_bubble.accept_event()
			_hide_bubble()


## Mostra a próxima fala da lista (alternando) num balão acima do Tião.
func say_next() -> void:
	var line := tr(LINES[_next_line % LINES.size()])
	_next_line = (_next_line + 1) % LINES.size()
	_tiao.play(TitleTiao.CAW)
	Audio.play(&"dialog_blip_tiao", 1.0, AudioBank.PITCH_VARIATION)
	_bubble_text.text = line
	_bubble_text.position = Vector2(5, 4)
	_bubble_text.size = Vector2(BUBBLE_W - 10, LINE_H)
	var lines := maxi(1, _bubble_text.get_line_count())
	var h := maxi(BUBBLE_MIN_H, lines * LINE_H + 9)
	_bubble_text.size = Vector2(BUBBLE_W - 10, h - 9)
	_bubble.size = Vector2(BUBBLE_W, h)
	# Balão acima da cabeça, rabicho apontando o Tião; o ponto do rabicho fica ~1/4 da largura.
	var head := Vector2(_tiao.position.x, _tiao.position.y - 16.0)
	var tail_x := 32.0
	_bubble.position = (head - Vector2(tail_x + 2.0, h + 4.0)).floor()
	var tail := _bubble.get_node_or_null(^"Tail") as TextureRect
	if tail != null:
		tail.position = Vector2(tail_x, h - 2)
	_bubble.visible = true
	_tip_left = TIP_TIME
	Juice.pop(_bubble, 0.08, 0.14)


func _hide_bubble() -> void:
	_bubble.visible = false
	_tip_left = 0.0


func _process(delta: float) -> void:
	if _tip_left <= 0.0:
		return
	_tip_left -= delta
	if _tip_left <= 0.0 or not is_visible_in_tree():
		_hide_bubble()
