extends BaseDefinitionResource
class_name ClassDefinitionResource

@export var icon_path := ""
@export var base_stat_modifiers := {
	"max_hp": 0,
	"max_armor": 0,
	"attack": 0,
}
@export var stat_growth := {
	"max_hp": 0,
	"max_armor": 0,
	"attack": 0,
}
@export var starting_ability_ids: Array[StringName] = []
@export var unlocks: Array = []
