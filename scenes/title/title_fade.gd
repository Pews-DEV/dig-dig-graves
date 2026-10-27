class_name TitleFade
extends TextureRect
## Preto da abertura (UI/UX §9.3) em dither Bayer 4×4 com a cor 01 (paleta fechada, sem alfa).

var level: float = 1.0:
	set(v):
		level = clampf(v, 0.0, 1.0)
		var lv := roundi(level * 16.0)
		visible = lv > 0
		if visible:
			texture = TitleArt.fade_texture(lv)


func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_TILE
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	level = 1.0
