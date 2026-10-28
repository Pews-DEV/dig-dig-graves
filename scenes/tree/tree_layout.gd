class_name TreeLayout
extends RefCounted
## Grade e folgas da Árvore de Raízes (GDD §6.1, §15.5; UI/UX §7.3), puras e testáveis.
## Coordenadas relativas ao centro do medalhão 32×32. O mundo mede 1936×1024 (TreeArt.WORLD).
##
## Cada nó ocupa uma "caixa" que inclui o "!" de novidade em cima e os pips + o custo
## embaixo; caixas não se tocam e as raízes não atravessam caixa nenhuma (nem a do pai).

## Passo da grade (posições dos .tres em data/skill_nodes/): colunas 320 ± 88k, linhas de 64.
const COLUMN := 88.0
const ROW := 64.0
const HALF := 16.0
## Pips: topo 1 px abaixo do medalhão (MANIFEST tree_pips).
const PIPS_TOP := 17.0
const PIPS_HEIGHT := 4.0
## Linha de base do custo (m5x7) sem pips; com pips desce PIPS_SHIFT.
const LABEL_BASELINE := 26.0
const PIPS_SHIFT := 5.0
## Descida da m5x7 abaixo da linha de base + contorno 01.
const LABEL_DESCENT := 4.0
## Custo mais largo previsto ("12.345 os" ≈ 9 × 6 px) e topo do "!" (MANIFEST fx_tree_new_badge).
const LABEL_MAX_W := 56.0
const BADGE_TOP := -22.0
## Raiz para filho na diagonal sai pela lateral do medalhão (fica longe do custo do pai);
## para filho logo abaixo, sai por baixo do custo.
const SIDE_EXIT := Vector2(15, 6)
const VERTICAL_DX := 24.0
## Câmera inicial: N00 a 128 px do topo da tela (mostra a copa, o N00 e duas linhas inteiras).
const START_CAM_OFFSET := 240.0
## Plaquetas de cima (carteira e "Cavar"): base em y = 6 + 24.
const TOP_HUD_BOTTOM := 30.0
const SIDE_MARGIN := 6.0
## Topo do painel de descrição da Árvore (360 − 6 − 58).
const PANEL_Y := 296


static func label_baseline(with_pips: bool) -> float:
	return LABEL_BASELINE + (PIPS_SHIFT if with_pips else 0.0)


## Onde terminam os enfeites embaixo do medalhão (custo, pips ou a própria moldura).
static func decor_bottom(has_label: bool, has_pips: bool) -> float:
	if has_label:
		return label_baseline(has_pips) + LABEL_DESCENT
	if has_pips:
		return PIPS_TOP + PIPS_HEIGHT
	return HALF - 1.0


## Caixa máxima de um nó (medalhão + "!" + pips + custo), em coordenadas do mundo.
static func node_rect(center: Vector2) -> Rect2:
	var top := BADGE_TOP - 1.0
	var bottom := decor_bottom(true, true)
	return Rect2(center.x - LABEL_MAX_W * 0.5, center.y + top, LABEL_MAX_W, bottom - top)


## Caixa do custo/pips embaixo do medalhão.
static func label_rect(center: Vector2) -> Rect2:
	var bottom := decor_bottom(true, true)
	return Rect2(center.x - LABEL_MAX_W * 0.5, center.y + PIPS_TOP, LABEL_MAX_W, bottom - PIPS_TOP)


static func medallion_rect(center: Vector2) -> Rect2:
	return Rect2(center - Vector2(HALF, HALF), Vector2(HALF, HALF) * 2.0)


## Ponto de saída da raiz do pai até o filho.
static func root_start(parent: Vector2, child: Vector2, parent_decor_bottom: float) -> Vector2:
	var dx := child.x - parent.x
	if absf(dx) < VERTICAL_DX:
		return parent + Vector2(0, parent_decor_bottom + 1.0)
	return parent + Vector2(signf(dx) * SIDE_EXIT.x, SIDE_EXIT.y)


## Enfeites de um nó revelado no estado atual do modelo (o mesmo que o medalhão desenha).
static func decor_bottom_for(tree: SkillTreeModel, id: StringName) -> float:
	var d := tree.get_node_data(id)
	if d == null:
		return HALF - 1.0
	var maxed := tree.is_maxed(id)
	var has_label := not maxed and d.base_cost > 0.0
	var has_pips := tree.level_of(id) > 0 and not maxed and d.max_level > 1
	return decor_bottom(has_label, has_pips)


static func start_camera_y(n00_y: float) -> float:
	return n00_y - START_CAM_OFFSET


## Faixa da tela onde o centro do nó em foco deve ficar para a caixa inteira aparecer
## entre as plaquetas de cima e o painel de baixo (que começa em `panel_y`).
static func safe_rect(panel_y: float) -> Rect2:
	var top := TOP_HUD_BOTTOM - (BADGE_TOP - 1.0) + 1.0
	var bottom := panel_y - decor_bottom(true, true) - 2.0
	var left := SIDE_MARGIN + LABEL_MAX_W * 0.5
	return Rect2(left, top, 640.0 - 2.0 * left, bottom - top)


