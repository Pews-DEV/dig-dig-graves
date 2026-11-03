class_name SkillTreeModel
extends RefCounted
## Estado puro da Árvore de Raízes (GDD §6): níveis, revelação, custos.
## Não toca em Economy: quem compra verifica/gasta e depois chama add_level().

const TREE_SOURCE := &"tree"

var nodes: Dictionary = {}  # StringName -> SkillNodeData
var order: Array[StringName] = []
var levels: Dictionary = {}  # StringName -> int
var _parents: Dictionary = {}  # StringName -> Array[StringName]
var trigger_state: Dictionary = {}


func _init(defs: Array[SkillNodeData] = []) -> void:
	for d: SkillNodeData in defs:
		nodes[d.id] = d
		order.append(d.id)
	for d: SkillNodeData in defs:
		for child: StringName in d.children:
			if not _parents.has(child):
				var list: Array[StringName] = []
				_parents[child] = list
			(_parents[child] as Array[StringName]).append(d.id)
	reset()


## Carrega todos os SkillNodeData (.tres) de uma pasta, em ordem de nome.
static func load_definitions(dir: String) -> Array[SkillNodeData]:
	var out: Array[SkillNodeData] = []
	var files := ResourceLoader.list_directory(dir)
	files.sort()
	for f: String in files:
		if not f.ends_with(".tres"):
			continue
		var res := load(dir.path_join(f)) as SkillNodeData
		if res != null:
			out.append(res)
	return out


func reset() -> void:
	levels.clear()
	trigger_state.clear()
	for id: StringName in order:
		levels[id] = 1 if (nodes[id] as SkillNodeData).starts_owned else 0


func get_node_data(id: StringName) -> SkillNodeData:
	return nodes.get(id) as SkillNodeData


func level_of(id: StringName) -> int:
	return int(levels.get(id, 0))


func is_owned(id: StringName) -> bool:
	return level_of(id) > 0


func is_maxed(id: StringName) -> bool:
	var d := get_node_data(id)
	return d != null and level_of(id) >= d.max_level


func parents_of(id: StringName) -> Array[StringName]:
	var none: Array[StringName] = []
	if _parents.has(id):
		return _parents[id] as Array[StringName]
	return none


## Revelado = comprado, inicial, ou filho de um nó comprado (GDD §6.1).
func is_revealed(id: StringName) -> bool:
	var d := get_node_data(id)
	if d == null:
		return false
	if d.starts_owned or is_owned(id):
		return true
	if d.reveal_trigger != &"" and not bool(trigger_state.get(d.reveal_trigger, false)):
		return false
	if not d.requires.is_empty() or not d.requires_any.is_empty():
		for req: Dictionary in d.requires:
			var req_id := StringName(str(req.get("id", "")))
			if level_of(req_id) < int(req.get("level", 1)):
				return false
		if not d.requires_any.is_empty():
			var has_any := false
			for req_id: StringName in d.requires_any:
				if is_owned(req_id):
					has_any = true
					break
			if not has_any:
				return false
		return true
	for p: StringName in parents_of(id):
		if is_owned(p):
			return true
	return false


## "?" escurecido: ainda oculto, mas filho de um nó já revelado.
func is_hinted(id: StringName) -> bool:
	if is_revealed(id):
		return false
	for p: StringName in parents_of(id):
		if is_revealed(p):
			return true
	return false


func next_cost(id: StringName) -> float:
	var d := get_node_data(id)
	if d == null or is_maxed(id):
		return INF
	if d.kind == &"M":
		# GDD §6.2: 1.500 × 3^(Raízes-mestras já compradas).
		return ceilf(d.base_cost * pow(d.cost_growth, masters_bought()))
	return d.cost_at(level_of(id))


func can_buy(id: StringName, wallet: Dictionary) -> bool:
	if not is_revealed(id) or is_maxed(id) or is_sealed(id):
		return false
	var d := get_node_data(id)
	return float(wallet.get(d.currency, 0.0)) >= next_cost(id)


