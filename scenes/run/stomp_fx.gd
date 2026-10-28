class_name StompFx
extends Sprite2D
## Anel de impacto em 4 quadros (DA §11.2, UI/UX §13.1).

const FRAME_SIZE := Vector2(24, 24)
const FRAME_TIME := 0.083
const FRAME_COUNT := 4

var _atlas: Texture2D
var _elapsed: float = 0.0
var _frame: int = -1


func setup(atlas: Texture2D, target_size: Vector2) -> void:
	_atlas = atlas
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 50
	scale = target_size / FRAME_SIZE
	_set_frame(0)


func _process(delta: float) -> void:
	_elapsed += delta
	var next_frame := int(_elapsed / FRAME_TIME)
	if next_frame >= FRAME_COUNT:
		queue_free()
		return
	if next_frame != _frame:
		_set_frame(next_frame)


func _set_frame(index: int) -> void:
	_frame = index
	var region := AtlasTexture.new()
	region.atlas = _atlas
	region.region = Rect2(Vector2(FRAME_SIZE.x * index, 0), FRAME_SIZE)
	texture = region
