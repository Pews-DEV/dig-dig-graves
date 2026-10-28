class_name BossView
extends Node2D
## Render simples do Caixão Fujão: usa a folha e as tags publicadas no manifesto.

var state: RunState
var tiles: TileMapLayer
var sheet: AsepriteSheet
var hole_texture: Texture2D
var elapsed := 0.0
var phase: StringName = &"idle"
var phase_elapsed := 0.0
var display_center := Vector2.ZERO
var next_center := Vector2.ZERO
var burrows: Array[Dictionary] = []


func setup(p_state: RunState, p_tiles: TileMapLayer) -> void:
	state = p_state
	tiles = p_tiles
	sheet = AsepriteSheet.load_id("boss_caixao_fujao")
	hole_texture = AssetManifest.texture_by_id("boss_caixao_buraco")
	state.boss_hopped.connect(_on_hopped)
	state.finished.connect(_on_finished)
	state.tile_regenerated.connect(_on_tile_regenerated)
	display_center = _center_of(state.boss_cells)
	next_center = display_center
	set_process(state.boss_active)
	visible = state.boss_active


func _process(delta: float) -> void:
	if state == null or not state.boss_active:
		return
	elapsed += delta
	phase_elapsed += delta
	if phase == &"sink" and phase_elapsed >= 0.5:
		phase = &"emerge"
		phase_elapsed = 0.0
		display_center = next_center
	elif phase == &"emerge" and phase_elapsed >= 0.5:
		phase = &"idle"
		phase_elapsed = 0.0
	queue_redraw()


func _draw() -> void:
	if state == null or not state.boss_active or state.boss_cells.is_empty():
		return
	if hole_texture != null:
		for burrow: Dictionary in burrows:
			var burrow_center: Vector2 = burrow.center
			draw_texture(hole_texture, (burrow_center - Vector2(32, 16)).round())
	var center := display_center
	if phase == &"idle":
		center = _center_of(state.boss_cells)
	if sheet != null and sheet.texture != null:
		var tag := &"defeat" if state.result.boss_victory else phase
		var frame := sheet.frame_at(tag, phase_elapsed if tag != &"idle" else elapsed, tag == &"idle")
		sheet.draw_frame(self, frame, center, Vector2(32, 32))
	else:
		# O asset está no manifesto; a forma é apenas uma proteção para exportações incompletas.
		draw_rect(Rect2(center - Vector2(10, 8), Vector2(20, 16)), Palette.color(Palette.COFFIN_DARK))
		draw_rect(Rect2(center - Vector2(8, 10), Vector2(16, 4)), Palette.color(Palette.COFFIN))


func _center_of(cells: Array[Vector2i]) -> Vector2:
	var center := Vector2.ZERO
	for cell: Vector2i in cells:
		center += tiles.map_to_local(cell)
	return center / maxf(1.0, float(cells.size()))


func _on_hopped(old_cells: Array[Vector2i], new_cells: Array[Vector2i]) -> void:
	display_center = _center_of(old_cells)
	next_center = _center_of(new_cells)
	burrows.append({"cells": old_cells.duplicate(), "center": display_center})
	phase = &"sink"
	phase_elapsed = 0.0


func _on_finished(_result: TurnResult) -> void:
	burrows.clear()
	display_center = _center_of(state.boss_cells)
	phase = &"defeat" if state.result.boss_victory else &"idle"
	phase_elapsed = 0.0
	queue_redraw()


func _on_tile_regenerated(cell: Vector2i) -> void:
	for burrow: Dictionary in burrows.duplicate():
		if (burrow.cells as Array).has(cell):
			burrows.erase(burrow)
			queue_redraw()
