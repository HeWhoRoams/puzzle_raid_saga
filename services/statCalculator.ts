import { PlayerStats, GameConfig, PlayerEquipment } from '../types';

/**
 * Calculates the player's final, effective stats by applying all bonuses from equipped items.
 */
export const calculateEffectivePlayerStats = (baseStats: PlayerStats, config: GameConfig): PlayerStats => {
  const effectiveStats = JSON.parse(JSON.stringify(baseStats));

  for (const slot in effectiveStats.equipment) {
    const playerItem = effectiveStats.equipment[slot as keyof PlayerEquipment];
    if (playerItem) {
      const itemDef = config.items.find(i => i.id === playerItem.itemId);
      if (itemDef) {
        const upgradeLevel = playerItem.currentUpgradeLevel;
        const upgrade = itemDef.upgradePath[upgradeLevel - 1]; // -1 because levels are 1-based
        if (upgrade) {
          const { modifiers } = upgrade;
          effectiveStats.maxHp += modifiers.maxHp || 0;
          effectiveStats.maxArmor += modifiers.maxArmor || 0;
          effectiveStats.attack += modifiers.attack || 0;
          
          if (modifiers.coinMultiplier) {
            effectiveStats.goldMultiplier = (effectiveStats.goldMultiplier || 1) * modifiers.coinMultiplier;
          }
          if (modifiers.xpGainMultiplier) {
            effectiveStats.xpGainMultiplier = (effectiveStats.xpGainMultiplier || 1) * modifiers.xpGainMultiplier;
          }
        }
      }
    }
  }

  // Ensure HP and Armor are capped by their new max values
  effectiveStats.hp = Math.min(effectiveStats.hp, effectiveStats.maxHp);
  effectiveStats.armor = Math.min(effectiveStats.armor, effectiveStats.maxArmor);

  return effectiveStats;
};
