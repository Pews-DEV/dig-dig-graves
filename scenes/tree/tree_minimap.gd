class_name TreeMinimap
extends Control
## Minimapa clicável da Árvore (UI/UX §18.2).

signal jump_requested(world_point: Vector2)

const MAP_MARGIN := 5.0
const FRAME := Color("#6e4430")
const BACKGROUND := Color("#2a2440")
const FRAME_PATH := "res://assets/ui/tree/minimap_frame.png"

var tree: SkillTreeModel
var world_size := Vector2(1936, 1024)
var view_size := Vector2(640, 360)
var camera_pos := Vector2.ZERO
var _dragging := false
var _points: Array[Dictionary] = []
var _branches: Dictionary = {}
var _frame: Texture2D


func _ready() -> void:
	size = Vector2(96, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame = AssetManifest.texture(FRAME_PATH)


func setup(p_tree: SkillTreeModel, p_world_size: Vector2, p_view_size: Vector2) -> void:
	tree = p_tree
	world_size = p_world_size
	view_size = p_view_size
	_points.clear()
	_branches.clear()
	if tree != null:
		for id: StringName in tree.order:
			var data := tree.get_node_data(id)
			if data == null:
				continue
			var colors: Array = SkillNodeButton.BRANCH_COLORS.get(data.branch, [Palette.OUTLINE, Palette.BONE_BRIGHT])
			_points.append({
				"id": id,
				"pos": data.tree_position,
				"color": Palette.color(int(colors[1])),
				"master": data.kind == &"M",
			})
			var branch_id := int(data.branch)
			if branch_id > 0:
				if not _branches.has(branch_id):
					_branches[branch_id] = {"x": data.tree_position.x, "min_y": data.tree_position.y, "max_y": data.tree_position.y, "color": Palette.color(int(colors[0]))}
				else:
					var branch: Dictionary = _branches[branch_id]
					branch.min_y = minf(float(branch.min_y), data.tree_position.y)
					branch.max_y = maxf(float(branch.max_y), data.tree_position.y)
	queue_redraw()


func set_camera_pos(p: Vector2) -> void:
	camera_pos = p
	queue_redraw()


func _draw() -> void:
	var rect := _map_rect()
	draw_rect(rect, BACKGROUND)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), Palette.color(Palette.GRASS_DARK))
	# Sete faixas coloridas dão orientação por ramo sem encher o mapa de rótulos.
	for branch: Dictionary in _branches.values():
		var tint: Color = branch.color
		tint.a = 0.48
		draw_line(_to_map(Vector2(float(branch.x), float(branch.min_y))), _to_map(Vector2(float(branch.x), float(branch.max_y))), tint, 2.0)
	# Ipê e tronco mantêm uma referência de orientação mesmo antes de comprar nós.
	var trunk := _to_map(TreeArt.TRUNK_ROOT)
	var canopy := _to_map(Vector2(968, 80))
	draw_line(canopy, trunk, Palette.color(Palette.DIRT_LIGHT), 1.0)
	for point: Dictionary in _points:
		var id: StringName = point.id
		if not tree.is_owned(id):
			continue
		var p := _to_map(point.pos as Vector2).round()
		var footprint := Vector2(2, 2) if bool(point.master) else Vector2.ONE
		draw_rect(Rect2(p - footprint * 0.5, footprint), point.color as Color)
	var vp_pos := _to_map(camera_pos)
	var vp_end := _to_map(camera_pos + view_size)
	var viewport_rect := Rect2(vp_pos, vp_end - vp_pos).intersection(rect)
	draw_rect(viewport_rect, Palette.color(Palette.BONE_BRIGHT), false, 1.0)
	if _frame != null:
		draw_texture(_frame, Vector2.ZERO)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), FRAME, false, 1.0)


func _map_rect() -> Rect2:
	var available := size - Vector2(MAP_MARGIN * 2.0, MAP_MARGIN * 2.0)
	var scale := minf(available.x / world_size.x, available.y / world_size.y)
	var fitted := world_size * scale
	return Rect2((size - fitted) * 0.5, fitted)


func _to_map(world_point: Vector2) -> Vector2:
	var rect := _map_rect()
	return rect.position + Vector2(world_point.x / world_size.x, world_point.y / world_size.y) * rect.size


func _world_at(local_point: Vector2) -> Vector2:
	var rect := _map_rect()
	var normalized := (local_point - rect.position) / rect.size
	return Vector2(clampf(normalized.x, 0.0, 1.0) * world_size.x, clampf(normalized.y, 0.0, 1.0) * world_size.y)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		if button.pressed:
			jump_requested.emit(_world_at(button.position))
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		jump_requested.emit(_world_at(motion.position))
		accept_event()
