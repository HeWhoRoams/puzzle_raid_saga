extends Resource
class_name GameConfigResource

@export var board_size := 6
@export var min_path_length := 3

@export var tile_types: Array[TileDefinitionResource] = []
@export var chain_bonuses: Array[ChainBonusResource] = []
@export var level_progression: LevelProgressionResource

@export var abilities: Array[AbilityDefinitionResource] = []
@export var classes: Array[ClassDefinitionResource] = []
@export var enemies: Array[EnemyDefinitionResource] = []
@export var items: Array[ItemDefinitionResource] = []
@export var difficulties: Array[DifficultyDefinitionResource] = []
@export var default_difficulty: StringName = &"Normal"