## GDD §6.2: encruzilhada — comprar um lado sela o outro (Duas Raízes, N05, libera; marco D).
func is_sealed(id: StringName) -> bool:
	var d := get_node_data(id)
	if d == null or d.exclusive_group == &"" or is_owned(id) or has_flag(&"both_sides"):
		return false
	for other_id: StringName in order:
		var other := get_node_data(other_id)
		if other_id != id and other.exclusive_group == d.exclusive_group and is_owned(other_id):
			return true
	return false


## Nós que esta compra acabou de selar (para o som/efeito `seal`).
func sealed_by(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var d := get_node_data(id)
	if d == null or d.exclusive_group == &"":
		return out
	for other_id: StringName in order:
		if other_id != id and get_node_data(other_id).exclusive_group == d.exclusive_group and is_sealed(other_id):
			out.append(other_id)
	return out


## Raiz-mestra (D4): silhueta visível desde o início, com nome e custo no hover.
func is_master(id: StringName) -> bool:
	var d := get_node_data(id)
	return d != null and d.kind == &"M"


func masters_bought() -> int:
	var bought := 0
	for other_id: StringName in order:
		if is_master(other_id) and is_owned(other_id):
			bought += 1
	return bought


func set_trigger(trigger: StringName, enabled: bool = true) -> void:
	trigger_state[trigger] = enabled


## Sobe 1 nível. Retorna os ids recém-revelados.
func add_level(id: StringName) -> Array[StringName]:
	var before: Array[StringName] = []
	for other: StringName in order:
		if is_revealed(other):
			before.append(other)
	levels[id] = level_of(id) + 1
	var revealed: Array[StringName] = []
	for other: StringName in order:
		if is_revealed(other) and not before.has(other):
			revealed.append(other)
	return revealed


## Modificadores agregados da árvore. `override_id`/`override_level` permitem a prévia.
func collect_modifiers(override_id: StringName = &"", override_level: int = -1) -> Array[StatModifier]:
	var out: Array[StatModifier] = []
	for id: StringName in order:
		var lvl := override_level if id == override_id else level_of(id)
		if lvl <= 0:
			continue
		for m: StatModifier in (nodes[id] as SkillNodeData).modifiers_per_level:
			out.append(m.scaled(lvl))
	return out


func has_flag(flag: StringName) -> bool:
	for id: StringName in order:
		if is_owned(id):
			var d := nodes[id] as SkillNodeData
			if d.unlock_flags.has(flag) or d.flags.has(flag):
				return true
	return false


## GDD §15.4: nó revelado mais próximo de ser comprado.
## Retorna {} se não houver; senão {id, level, cost, currency, missing, affordable}.
func cheapest_pending(wallet: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for id: StringName in order:
		if not is_revealed(id) or is_maxed(id) or is_sealed(id):
			continue
		var d := get_node_data(id)
		var cost := next_cost(id)
		var missing := maxf(0.0, cost - float(wallet.get(d.currency, 0.0)))
		var candidate := {
			"id": id, "level": level_of(id) + 1, "cost": cost, "currency": d.currency,
			"missing": missing, "affordable": missing <= 0.0,
		}
		if best.is_empty() or _better(candidate, best):
			best = candidate
	return best


func _better(a: Dictionary, b: Dictionary) -> bool:
	# Compráveis primeiro (o mais barato); senão o que falta menos.
	if bool(a.affordable) != bool(b.affordable):
		return bool(a.affordable)
	if bool(a.affordable):
		return float(a.cost) < float(b.cost)
	return float(a.missing) < float(b.missing)


## GDD §18.5: níveis por id + `masters_bought` (ignorado na leitura: não é id de nó).
func to_save() -> Dictionary:
	var out: Dictionary = {}
	for id: StringName in order:
		if level_of(id) > 0:
			out[String(id)] = level_of(id)
	out["masters_bought"] = masters_bought()
	return out


func load_save(data: Dictionary) -> void:
	reset()
	for key: Variant in data:
		var id := StringName(str(key))
		if nodes.has(id):
			levels[id] = clampi(int(data[key]), 0, (nodes[id] as SkillNodeData).max_level)
