import { PlayerStats } from './types';

export const BASE_PLAYER_STATS: PlayerStats = {
  hp: 100,
  maxHp: 100,
  armor: 10,
  maxArmor: 10,
  attack: 5,
  gold: 0,
  xp: 0,
  level: 1,
  classId: '',
  abilities: [],
  poisonStacks: 0,
  buffs: [],
  equipment: { 
    weapon: null,
    armor: null,
    accessory1: null,
    accessory2: null,
  },
};
