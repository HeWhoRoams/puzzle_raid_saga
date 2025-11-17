
import { DifficultySettings } from '../types';

export const DIFFICULTY_SETTINGS: DifficultySettings = {
  'Easy': {
    name: 'Easy',
    statMultiplier: 0.75,
    specialEnemySpawnModifier: 0.5,
  },
  'Normal': {
    name: 'Normal',
    statMultiplier: 1.0,
    specialEnemySpawnModifier: 1.0,
  },
  'Hard': {
    name: 'Hard',
    statMultiplier: 1.5,
    specialEnemySpawnModifier: 1.25,
  },
  'Insane': {
    name: 'Insane',
    statMultiplier: 2.0,
    specialEnemySpawnModifier: 1.75,
  },
};
