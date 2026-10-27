extends Node
## Barramento de sinais global (GDD §18.2). Só declarações; nenhuma lógica.
## Sistemas emitem e escutam aqui em vez de usar get_node atravessando cenas.
## Os sinais são emitidos por outros scripts, então o aviso UNUSED_SIGNAL não se aplica aqui.
@warning_ignore_start("unused_signal")

# Economia / progressão
signal currency_changed(currency: StringName, amount: float)
signal stats_changed()
signal skill_node_bought(id: StringName, level: int)
signal skill_node_revealed(id: StringName)
signal game_saved()
signal settings_changed()

# Turno
signal turn_started()
signal pulse_resolved(report: Dictionary)
signal layer_broken(cell: Vector2i, layer: LayerData, bone: bool, xp: float, crit: bool)
signal tile_regenerated(cell: Vector2i)
signal field_cleared(bonus_copper: float)
signal run_xp_changed(xp: float, needed: float, level: int)
## GDD §4.9: Epitáfios entram aqui (fila de escolha) quando N01 existir.
signal run_level_up(level: int)
signal grave_opened(grave: Dictionary, rewards: Dictionary)
signal unrest_changed(value: float)
## GDD §10: chefe da área aparece (M1).
signal unrest_filled(area_id: int)
signal wisp_collected(oil: float)
signal turn_ended(result: TurnResult)
