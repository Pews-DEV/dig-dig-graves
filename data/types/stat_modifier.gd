class_name StatModifier
extends Resource
## Modificador {stat, op, value} (GDD §18.2). Agregado por StatSheet: (base + Σadd) × Πmul.

enum Op { ADD, MUL }

@export var stat: StringName
@export var op: Op = Op.ADD
@export var value: float = 0.0


static func make(p_stat: StringName, p_op: Op, p_value: float) -> StatModifier:
	var m := StatModifier.new()
	m.stat = p_stat
	m.op = p_op
	m.value = p_value
	return m


## Modificador equivalente a `levels` níveis deste (add soma, mul compõe).
func scaled(levels: int) -> StatModifier:
	var v: float = value * levels if op == Op.ADD else pow(value, levels)
	return StatModifier.make(stat, op, v)
