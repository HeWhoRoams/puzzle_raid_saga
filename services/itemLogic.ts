import { PlayerStats, AccountProgression, GameConfig, ItemOffer, PlayerItem, EquipmentSlot } from '../types';

/**
 * Generates a set of item/upgrade offers for the player, typically after a level up.
 */
export const generateItemOffers = (playerStats: PlayerStats, progression: AccountProgression, config: GameConfig): ItemOffer[] => {
  const offers: ItemOffer[] = [];
  const MAX_OFFERS = 3;

  // --- Generate Upgrade Offers ---
  const upgradeableItems: { item: PlayerItem; itemDef: any; slot: EquipmentSlot }[] = [];
  for (const slot in playerStats.equipment) {
    const item = playerStats.equipment[slot as EquipmentSlot];
    if (item) {
      const itemDef = config.items.find(i => i.id === item.itemId);
      if (itemDef && item.currentUpgradeLevel < itemDef.upgradePath.length) {
        upgradeableItems.push({ item, itemDef, slot: slot as EquipmentSlot });
      }
    }
  }

  if (upgradeableItems.length > 0) {
    const randomUpgradeable = upgradeableItems[Math.floor(Math.random() * upgradeableItems.length)];
    const { item, itemDef } = randomUpgradeable;
    const nextLevel = item.currentUpgradeLevel + 1;
    const upgradeDef = itemDef.upgradePath[nextLevel - 1];
    
    offers.push({
      type: 'upgrade',
      item,
      itemDef,
      upgradeDef,
      nextLevel,
    });
  }

  // --- Generate New Item Offers ---
  const availableSlots: EquipmentSlot[] = [];
  if (!playerStats.equipment.weapon) availableSlots.push('weapon');
  if (!playerStats.equipment.armor) availableSlots.push('armor');
  if (!playerStats.equipment.accessory1) availableSlots.push('accessory1');
  if (!playerStats.equipment.accessory2) availableSlots.push('accessory2');
  
  const potentialNewItems = config.items.filter(itemDef => 
    progression.globallyUnlockedItemIds.includes(itemDef.id) &&
    !Object.values(playerStats.equipment).some(i => i?.itemId === itemDef.id)
  );

  // Offer item for an empty slot first
  if (availableSlots.length > 0 && potentialNewItems.length > 0) {
    const targetSlot = availableSlots[Math.floor(Math.random() * availableSlots.length)];
    const itemsForSlot = potentialNewItems.filter(i => i.slot === targetSlot);
    if (itemsForSlot.length > 0) {
      const itemDef = itemsForSlot[Math.floor(Math.random() * itemsForSlot.length)];
      offers.push({ type: 'newItem', itemDef });
    }
  }

  // Add more new items if we still have space for offers
  while (offers.length < MAX_OFFERS && potentialNewItems.length > 0) {
      const randomIndex = Math.floor(Math.random() * potentialNewItems.length);
      const itemDef = potentialNewItems[randomIndex];
      
      // Avoid offering duplicates in the same screen
      if (!offers.some(o => o.type === 'newItem' && o.itemDef.id === itemDef.id)) {
          offers.push({ type: 'newItem', itemDef });
      }
      potentialNewItems.splice(randomIndex, 1); // Remove to avoid re-picking
  }
  
  return offers.slice(0, MAX_OFFERS);
};
