class_name Palette
extends RefCounted
## Paleta fechada "Lua de Cova 32" (Direção de Arte §3).
## Índices 1-based, iguais aos do documento. Única fonte de cores do jogo.

const HEX: Array[String] = [
	"0d0b14", "1a1626", "2a2440", "3d3660", "58507f", "7d789c", "a8a5bf", "d6d4e3",
	"1f3b35", "2f5a46", "4a7d55", "7aa35e", "2b1a17", "4a2c22", "6e4430", "946140",
	"b88a5a", "3b2230", "5e3340", "8a4b4f", "c9b48f", "e8dcc0", "fff6e0", "a8541a",
	"e08a2a", "ffc94a", "1b5e5a", "2fb39a", "7cf2c8", "8fd3ff", "8c2b3a", "d0465a",
]

# Direção de Arte §4.2: variante "iluminada" = 1 degrau acima na rampa. 21–32 não mudam.
const LIT_MAP: Dictionary = {
	1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 8,
	9: 10, 10: 11, 11: 12, 12: 12,
	13: 14, 14: 15, 15: 16, 16: 17, 17: 17,
	18: 19, 19: 20, 20: 20,
}

# Nomes semânticos usados com frequência (Direção de Arte §3).
const OUTLINE := 1
const BG := 2
const NIGHT := 3
const NIGHT_VIOLET := 4
const MOONSHADOW := 5
const STONE_DARK := 6
const STONE := 7
const STONE_LIGHT := 8
const GRASS_DEEP := 9
const GRASS_DARK := 10
const GRASS := 11
const GRASS_LIGHT := 12
const DIRT_BOTTOM := 13
const DIRT_DARK := 14
const DIRT := 15
const DIRT_LIGHT := 16
const DIRT_EDGE := 17
const COFFIN_DARK := 18
const COFFIN := 19
const COFFIN_LIGHT := 20
const BONE_SHADOW := 21
const BONE := 22
const BONE_BRIGHT := 23
const LANTERN_DARK := 24
const LANTERN := 25
const LANTERN_BRIGHT := 26
const ECTO_DARK := 27
const ECTO := 28
const ECTO_BRIGHT := 29
const SOUL := 30
const DANGER_DARK := 31
const DANGER := 32

static var _colors: Array[Color] = []
static var _index_by_rgb: Dictionary = {}


static func color(index: int) -> Color:
	_ensure()
	return _colors[clampi(index, 1, HEX.size()) - 1]


static func lit_index(index: int) -> int:
	return int(LIT_MAP.get(index, index))


## Índice 1-based de uma cor da paleta, ou 0 se a cor não for da paleta.
static func index_of(c: Color) -> int:
	_ensure()
	return int(_index_by_rgb.get(_key(c), 0))


static func size() -> int:
	return HEX.size()


static func _key(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


static func _ensure() -> void:
	if not _colors.is_empty():
		return
	for i: int in HEX.size():
		var c := Color.html(HEX[i])
		_colors.append(c)
		_index_by_rgb[_key(c)] = i + 1