## Bezier quadrática: sai do pai quase na horizontal e desce até o filho (pixels inteiros).
## Retorna [Array[Vector2i] pontos, Array[bool] trecho íngreme].
static func root_path(a: Vector2, b: Vector2, obstacles: Array[Rect2] = []) -> Array:
	var base_ctrl := Vector2(lerpf(a.x, b.x, 0.85), a.y + (b.y - a.y) * 0.2)
	if absf(a.x - b.x) < 2.0:
		base_ctrl = (a + b) * 0.5
	var controls: Array[Vector2] = [base_ctrl]
	for offset_x: float in [-32.0, 32.0, -64.0, 64.0, -128.0, 128.0, -192.0, 192.0, -256.0, 256.0, -384.0, 384.0]:
		controls.append(base_ctrl + Vector2(offset_x, 0))
	for offset_y: float in [-48.0, 48.0, -96.0, 96.0, -160.0, 160.0]:
		controls.append(base_ctrl + Vector2(0, offset_y))
	for offset: Vector2 in [Vector2(-96, 48), Vector2(96, 48), Vector2(-96, -48), Vector2(96, -48)]:
		controls.append(base_ctrl + offset)
	var best: Array = []
	var best_length := INF
	for ctrl: Vector2 in controls:
		var candidate := _root_path_with_control(a, b, ctrl)
		var pts: Array = candidate[0]
		var clear := true
		for q: Vector2i in pts:
			for obstacle: Rect2 in obstacles:
				if obstacle.has_point(Vector2(q)):
					clear = false
					break
			if not clear:
				break
		var path_length := float(pts.size())
		if clear and path_length < best_length:
			best = candidate
			best_length = path_length
	if not best.is_empty():
		return best
	if not obstacles.is_empty():
		var routed := _route_root_grid(a, b, obstacles)
		if not routed.is_empty():
			return routed
	return _root_path_with_control(a, b, base_ctrl)


static func _root_path_with_control(a: Vector2, b: Vector2, ctrl: Vector2) -> Array:
	var length := a.distance_to(b) * 1.3 + 4.0
	var steps := maxi(1, int(length * 2.0))
	var pts: Array[Vector2i] = []
	var steep: Array[bool] = []
	for i: int in steps + 1:
		var t := float(i) / steps
		var p := a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)
		var q := Vector2i(p.round())
		if pts.is_empty() or pts[pts.size() - 1] != q:
			var tangent := (ctrl - a).lerp(b - ctrl, t)
			pts.append(q)
			steep.append(absf(tangent.y) > absf(tangent.x))
	return [pts, steep]


static func _route_root_grid(a: Vector2, b: Vector2, obstacles: Array[Rect2]) -> Array:
	const STEP := 8
	const WIDTH := 244
	const HEIGHT := 132
	var start := Vector2i(roundi(a.x / STEP), roundi(a.y / STEP))
	var goal := Vector2i(roundi(b.x / STEP), roundi(b.y / STEP))
	var queue: Array[int] = [start.y * WIDTH + start.x]
	var parent: Dictionary = {queue[0]: -1}
	var cursor := 0
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	var goal_id := goal.y * WIDTH + goal.x
	while cursor < queue.size() and not parent.has(goal_id):
		var current_id := queue[cursor]
		cursor += 1
		var current := Vector2i(current_id % WIDTH, int(current_id / WIDTH))
		for direction: Vector2i in directions:
			var next := current + direction
			if next.x < 0 or next.x >= WIDTH or next.y < 0 or next.y >= HEIGHT:
				continue
			var next_id := next.y * WIDTH + next.x
			if parent.has(next_id):
				continue
			var point := Vector2(next * STEP)
			var blocked := false
			for obstacle: Rect2 in obstacles:
				if obstacle.grow(2.0).has_point(point):
					blocked = true
					break
			if blocked:
				continue
			parent[next_id] = current_id
			queue.append(next_id)
	if not parent.has(goal_id):
		return []
	var grid_path: Array[Vector2i] = []
	var node_id := goal_id
	while node_id >= 0:
		grid_path.push_front(Vector2i(node_id % WIDTH, int(node_id / WIDTH)))
		node_id = int(parent[node_id])
	var points: Array[Vector2i] = [Vector2i(a.round())]
	var prior := a
	for cell: Vector2i in grid_path:
		var next_point := Vector2(cell * STEP)
		var count := maxi(1, int(ceil(prior.distance_to(next_point))))
		for i: int in count:
			var q := Vector2i(prior.lerp(next_point, float(i + 1) / count).round())
			if points[points.size() - 1] != q:
				points.append(q)
		prior = next_point
	var end_count := maxi(1, int(ceil(prior.distance_to(b))))
	for i: int in end_count:
		var q := Vector2i(prior.lerp(b, float(i + 1) / end_count).round())
		if points[points.size() - 1] != q:
			points.append(q)
	var steep: Array[bool] = []
	for i: int in points.size():
		var tangent := Vector2(points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)])
		steep.append(absf(tangent.y) > absf(tangent.x))
	return [points, steep]
