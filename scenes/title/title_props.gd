class_name TitleProps
extends RefCounted
## Props do primeiro plano da tela-título (UI/UX §9.6): a pá cravada no monte e a lanterna no
## chão com o halo. Somem quando o Coveiro faz o `stand`.


## Pá cravada (pa_cravada, pivô na base). Sem arte: cabo inclinado com alça em D e lâmina enterrada.
class StuckShovel:
	extends Node2D

	var _tex: Texture2D = TitleArt.texture(TitleArt.SHOVEL_STUCK)
	var wobble: int = 0:
		set(v):
			wobble = v
			queue_redraw()

	func _draw() -> void:
		if _tex != null:
			draw_texture(_tex, Vector2(-floorf(_tex.get_width() * 0.5) + wobble, 1.0 - _tex.get_height()))
			return
		var c := Palette.color(Palette.DIRT_EDGE)
		for i: int in 22:
			draw_rect(Rect2(-(i >> 2) + wobble, -i - 2, 2, 1), c)
		draw_rect(Rect2(-7 + wobble, -27, 6, 1), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(-7 + wobble, -29, 1, 3), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(-2 + wobble, -29, 1, 3), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(-3, -3, 7, 3), Palette.color(Palette.STONE))
		draw_rect(Rect2(-3, -3, 7, 1), Palette.color(Palette.STONE_LIGHT))


## Lanterna no chão (lanterna_chao: 12×16, pivô (6, 15), `idle` 3 frames a 8 fps), desenhada
## na frente do Coveiro.
class GroundLantern:
	extends Node2D

	const FRAMES: Array[float] = [0.125, 0.125, 0.125]
	var _sheet: AsepriteSheet = TitleArt.sheet(TitleArt.LANTERN)
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _sheet != null:
			var fs := _sheet.frame_size()
			_sheet.draw_frame(self, _sheet.frame_at(&"idle", _t, true), Vector2.ZERO, Vector2(floorf(fs.x * 0.5), fs.y - 1.0))
			return
		var f := TreeArt.frame_at(_t, FRAMES)
		draw_rect(Rect2(-3, -11, 7, 11), Palette.color(Palette.OUTLINE))
		draw_rect(Rect2(-2, -10, 5, 9), Palette.color(Palette.LANTERN_DARK))
		draw_rect(Rect2(-1, -8, 3, 5), Palette.color(Palette.LANTERN))
		draw_rect(Rect2(0, -7 + (1 if f == 2 else 0), 1, 2), Palette.color(Palette.LANTERN_BRIGHT if f != 1 else Palette.BONE_BRIGHT))
		draw_rect(Rect2(-1, -13, 3, 2), Palette.color(Palette.OUTLINE))


## Halo da lanterna (lanterna_chao_halo, 56×36, centro (28, 18)): atrás do Coveiro e da pá.
## Sem arte: elipse em xadrez 25/24 que "respira" 1 px (parada com "reduzir flashes").
class LanternHalo:
	extends Node2D

	const R := Vector2(27, 17)
	var _tex: Texture2D = TitleArt.texture(TitleArt.LANTERN_HALO)
	var _t: float = 0.0

	func _process(delta: float) -> void:
		var before := int(_t / 0.25)
		_t += delta
		if _tex == null and int(_t / 0.25) != before:
			queue_redraw()

	func _draw() -> void:
		if _tex != null:
			draw_texture(_tex, -(_tex.get_size() * 0.5).floor())
			return
		var grow := 0.0 if Juice.reduce_flashes() else float(int(_t / 0.25) % 2)
		for y: int in range(-int(R.y) - 1, int(R.y) + 2):
			for x: int in range(-int(R.x) - 1, int(R.x) + 2):
				var d := Vector2(x / (R.x + grow), y / (R.y + grow)).length()
				if d > 1.0 or (x + y) % 2 != 0:
					continue
				if d > 0.7 and (x % 4 != 0 or y % 2 != 0):
					continue
				draw_rect(Rect2(x, y, 1, 1), Palette.color(Palette.LANTERN if d < 0.4 else Palette.LANTERN_DARK))
