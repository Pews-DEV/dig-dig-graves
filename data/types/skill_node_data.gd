class_name SkillNodeData
extends Resource
## Nó da Árvore de Raízes (GDD §6). Um .tres por nó em data/skill_nodes/.

enum Branch { CENTER, DIG, LANTERN, FORTUNE, CEMETERY, HELPERS, SOULS, LUNAR }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var branch: Branch = Branch.CENTER
@export var max_level: int = 1
## GDD §6.2: custo(nível) = base × crescimento^nível, arredondado para cima.
@export var base_cost: float = 0.0
@export var cost_growth: float = 1.0
@export var currency: StringName = &"copper"
## Efeito de 1 nível; o total é escalado pelo nível comprado.
@export var modifiers_per_level: Array[StatModifier] = []
## Flags de desbloqueio (ex.: &"epitaphs" para N01).
@export var unlock_flags: Array[StringName] = []
## Nós revelados quando este é comprado (topologia da árvore).
@export var children: Array[StringName] = []
## Posição do centro do medalhão na tela da árvore (px, viewport 640×360).
@export var tree_position: Vector2 = Vector2.ZERO
## Célula 16×16 do ícone em assets/ui/tree/node_icons.png (MANIFEST tree_node_icons).
## (−1, −1) = sem ícone (desenha o id como placeholder).
@export var icon_cell: Vector2i = Vector2i(-1, -1)
@export var starts_owned: bool = false
## GDD §6.4: área mínima para o nó aparecer.
@export var required_area: int = 1


func cost_at(level: int) -> float:
	if base_cost <= 0.0:
		return 0.0
	return ceilf(base_cost * pow(cost_growth, level) - 0.000001)
