import { Board, GameConfig, TileData, TileType, Position, PlayerStats, EnemyDefinition, DifficultyLevel, PlayerAbility, AbilityDefinition, ClassDefinition, PathPreviewData } from '../types';

/**
 * Selects an enemy type to spawn based on current depth and difficulty.
 */
export const selectEnemyForSpawn = (depth: number, config: GameConfig, difficulty: DifficultyLevel): EnemyDefinition | null => {
  const eligibleEnemies = config.enemies.filter(e => depth >= e.minDepth && depth <= e.maxDepth);
  if (eligibleEnemies.length === 0) return null;

  const totalWeight = eligibleEnemies.reduce((sum, enemy) => {
    const isBasic = enemy.minDepth === 0;
    const modifier = isBasic ? 1.0 : difficulty.specialEnemySpawnModifier;
    return sum + (enemy.rarity * modifier);
  }, 0);

  let randomWeight = Math.random() * totalWeight;

  for (const enemy of eligibleEnemies) {
    const isBasic = enemy.minDepth === 0;
    const modifier = isBasic ? 1.0 : difficulty.specialEnemySpawnModifier;
    const effectiveRarity = enemy.rarity * modifier;
    
    if (randomWeight < effectiveRarity) {
      return enemy;
    }
    randomWeight -= effectiveRarity;
  }
  
  return eligibleEnemies[0];
};

export const createSkullTile = (enemyDef: EnemyDefinition, difficulty: DifficultyLevel): TileData => {
  const statMultiplier = difficulty.statMultiplier;
  const hp = Math.ceil(enemyDef.baseHp * statMultiplier);
  const attack = Math.ceil(enemyDef.baseAttack * statMultiplier);
  return {
    id: crypto.randomUUID(),
    type: TileType.SKULL,
    enemyId: enemyDef.id,
    name: enemyDef.name,
    hp: hp,
    maxHp: hp,
    attack: attack,
    armor: enemyDef.baseArmor ?? 0,
    traits: [...enemyDef.traits],
    isNew: true,
  };
};

export const createNewTile = (depth: number, config: GameConfig, difficulty: DifficultyLevel): TileData => {
  const totalWeight = config.tileTypes.reduce((sum, tile) => sum + tile.weight, 0);
  let randomWeight = Math.random() * totalWeight;

  for (const tileDef of config.tileTypes) {
    if (randomWeight < tileDef.weight) {
      if (tileDef.type === TileType.SKULL) {
        const enemyDef = selectEnemyForSpawn(depth, config, difficulty);
        if (enemyDef) {
          return createSkullTile(enemyDef, difficulty);
        }
      } else {
        return { id: crypto.randomUUID(), type: tileDef.type, isNew: true };
      }
    }
    randomWeight -= tileDef.weight;
  }
  const nonSkullTypes = config.tileTypes.filter(t => t.type !== TileType.SKULL);
  const fallbackType = nonSkullTypes[Math.floor(Math.random() * nonSkullTypes.length)].type;
  return { id: crypto.randomUUID(), type: fallbackType, isNew: true };
};

export const initializeBoard = (depth: number, config: GameConfig, difficulty: DifficultyLevel): Board => {
  const { boardSize } = config;
  const newBoard: Board = [];
  for (let row = 0; row < boardSize; row++) {
    newBoard[row] = [];
    for (let col = 0; col < boardSize; col++) {
      newBoard[row][col] = createNewTile(depth, config, difficulty);
    }
  }
  return newBoard;
};

export const isAdjacent = (pos1: Position, pos2: Position): boolean => {
  const rowDiff = Math.abs(pos1.row - pos2.row);
  const colDiff = Math.abs(pos1.col - pos2.col);
  return rowDiff <= 1 && colDiff <= 1 && (rowDiff + colDiff > 0);
};

export const getXpForLevel = (level: number, config: GameConfig): number => {
    const { baseXp, xpMultiplier } = config.levelProgression;
    return Math.floor(baseXp * Math.pow(xpMultiplier, level - 1));
};

