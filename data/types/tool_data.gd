class_name ToolData
extends Resource
## Ferramenta (GDD §8): define o formato da área e modificadores de dano/intervalo.

enum Shape { SQUARE, CROSS, LINE, DIAMOND }

@export var id: StringName
@export var display_name: String
@export var shape: Shape = Shape.SQUARE
@export var damage_mult: float = 1.0
@export var interval_mult: float = 1.0
@export var ignores_rock_drain: bool = false


## Células da área (sem recorte) para um centro e raio. `rotation` só afeta LINE.
func cells(center: Vector2i, radius: int, rotation: int = 0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match shape:
		Shape.SQUARE:
			for dy: int in range(-radius, radius + 1):
				for dx: int in range(-radius, radius + 1):
					out.append(center + Vector2i(dx, dy))
		Shape.CROSS:
			var arm := radius + 1
			out.append(center)
			for d: int in range(1, arm + 1):
				out.append_array([center + Vector2i(d, 0), center + Vector2i(-d, 0), center + Vector2i(0, d), center + Vector2i(0, -d)])
		Shape.LINE:
			var half := radius + 1
			var dir := Vector2i(1, 0) if rotation % 2 == 0 else Vector2i(0, 1)
			for d: int in range(-half, half + 1):
				out.append(center + dir * d)
		Shape.DIAMOND:
			var r := radius + 2
			for dy: int in range(-r, r + 1):
				for dx: int in range(-r, r + 1):
					if absi(dx) + absi(dy) <= r:
						out.append(center + Vector2i(dx, dy))
	return out


## GDD §4.4: converte passos em uma área que cresce um lado por vez
## (1×1, 1×2, 2×2 ...). `anchor` é o tile sob o cursor; quando um lado
## é par, o bloco avança para +x/+y a partir dele.
func cells_for_step(anchor: Vector2i, step: int, rotation: int = 0) -> Array[Vector2i]:
	var safe_step := clampi(step, 0, 10)
	var width := int(ceil(float(safe_step + 1) / 2.0))
	var height := int(floor(float(safe_step + 1) / 2.0)) + 1
	if rotation % 2 != 0:
		var swap := width
		width = height
		height = swap
	var x0 := anchor.x - int(floor(float(width - 1) / 2.0))
	var y0 := anchor.y - int(floor(float(height - 1) / 2.0))
	var out: Array[Vector2i] = []
	match shape:
		Shape.SQUARE:
			for y: int in height:
				for x: int in width:
					out.append(Vector2i(x0 + x, y0 + y))
		Shape.CROSS:
			for y: int in height:
				for x: int in width:
					if x == floori(float(width) / 2.0) or y == floori(float(height) / 2.0):
						out.append(Vector2i(x0 + x, y0 + y))
		Shape.LINE:
			var length := maxi(width, height)
			var horizontal := width >= height
			if rotation % 2 != 0:
				horizontal = not horizontal
			for i: int in length:
				var offset := i - int(floor(float(length - 1) / 2.0))
				out.append(anchor + (Vector2i(offset, 0) if horizontal else Vector2i(0, offset)))
		Shape.DIAMOND:
			var rx := maxi(0, int(floor(float(width - 1) / 2.0)))
			var ry := maxi(0, int(floor(float(height - 1) / 2.0)))
			for y: int in height:
				for x: int in width:
					var dx := absi(x - int(floor(float(width - 1) / 2.0)))
					var dy := absi(y - int(floor(float(height - 1) / 2.0)))
					if (rx == 0 or dx == 0) and (ry == 0 or dy == 0):
						out.append(Vector2i(x0 + x, y0 + y))
	return out
