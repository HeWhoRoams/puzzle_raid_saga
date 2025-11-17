// FIX: `BASE_PLAYER_STATS` is exported from `constants.ts`, not `types.ts`.
import { AccountProgression, GameConfig, PlayerStats, ClassDefinition } from '../types';
import { BASE_PLAYER_STATS } from '../constants';

const PROGRESSION_KEY = 'puzzleRaidSagaProgression';

const CLASS_XP_CURVE = {
    base: 200,
    multiplier: 1.6
};

/**
 * Calculates a class's level based on its total accumulated XP.
 */
export const getClassLevel = (xp: number): { level: number; xpForNext: number; currentLevelXp: number } => {
    let level = 1;
    let requiredXp = CLASS_XP_CURVE.base;
    let totalXpForLevel = 0;
    
    while (xp >= requiredXp) {
        xp -= requiredXp;
        level++;
        totalXpForLevel = requiredXp;
        requiredXp = Math.floor(requiredXp * CLASS_XP_CURVE.multiplier);
    }
    
    return { level, xpForNext: requiredXp, currentLevelXp: totalXpForLevel };
};

/**
 * Loads the player's progression from localStorage.
 * If no data is found, it initializes a default progression state.
 */
export const loadProgression = (): AccountProgression => {
    try {
        const savedData = localStorage.getItem(PROGRESSION_KEY);
        if (savedData) {
            const parsed = JSON.parse(savedData);
            // Ensure new properties exist for players with old save data
            if (!parsed.globallyUnlockedItemIds) {
                parsed.globallyUnlockedItemIds = ['short_sword', 'leather_armor'];
            }
            return parsed;
        }
    } catch (error) {
        console.error("Failed to load progression:", error);
    }

    // Default initial state
    return {
        classData: {},
        globallyUnlockedAbilityIds: ['minor_heal', 'skull_crusher', 'gold_rush'],
        globallyUnlockedItemIds: ['short_sword', 'leather_armor'], // Start with basic items
    };
};

/**
 * Saves the player's progression to localStorage.
 */
export const saveProgression = (progression: AccountProgression): void => {
    try {
        localStorage.setItem(PROGRESSION_KEY, JSON.stringify(progression));
    } catch (error) {
        console.error("Failed to save progression:", error);
    }
};

/**
 * Initializes a PlayerStats object for the start of a new run based on the chosen class.
 */
export const initializePlayerForClass = (classId: string, config: GameConfig): PlayerStats => {
    const classDef = config.classes.find(c => c.id === classId);
    if (!classDef) {
        throw new Error(`Class with id ${classId} not found.`);
    }

    const newPlayerStats: PlayerStats = {
        ...BASE_PLAYER_STATS,
        equipment: { weapon: null, armor: null, accessory1: null, accessory2: null }, // Ensure equipment is reset
        classId,
        maxHp: BASE_PLAYER_STATS.maxHp + classDef.baseStatModifiers.maxHp,
        hp: BASE_PLAYER_STATS.maxHp + classDef.baseStatModifiers.maxHp,
        maxArmor: BASE_PLAYER_STATS.maxArmor + classDef.baseStatModifiers.maxArmor,
        armor: BASE_PLAYER_STATS.maxArmor + classDef.baseStatModifiers.maxArmor,
        attack: BASE_PLAYER_STATS.attack + classDef.baseStatModifiers.attack,
        abilities: classDef.startingAbilityIds.map(id => ({
            id,
            currentLevel: 1,
            currentCooldown: 0,
        })),
    };

    return newPlayerStats;
};


/**
 * Processes the end of a run, calculating XP, checking for unlocks, and saving progression.
 */
export const processEndOfRun = (
    progression: AccountProgression,
    playerStats: PlayerStats,
    config: GameConfig
) => {
    const classId = playerStats.classId;
    const classDef = config.classes.find(c => c.id === classId);
    if (!classDef) return { updatedProgression: progression, xpGained: 0, newUnlocks: [] };
    
    // XP is now based on gold earned, not depth.
    const xpGained = Math.floor(playerStats.gold / 2) + playerStats.xp; // Includes XP from kills
    const updatedProgression = JSON.parse(JSON.stringify(progression));

    if (!updatedProgression.classData[classId]) {
        updatedProgression.classData[classId] = { xp: 0, level: 1 };
    }

    const classProgress = updatedProgression.classData[classId];
    const oldLevel = classProgress.level;
    
    classProgress.xp += xpGained;
    const { level: newLevel } = getClassLevel(classProgress.xp);
    classProgress.level = newLevel;

    const newUnlocks: string[] = [];
    if (newLevel > oldLevel) {
        classDef.unlocks.forEach(unlock => {
            if (unlock.level > oldLevel && unlock.level <= newLevel) {
                if (!updatedProgression.globallyUnlockedAbilityIds.includes(unlock.abilityId)) {
                    updatedProgression.globallyUnlockedAbilityIds.push(unlock.abilityId);
                    newUnlocks.push(unlock.abilityId);
                }
            }
        });
    }

    saveProgression(updatedProgression);
    
    return { updatedProgression, xpGained, newUnlocks };
};