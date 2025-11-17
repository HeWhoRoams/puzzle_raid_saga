import { GameConfig, AbilityDefinition, ClassDefinition, EnemyDefinition, ItemDefinition, DifficultySettings, EnemyTrait } from '../types';

// A type guard to check if an object is an EnemyTrait
function isEnemyTrait(trait: string, validTraits: Set<string>): trait is EnemyTrait {
    return validTraits.has(trait);
}

class ValidationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'ValidationError';
    }
}

async function validateContent(
    abilities: AbilityDefinition[],
    classes: ClassDefinition[],
    enemiesData: { validTraits: string[], definitions: EnemyDefinition[] },
    items: ItemDefinition[],
    difficulties: DifficultySettings
): Promise<void> {

    const abilityIds = new Set(abilities.map(a => a.id));
    const validTraits = new Set(enemiesData.validTraits);

    // Validate Classes
    for (const cls of classes) {
        for (const abilityId of cls.startingAbilityIds) {
            if (!abilityIds.has(abilityId)) {
                throw new ValidationError(`Class '${cls.name}' references non-existent starting ability '${abilityId}'.`);
            }
        }
        for (const unlock of cls.unlocks) {
            if (!abilityIds.has(unlock.abilityId)) {
                throw new ValidationError(`Class '${cls.name}' references non-existent unlock ability '${unlock.abilityId}' at level ${unlock.level}.`);
            }
        }
    }

    // Validate Enemies
    for (const enemy of enemiesData.definitions) {
        for (const trait of enemy.traits) {
            if (!isEnemyTrait(trait, validTraits)) {
                throw new ValidationError(`Enemy '${enemy.name}' has an invalid trait '${trait}'. Valid traits are: [${[...validTraits].join(', ')}].`);
            }
        }
    }
    
    // Validate Difficulties
    if (!difficulties['Normal']) {
        throw new ValidationError("The 'Normal' difficulty preset is missing in difficulties.json.");
    }

    // Items validation can be added here if they reference other content, e.g., abilities.
}


async function fetchContent<T>(path: string): Promise<T> {
    const response = await fetch(path);
    if (!response.ok) {
        throw new Error(`Failed to fetch ${path}: ${response.statusText}`);
    }
    return response.json();
}

export const loadAndValidateGameConfig = async (): Promise<GameConfig> => {
    // Fetch all content JSON files concurrently.
    const [
        settings,
        abilitiesList,
        classesList,
        enemiesModule,
        itemsList,
        difficultiesSettings
    ] = await Promise.all([
        fetchContent<any>('/content/game_settings.json'),
        fetchContent<AbilityDefinition[]>('/content/abilities.json'),
        fetchContent<ClassDefinition[]>('/content/classes.json'),
        fetchContent<{ validTraits: string[], definitions: EnemyDefinition[] }>('/content/enemies.json'),
        fetchContent<ItemDefinition[]>('/content/items.json'),
        fetchContent<DifficultySettings>('/content/difficulties.json')
    ]);

    // Run all validation checks
    await validateContent(abilitiesList, classesList, enemiesModule, itemsList, difficultiesSettings);

    // Assemble the final config object
    const gameConfig: GameConfig = {
        boardSize: settings.boardSize,
        minPathLength: settings.minPathLength,
        tileTypes: settings.tileTypes,
        chainBonuses: settings.chainBonuses,
        levelProgression: settings.levelProgression,
        abilities: abilitiesList,
        classes: classesList,
        enemies: enemiesModule.definitions,
        enemyTraits: enemiesModule.validTraits as EnemyTrait[],
        items: itemsList,
        difficulty: difficultiesSettings,
    };
    
    return gameConfig;
};