export const resolvePlayerAction = (board: Board, baseStats: PlayerStats, effectiveStats: PlayerStats, selectedPath: Position[], config: GameConfig) => {
    const newBoard = JSON.parse(JSON.stringify(board)) as Board;
    let newPlayerStats = { ...baseStats }; // Operate on the base stats
    const logs: string[] = [];
    const defeatedEnemies: EnemyDefinition[] = [];

    const pathType = newBoard[selectedPath[0].row][selectedPath[0].col]?.type;
    if (!pathType) return { newBoard, newPlayerStats, logs, defeatedEnemies };

    const chainLength = selectedPath.length;
    const bonusItem = config.chainBonuses.slice().reverse().find(b => chainLength >= b.length);
    let bonus = bonusItem ? bonusItem.multiplier : 1.0;
    
    switch (pathType) {
        case TileType.SWORD:
        case TileType.SKULL:
            let attackMultiplier = 1.0;
            if (effectiveStats.buffs.some(b => b.id === 'double_attack')) {
                attackMultiplier = 2.0;
                logs.push(`<span class="text-yellow-300 font-bold">BERSERK! Attack is doubled!</span>`);
                newPlayerStats.buffs = newPlayerStats.buffs.filter(b => b.id !== 'double_attack');
            }
            const totalDamage = Math.floor(effectiveStats.attack * chainLength * bonus * attackMultiplier);
            logs.push(`You attack for <span class="text-red-400">${totalDamage}</span> total damage.`);
            selectedPath.forEach(pos => {
                const tile = newBoard[pos.row][pos.col];
                if (tile && tile.type === TileType.SKULL && tile.hp && tile.hp > 0) {
                    tile.hp -= totalDamage;
                    if (tile.hp <= 0) {
                        const enemyDef = config.enemies.find(e => e.id === tile.enemyId);
                        if (enemyDef) defeatedEnemies.push(enemyDef);
                    } else {
                        logs.push(`${tile.name} takes <span class="text-red-400">${totalDamage}</span> damage.`);
                    }
                }
            });
            break;
        case TileType.SHIELD:
            const armorGain = Math.floor(5 * chainLength * bonus);
            newPlayerStats.armor = Math.min(effectiveStats.maxArmor, newPlayerStats.armor + armorGain);
            logs.push(`You repaired <span class="text-blue-400">${armorGain}</span> armor.`);
            break;
        case TileType.POTION:
            const healAmount = Math.floor(10 * chainLength * bonus);
            newPlayerStats.hp = Math.min(effectiveStats.maxHp, newPlayerStats.hp + healAmount);
            logs.push(`You healed for <span class="text-green-400">${healAmount}</span> HP.`);
            break;
        case TileType.COIN:
             let goldMultiplier = (effectiveStats as any).coinMultiplier || 1.0;
            if (effectiveStats.buffs.some(b => b.id === 'double_gold')) {
                goldMultiplier *= 2.0;
                logs.push(`<span class="text-yellow-300 font-bold">GOLD RUSH! Coins are doubled!</span>`);
                newPlayerStats.buffs = newPlayerStats.buffs.filter(b => b.id !== 'double_gold');
            }
            const goldGained = Math.floor(chainLength * bonus * goldMultiplier);
            newPlayerStats.gold += goldGained;
            logs.push(`You collected <span class="text-yellow-400">${goldGained}</span> gold.`);
            break;
    }
    return { newBoard, newPlayerStats, logs, defeatedEnemies };
};

export const resolveEnemyPreAttacks = (board: Board) => {
    const newBoard = JSON.parse(JSON.stringify(board)) as Board;
    const logs: string[] = [];
    const healers: TileData[] = [];
    newBoard.flat().forEach(tile => {
        if (tile?.type === TileType.SKULL && tile.hp && tile.hp > 0 && tile.traits?.includes('HEAL_ALLIES')) {
            healers.push(tile);
        }
    });

    if (healers.length > 0) {
        let totalHealed = 0;
        const healAmount = 5;
        newBoard.flat().forEach(tile => {
            if (tile?.type === TileType.SKULL && tile.hp && tile.hp > 0) {
                const amountToHeal = Math.min(tile.maxHp! - tile.hp, healAmount * healers.length);
                if (amountToHeal > 0) {
                    tile.hp += amountToHeal;
                    totalHealed += amountToHeal;
                }
            }
        });
        if (totalHealed > 0) logs.push(`<span class="text-lime-400">Enemy shamans heal their allies!</span>`);
    }

    return { newBoard, logs };
}

