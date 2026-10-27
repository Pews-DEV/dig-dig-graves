class_name DirtParticles
extends Node2D
## Torrões e poeira (DA §9.2). Sistema próprio e leve em vez de CPUParticles2D:
## precisa de 1 quique no "chão" de cada tile e de pixels inteiros da paleta.

const LIFETIME := 0.4
const GRAVITY := 420.0
const MAX_PARTICLES := 400
const DUST_TIME := 0.25
const DUST_WIDTHS: Array[int] = [8, 12, 16]
## MANIFEST dust: frames 16×16, coluna = frame (0–2), linha = material; base (8,14) no pivô do tile.
const DUST_PATH := "res://assets/sprites/fx/dust.png"
const DUST_FRAME := Vector2(16, 16)
const DUST_PIVOT := Vector2(8, 14)

var _dust_texture: Texture2D = AssetManifest.texture(DUST_PATH)
## MANIFEST torroes: folha 3×3 de células 3×3; coluna = tamanho (1–3 px), linha = material.
const CLOD_PATH := "res://assets/sprites/fx/torroes.png"
const CLOD_CELL := 3
var _clod_texture: Texture2D = AssetManifest.texture(CLOD_PATH)

const FLASH_TIME := 0.06

var _flashes: Array[Dictionary] = []
var _parts: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


## Torrões: quadradinhos de 1–3 px nas cores do material, arco balístico, 1 quique.
## `material_row` = 0 grama, 1 terra, 2 barro (linha de `torroes`); −1 = cores por código.
func burst(origin: Vector2, colors: PackedInt32Array, count: int, strength: float = 1.0, material_row: int = -1) -> void:
	if colors.is_empty():
		return
	for i: int in count:
		if _parts.size() >= MAX_PARTICLES:
			_parts.pop_front()
		_parts.append({
			"pos": origin + Vector2(_rng.randi_range(-4, 4), _rng.randi_range(-2, 1)),
			"vel": Vector2(_rng.randf_range(-45.0, 45.0), _rng.randf_range(-95.0, -55.0)) * strength,
			"ground": origin.y + _rng.randi_range(1, 4),
			"color": Palette.color(colors[_rng.randi() % colors.size()]),
			"size": _rng.randi_range(1, 3 if strength >= 1.0 else 2),
			"age": 0.0,
			"bounced": false,
			"row": material_row,
		})


## Poeira de quebra de camada (3 frames, 250 ms). `material_row` = coluna S0..S2 da camada
## quebrada; sem o asset, desenha um anel iso por código na cor `color_index`.
func dust(origin: Vector2, color_index: int, material_row: int) -> void:
	_dust.append({"pos": origin, "age": 0.0, "color": Palette.color(color_index), "row": material_row})


## Flash de quebra: contorno do losango em 23 por ~1 frame (desligável com "reduzir flashes").
func flash(origin: Vector2) -> void:
	_flashes.append({"pos": origin, "age": 0.0})


func _process(delta: float) -> void:
	if _parts.is_empty() and _dust.is_empty() and _flashes.is_empty():
		return
	for f: Dictionary in _flashes:
		f.age = float(f.age) + delta
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return float(f.age) < FLASH_TIME)
	for p: Dictionary in _parts:
		p.age = float(p.age) + delta
		var vel: Vector2 = p.vel
		vel.y += GRAVITY * delta
		var pos: Vector2 = p.pos + vel * delta
		if pos.y >= float(p.ground) and vel.y > 0.0:
			pos.y = float(p.ground)
			if bool(p.bounced):
				vel = Vector2.ZERO
			else:
				vel = Vector2(vel.x * 0.5, -vel.y * 0.35)
				p.bounced = true
		p.vel = vel
		p.pos = pos
	_parts = _parts.filter(func(p: Dictionary) -> bool: return float(p.age) < LIFETIME)
	for d: Dictionary in _dust:
		d.age = float(d.age) + delta
	_dust = _dust.filter(func(d: Dictionary) -> bool: return float(d.age) < DUST_TIME)
	queue_redraw()


func _draw() -> void:
	for f: Dictionary in _flashes:
		IsoDraw.outline_diamond(self, (f.pos as Vector2).round(), 28, Palette.color(Palette.BONE_BRIGHT))
	for p: Dictionary in _parts:
		var s := int(p.size)
		var pos: Vector2 = p.pos
		if _clod_texture != null and int(p.row) >= 0:
			var src := Rect2((s - 1) * CLOD_CELL, int(p.row) * CLOD_CELL, CLOD_CELL, CLOD_CELL)
			draw_texture_rect_region(_clod_texture, Rect2(floorf(pos.x) - 1, floorf(pos.y) - 2, CLOD_CELL, CLOD_CELL), src)
			continue
		draw_rect(Rect2(floorf(pos.x), floorf(pos.y) - s + 1, s, s), p.color)
	for d: Dictionary in _dust:
		var frame := clampi(int(float(d.age) / (DUST_TIME / DUST_WIDTHS.size())), 0, DUST_WIDTHS.size() - 1)
		var pos: Vector2 = d.pos
		if _dust_texture != null:
			var src := Rect2(Vector2(frame * DUST_FRAME.x, int(d.row) * DUST_FRAME.y), DUST_FRAME)
			draw_texture_rect_region(_dust_texture, Rect2(pos.round() - DUST_PIVOT, DUST_FRAME), src)
			continue
		IsoDraw.outline_diamond(self, pos.round(), DUST_WIDTHS[frame], d.color)
