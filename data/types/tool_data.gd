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
