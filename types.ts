export enum TileType {
  SWORD = 'SWORD',
  SKULL = 'SKULL',
  SHIELD = 'SHIELD',
  POTION = 'POTION',
  COIN = 'COIN',
}

export type EnemyTrait = 'POISON' | 'ARMOR_PIERCING' | 'HEAL_ALLIES' | 'SPAWN_SKULLS';

export interface EnemyDefinition {
  id: string;
  name: string;
  baseHp: number;
  baseAttack: number;
  baseArmor?: number;
  traits: EnemyTrait[];
  rarity: number;
  minDepth: number;
  maxDepth: number;
  xpReward: number;
  goldReward: number;
}

export interface TileData {
  id: string;
  type: TileType;
  hp?: number;
  maxHp?: number;
  attack?: number;
  armor?: number;
  enemyId?: string;
  name?: string;
  traits?: EnemyTrait[];
  isNew?: boolean; // Flag for new tile animation
}

export type Board = (TileData | null)[][];

export interface Position {
  row: number;
  col: number;
}

export interface PlayerBuff {
  id: string;
  durationTurns: number;
}

export interface PlayerAbility {
  id: string;
  currentLevel: number;
  currentCooldown: number;
}

// --- NEW ITEM & EQUIPMENT SCHEMAS ---

export type EquipmentSlot = 'weapon' | 'armor' | 'accessory1' | 'accessory2';

export interface ItemStatModifiers {
  maxHp?: number;
  maxArmor?: number;
  attack?: number;
  coinMultiplier?: number; // e.g., 1.1 for +10%
  xpGainMultiplier?: number; // e.g., 1.1 for +10%
}

export interface ItemUpgradeDefinition {
  cost: number;
  modifiers: ItemStatModifiers;
}

export interface ItemDefinition {
  id: string;
  name: string;
  description: string;
  icon: string;
  slot: EquipmentSlot;
  rarity: number; // For generation logic
  upgradePath: ItemUpgradeDefinition[];
}

export interface PlayerItem {
  itemId: string;
  currentUpgradeLevel: number;
}

export type PlayerEquipment = Record<EquipmentSlot, PlayerItem | null>;

// --- END NEW ITEM SCHEMAS ---


export interface PlayerStats {
  hp: number;
  maxHp: number;
  armor: number;
  maxArmor: number;
  attack: number;
  gold: number;
  xp: number;
  level: number;
  classId: string;
  abilities: PlayerAbility[];
  poisonStacks: number;
  buffs: PlayerBuff[];
  equipment: PlayerEquipment; // New
}

export interface TileDefinition {
  type: TileType;
  weight: number;
}

export interface ChainBonus {
  length: number;
  multiplier: number;
}

export interface LevelProgression {
  baseXp: number;
  xpMultiplier: number;
  statGains: {
    maxHp: number;
    maxArmor: number;
    attack: number;
  };
}

export interface DifficultyLevel {
  name: string;
  statMultiplier: number;
  specialEnemySpawnModifier: number;
}

export interface DifficultySettings {
  [key: string]: DifficultyLevel;
}

export type AbilityEffect =
  | { type: 'HEAL'; amount: number }
  | { type: 'DAMAGE_ALL_SKULLS'; amount: number }
  | { type: 'APPLY_BUFF'; buffId: string; duration: number }
  | { type: 'CONVERT_TILES'; from: TileType; to: TileType }
  | { type: 'SHIELD_EXPLOSION'; baseAmount: number };

export interface AbilityDefinition {
  id: string;
  name: string;
  description: string;
  icon: string;
  baseCooldown: number;
  cooldownReductionPerLevel: number;
  maxLevel: number;
  effect: AbilityEffect;
}

export interface ClassAbilityUnlock {
  level: number;
  abilityId: string;
}

export interface ClassStatGrowth {
  maxHp: number;
  maxArmor: number;
  attack: number;
}

export interface ClassDefinition {
  id: string;
  name: string;
  description: string;
  icon: string;
  baseStatModifiers: {
    maxHp: number;
    maxArmor: number;
    attack: number;
  };
  statGrowth: ClassStatGrowth;
  startingAbilityIds: string[];
  unlocks: ClassAbilityUnlock[];
}

export interface ClassProgress {
  xp: number;
  level: number;
}

export interface AccountProgression {
  classData: {
    [classId: string]: ClassProgress;
  };
  globallyUnlockedAbilityIds: string[];
  globallyUnlockedItemIds: string[]; // New
}


export interface GameConfig {
  boardSize: number;
  minPathLength: number;
  tileTypes: TileDefinition[];
  chainBonuses: ChainBonus[];
  levelProgression: LevelProgression;
  enemies: EnemyDefinition[];
  enemyTraits: EnemyTrait[];
  difficulty: DifficultySettings;
  abilities: AbilityDefinition[];
  classes: ClassDefinition[];
  items: ItemDefinition[]; // New
}

// New: For the item offer screen
export type ItemOffer =
  | { type: 'newItem'; itemDef: ItemDefinition }
  | { type: 'upgrade'; item: PlayerItem; itemDef: ItemDefinition; upgradeDef: ItemUpgradeDefinition; nextLevel: number };

// New: For the path preview
export interface PathPreviewData {
    type: TileType;
    count: number;
    value: number;
    multiplier: number;
}

// --- New: For persistence ---
export interface SavedRunState {
  board: Board;
  playerStats: PlayerStats;
  depth: number;
  gameLog: string[];
}

export interface RunHistoryEntry {
  id: number;
  date: string;
  score: number;
  className: string;
  finalLevel: number;
  finalDepth: number;
}