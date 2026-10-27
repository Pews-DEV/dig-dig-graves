class_name HudMedal
extends Control
## Medalha de nível 24×24 de cobre com o número em m6x11 (UI/UX §3–4).
## Subir de nível: pula −4 px (200 ms, back-out) e um brilho varre o disco.

const SHINE_TIME := 0.6

var level: int = 1:
	set(v):
		if v != level:
			level = v
			queue_redraw()
var _shine: float = -1.0


## Referência guardada: o canvas só guarda o RID; sem isto a textura seria liberada.
var _art: Texture2D = AssetManifest.texture(UiKit.MEDAL_PATH)


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func jump() -> void:
	Juice.nudge(self, Vector2(0, -4) * maxf(Juice.motion(), 0.5), 0.4)
	if not Juice.reduce_flashes():
		_shine = 0.0


func _process(delta: float) -> void:
	if _shine >= 0.0:
		_shine += delta
		if _shine > SHINE_TIME:
			_shine = -1.0
		queue_redraw()


func _draw() -> void:
	var art := _art
	if art != null:
		# MANIFEST medalha_nivel: idle = frame 0; special = frames 1–4 (83 ms) varrendo o brilho.
		var f := 0 if _shine < 0.0 else clampi(1 + int(_shine / 0.083), 1, 4)
		if _shine > 0.333:
			f = 0
		draw_texture_rect_region(art, Rect2(0, 0, 24, 24), Rect2(f * 24, 0, 24, 24))
	else:
		draw_texture(UiKit.medal_texture(), Vector2.ZERO)
	if _shine >= 0.0 and art == null:
		var d := roundi(lerpf(-24.0, 24.0, _shine / SHINE_TIME))
		var c := Palette.color(Palette.BONE_BRIGHT)
		for y: int in 24:
			for x: int in 24:
				if absi(x - y - d) <= 1 and Vector2(x, y).distance_to(Vector2(11.5, 11.5)) <= 10.0:
					draw_rect(Rect2(x, y, 1, 1), c)
	var font := UiTheme.title_font()
	var text := str(level)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_TITLE).x
	UiTheme.draw_outlined(self, font, Vector2(roundf(12.0 - w * 0.5), 17), text, UiTheme.SIZE_TITLE, Palette.color(Palette.BONE_BRIGHT))