export const resolveEnemyAttacks = (board: Board, baseStats: PlayerStats, effectiveStats: PlayerStats, selectedPath: Position[]) => {
    let newPlayerStats = { ...baseStats };
    const logs: string[] = [];
    let totalDamageTaken = 0;
    let totalArmorPiercingDamage = 0;

    for (let r = 0; r < board.length; r++) {
        for (let c = 0; c < board[r].length; c++) {
            const tile = board[r][c];
            if (tile?.type === TileType.SKULL && tile.hp && tile.hp > 0) {
                const isPartOfPath = selectedPath.some(p => p.row === r && p.col === c);
                if (!isPartOfPath) {
                    const enemyAttack = tile.attack || 0;
                    if (enemyAttack > 0) {
                        if (tile.traits?.includes('ARMOR_PIERCING')) {
                            totalArmorPiercingDamage += enemyAttack;
                        } else {
                            const damage = Math.max(1, enemyAttack - effectiveStats.armor);
                            totalDamageTaken += damage;
                        }
                        if (tile.traits?.includes('POISON')) {
                           newPlayerStats.poisonStacks += 1;
                        }
                    }
                }
            }
        }
    }
    
    if (totalArmorPiercingDamage > 0) {
        newPlayerStats.hp -= totalArmorPiercingDamage;
        logs.push(`Armor-piercing attacks deal <span class="text-fuchsia-500">${totalArmorPiercingDamage}</span> direct damage!`);
    }

    if (totalDamageTaken > 0) {
        const damageToArmor = Math.min(newPlayerStats.armor, totalDamageTaken);
        newPlayerStats.armor -= damageToArmor;
        
        const remainingDamage = totalDamageTaken - damageToArmor;
        if (remainingDamage > 0) {
            newPlayerStats.hp -= remainingDamage;
        }

        logs.push(`Enemies attack! You take <span class="text-orange-500">${remainingDamage}</span> damage and lose <span class="text-blue-300">${damageToArmor}</span> armor.`);
    }

    return { newPlayerStats, logs };
};

export const resolveLevelUps = (playerStats: PlayerStats, classDef: ClassDefinition, config: GameConfig) => {
    let newPlayerStats = { ...playerStats };
    const logs: string[] = [];
    let leveledUp = false;

    let xpForNextLevel = getXpForLevel(newPlayerStats.level, config);
    while (newPlayerStats.xp >= xpForNextLevel) {
        leveledUp = true;
        newPlayerStats.level += 1;
        newPlayerStats.xp -= xpForNextLevel;

        const gains = classDef.statGrowth;
        newPlayerStats.maxHp += gains.maxHp;
        newPlayerStats.maxArmor += gains.maxArmor;
        newPlayerStats.attack += gains.attack;
        
        newPlayerStats.hp = newPlayerStats.maxHp;
        newPlayerStats.armor = newPlayerStats.maxArmor;
        newPlayerStats.poisonStacks = 0;

        logs.push(`<span class="text-cyan-300 font-bold">LEVEL UP! You are now level ${newPlayerStats.level}!</span>`);
        xpForNextLevel = getXpForLevel(newPlayerStats.level, config);
    }

    return { newPlayerStats, logs, leveledUp };
};

export const applyGravityAndRefill = (board: Board, depth: number, config: GameConfig, difficulty: DifficultyLevel): Board => {
  const newBoard = JSON.parse(JSON.stringify(board));
  const size = config.boardSize;

  for (let col = 0; col < size; col++) {
    let writeRow = size - 1;
    for (let readRow = size - 1; readRow >= 0; readRow--) {
      if (newBoard[readRow][col] !== null) {
        if (writeRow !== readRow) {
          newBoard[writeRow][col] = newBoard[readRow][col];
          newBoard[readRow][col] = null;
        }
        writeRow--;
      }
    }
  }

  for (let row = 0; row < size; row++) {
    for (let col = 0; col < size; col++) {
      if (newBoard[row][col] === null) {
        newBoard[row][col] = createNewTile(depth, config, difficulty);
      }
    }
  }

  return newBoard;
};

