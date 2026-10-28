extends SceneTree

var _last_jump := Vector2.ZERO
var _jump_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var minimap := (load("res://scenes/tree/tree_minimap.gd") as Script).new() as Control
	var tree := SkillTreeModel.new(SkillTreeModel.load_definitions("res://data/skill_nodes/"))
	minimap.setup(tree, TreeArt.WORLD, Vector2(640, 360))
	minimap.jump_requested.connect(_on_jump)
	root.add_child(minimap)
	await process_frame
	var map_rect: Rect2 = minimap.call("_map_rect")
	var center: Vector2 = minimap.call("_world_at", map_rect.get_center())
	assert(center.distance_to(TreeArt.WORLD * 0.5) < 0.1, "minimap center should map to world center")
	assert(minimap.get("_frame") is Texture2D, "wood frame texture should load")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map_rect.get_center()
	minimap.call("_gui_input", click)
	assert(_jump_count == 1, "click should request a camera jump")
	assert(_last_jump.distance_to(TreeArt.WORLD * 0.5) < 0.1, "click should target the world center")
	minimap.call("set_camera_pos", Vector2(500, 300))
	await process_frame
	print("PASS tree minimap frame, world mapping, click navigation, and redraw")
	quit(0)


func _on_jump(world_point: Vector2) -> void:
	_last_jump = world_point
	_jump_count += 1
