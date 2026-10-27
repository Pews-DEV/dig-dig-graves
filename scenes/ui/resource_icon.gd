class_name ResourceIcon
extends Control
## Ícones 16×16 (DA §10.2). Usa `icons_res.png` do manifesto (coluna = recurso);
## sem ele, ou para ícones que não estão no atlas (lanterna), desenha o placeholder ASCII.

enum Kind { COPPER, BONES, SOULS, LANTERN, SEAL, KEY }

const ATLAS_PATH := "res://assets/ui/icons/icons_res.png"
## MANIFEST icons_res: 0 = Cobre, 1 = Osso, 2 = Alma, 3 = Selo Lunar, 4 = Chave da Cripta.
const ATLAS_COLUMN: Dictionary = {Kind.COPPER: 0, Kind.BONES: 1, Kind.SOULS: 2, Kind.SEAL: 3, Kind.KEY: 4}

const LANTERN_PATH := "res://assets/ui/hud/icone_lanterna.png"
static var _lantern: Texture2D
static var _lantern_checked: bool = false
static var _atlas: Texture2D
static var _atlas_checked: bool = false

## Legenda: o = 01 contorno; demais letras = índice da paleta abaixo.
const LEGEND: Dictionary = {
	"o": 1, "a": 24, "b": 25, "c": 26, "s": 21, "w": 22, "h": 23, "u": 30, "n": 3, "d": 18, "e": 19,
}

const ART: Dictionary = {
	Kind.COPPER: [
		"...oooooo...",
		"..obbbbbbo..",
		".obccbbbbao.",
		"obcbbbbbbbao",
		"obcbbbbbbbao",
		"obbbboobbbao",
		"obbbboobbbao",
		"obbbbbbbbbao",
		"obbbbbbbbaao",
		".obbbbbbaao.",
		"..oaaaaaao..",
		"...oooooo...",
	],
	Kind.BONES: [
		".oo.......",
		"ohwo....oo",
		"owwwo..owwo",
		".owwwooowwso",
		"..owwwwwwwo.",
		"...owwwwwo..",
		"..owwwwwwo..",
		".owsooowwso.",
		"owwso..owsso",
		"owso....oso.",
		".oo......oo.",
	],
	Kind.SOULS: [
		".....o......",
		"....ouo.....",
		"...ouuo.....",
		"...ouhuo....",
		"..ouuhuuo...",
		".ouuuhhuuo..",
		".ouunuunuo..",
		"ouuunuunuuo.",
		"ouuuuuuuuuo.",
		".ouuuuuuuo..",
		"..ooooooo...",
	],
	Kind.LANTERN: [
		"....oooo....",
		"...o....o...",
		"..oooooooo..",
		"..oeccccdo..",
		"..oecbbcdo..",
		"..oechbcdo..",
		"..oecbbcdo..",
		"..oeccccdo..",
		"..oooooooo..",
		"...oeeddo...",
		"....oooo....",
	],
}

@export var kind: Kind = Kind.COPPER:
	set(value):
		kind = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(16, 16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func atlas() -> Texture2D:
	if not _atlas_checked:
		_atlas_checked = true
		_atlas = AssetManifest.texture(ATLAS_PATH)
	return _atlas


func _draw() -> void:
	if kind == Kind.LANTERN:
		if not _lantern_checked:
			_lantern_checked = true
			_lantern = AssetManifest.texture(LANTERN_PATH)
		if _lantern != null:
			draw_texture(_lantern, Vector2.ZERO)
			return
	var tex := atlas()
	if tex != null and ATLAS_COLUMN.has(kind):
		draw_texture_rect_region(tex, Rect2(0, 0, 16, 16), Rect2(int(ATLAS_COLUMN[kind]) * 16, 0, 16, 16))
		return
	if not ART.has(kind):
		return
	var rows: Array = ART[kind]
	var h := rows.size()
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var origin := Vector2i((16 - w) >> 1, (16 - h) >> 1)
	for y: int in h:
		var row: String = rows[y]
		for x: int in row.length():
			var ch := row[x]
			if LEGEND.has(ch):
				draw_rect(Rect2(origin + Vector2i(x, y), Vector2i.ONE), Palette.color(int(LEGEND[ch])))


static func kind_for_currency(currency: StringName) -> Kind:
	match currency:
		&"bones":
			return Kind.BONES
		&"souls":
			return Kind.SOULS
	return Kind.COPPER