export const activateAbility = (abilityId: string, board: Board, playerStats: PlayerStats, config: GameConfig) => {
    let newBoard = JSON.parse(JSON.stringify(board)) as Board;
    let newPlayerStats = { ...playerStats };
    const logs: string[] = [];
    
    const playerAbility = newPlayerStats.abilities.find(a => a.id === abilityId);
    if (!playerAbility || playerAbility.currentCooldown > 0) {
        return { newBoard, newPlayerStats, logs };
    }

    const abilityDef = config.abilities.find(ad => ad.id === abilityId);
    if (!abilityDef) return { newBoard, newPlayerStats, logs };
    
    logs.push(`You used <span class="text-yellow-300 font-bold">${abilityDef.name}!</span>`);

    const effect = abilityDef.effect;
    switch (effect.type) {
        case 'HEAL':
            const healed = Math.min(newPlayerStats.maxHp - newPlayerStats.hp, effect.amount);
            newPlayerStats.hp += healed;
            logs.push(`You healed for <span class="text-green-400">${healed}</span> HP.`);
            break;
        case 'DAMAGE_ALL_SKULLS':
            let totalDamage = 0;
            newBoard.flat().forEach(tile => {
                if (tile?.type === TileType.SKULL && tile.hp && tile.hp > 0) {
                    const damage = effect.amount;
                    tile.hp -= damage;
                    totalDamage += damage;
                }
            });
            logs.push(`All enemies take <span class="text-red-400">${effect.amount}</span> damage.`);
            break;
        case 'APPLY_BUFF':
            newPlayerStats.buffs.push({
                id: effect.buffId,
                durationTurns: effect.duration,
            });
            break;
        case 'CONVERT_TILES':
            const { from, to } = effect;
            newBoard.forEach(row => row.forEach(tile => {
                if (tile?.type === from) {
                    tile.type = to;
                    // Reset skull properties
                    tile.hp = undefined;
                    tile.maxHp = undefined;
                    tile.attack = undefined;
                    tile.armor = undefined;
                    tile.enemyId = undefined;
                    tile.name = undefined;
                    tile.traits = undefined;
                }
            }));
            break;
    }

    // Put ability on cooldown
    playerAbility.currentCooldown = abilityDef.baseCooldown - (abilityDef.cooldownReductionPerLevel * (playerAbility.currentLevel - 1));

    return { newBoard, newPlayerStats, logs };
};


export const tickDownCooldownsAndBuffs = (playerStats: PlayerStats) => {
    let newPlayerStats = { ...playerStats };
    const logs: string[] = [];

    // Tick down poison
    if (newPlayerStats.poisonStacks > 0) {
        const poisonDamage = newPlayerStats.poisonStacks;
        newPlayerStats.hp -= poisonDamage;
        logs.push(`You take <span class="text-green-600">${poisonDamage}</span> damage from poison.`);
        newPlayerStats.poisonStacks = Math.max(0, newPlayerStats.poisonStacks - 1); // Poison decays
    }
    
    // Tick down ability cooldowns
    newPlayerStats.abilities = newPlayerStats.abilities.map(ab => ({
        ...ab,
        currentCooldown: Math.max(0, ab.currentCooldown - 1),
    }));

    // Tick down buffs
    newPlayerStats.buffs = newPlayerStats.buffs
        .map(buff => ({ ...buff, durationTurns: buff.durationTurns - 1 }))
        .filter(buff => buff.durationTurns > 0);
    
    return { newPlayerStats, logs };
};

/**
 * Calculates the potential result of a path for UI preview purposes.
 */
export const calculatePathPreview = (board: Board, path: Position[], effectiveStats: PlayerStats, config: GameConfig): PathPreviewData | null => {
    if (path.length < config.minPathLength) return null;

    const firstTile = board[path[0].row][path[0].col];
    if (!firstTile) return null;

    const pathType = firstTile.type;
    const chainLength = path.length;
    const bonusItem = config.chainBonuses.slice().reverse().find(b => chainLength >= b.length);
    const bonus = bonusItem ? bonusItem.multiplier : 1.0;

    let value = 0;
    switch (pathType) {
        case TileType.SWORD:
        case TileType.SKULL:
            let attackMultiplier = 1.0;
            if (effectiveStats.buffs.some(b => b.id === 'double_attack')) {
                attackMultiplier = 2.0;
            }
            value = Math.floor(effectiveStats.attack * chainLength * bonus * attackMultiplier);
            break;
        case TileType.SHIELD:
            value = Math.floor(5 * chainLength * bonus);
            break;
        case TileType.POTION:
            value = Math.floor(10 * chainLength * bonus);
            break;
        case TileType.COIN:
            let goldMultiplier = (effectiveStats as any).coinMultiplier || 1.0;
            if (effectiveStats.buffs.some(b => b.id === 'double_gold')) {
                goldMultiplier *= 2.0;
            }
            value = Math.floor(chainLength * bonus * goldMultiplier);
            break;
    }
    
    return {
        type: pathType,
        count: chainLength,
        value: value,
        multiplier: bonus,
    };
};