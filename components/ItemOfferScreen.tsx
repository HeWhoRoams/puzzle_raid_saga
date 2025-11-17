import React from 'react';
import { ItemOffer, ItemStatModifiers } from '../types';

const formatModifier = (key: keyof ItemStatModifiers, value: number): string => {
  switch (key) {
    case 'maxHp':
      return `+${value} Max HP`;
    case 'maxArmor':
      return `+${value} Max Armor`;
    case 'attack':
      return `+${value} Attack`;
    case 'coinMultiplier':
      return `+${((value - 1) * 100).toFixed(0)}% Gold`;
    case 'xpGainMultiplier':
      return `+${((value - 1) * 100).toFixed(0)}% XP`;
    default:
      return '';
  }
};

const ModifierList: React.FC<{ modifiers: ItemStatModifiers }> = ({ modifiers }) => (
  <ul className="text-sm text-slate-300 list-disc list-inside">
    {Object.entries(modifiers).map(([key, value]) => (
      // FIX: Cast `value` to number. Object.entries returns `[string, unknown]`
      // which is not directly compatible with `formatModifier`'s `value: number` parameter.
      value ? <li key={key}>{formatModifier(key as keyof ItemStatModifiers, value as number)}</li> : null
    ))}
  </ul>
);


const OfferCard: React.FC<{ offer: ItemOffer; playerGold: number; onPurchase: (offer: ItemOffer) => void }> = ({ offer, playerGold, onPurchase }) => {
  if (offer.type === 'newItem') {
    const { itemDef } = offer;
    const baseModifiers = itemDef.upgradePath[0].modifiers;
    return (
      <div className="bg-slate-800 p-4 rounded-lg flex flex-col">
        <div className="flex items-center space-x-3 mb-2">
          <span className="text-3xl">{itemDef.icon}</span>
          <div>
            <h3 className="font-bold text-green-400">New: {itemDef.name}</h3>
            <p className="text-xs text-slate-400 capitalize">{itemDef.slot.replace('accessory', 'Accessory ')}</p>
          </div>
        </div>
        <p className="text-sm text-slate-400 mb-2 flex-grow">{itemDef.description}</p>
        <ModifierList modifiers={baseModifiers} />
        <button
          onClick={() => onPurchase(offer)}
          className="mt-3 w-full bg-green-600 hover:bg-green-500 text-white font-bold py-2 px-4 rounded transition"
        >
          Equip (Free)
        </button>
      </div>
    );
  } else { // upgrade
    const { item, itemDef, upgradeDef, nextLevel } = offer;
    const canAfford = playerGold >= upgradeDef.cost;
    return (
      <div className="bg-slate-800 p-4 rounded-lg flex flex-col">
        <div className="flex items-center space-x-3 mb-2">
          <span className="text-3xl">{itemDef.icon}</span>
          <div>
            <h3 className="font-bold text-cyan-400">Upgrade: {itemDef.name}</h3>
            {/* FIX: The 'item' was missing from the destructuring above, causing an error. */}
            <p className="text-xs text-slate-400">Level {item.currentUpgradeLevel} → {nextLevel}</p>
          </div>
        </div>
        <p className="text-sm text-slate-400 mb-2 flex-grow">{itemDef.description}</p>
        <ModifierList modifiers={upgradeDef.modifiers} />
        <button
          onClick={() => onPurchase(offer)}
          disabled={!canAfford}
          className="mt-3 w-full bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-700 disabled:cursor-not-allowed text-white font-bold py-2 px-4 rounded transition"
        >
          Upgrade ({upgradeDef.cost}G)
        </button>
      </div>
    );
  }
};


interface ItemOfferScreenProps {
  offers: ItemOffer[];
  playerGold: number;
  onPurchase: (offer: ItemOffer) => void;
  onSkip: () => void;
}

const ItemOfferScreen: React.FC<ItemOfferScreenProps> = ({ offers, playerGold, onPurchase, onSkip }) => {
  return (
    <div className="absolute inset-0 bg-black/80 flex flex-col justify-center items-center z-10 p-4">
      <div className="bg-slate-900 p-6 rounded-xl shadow-2xl text-center max-w-sm w-full space-y-4">
        <div>
          <h2 className="text-2xl font-bold text-yellow-300">Level Up!</h2>
          <p className="text-slate-400">Choose a reward.</p>
        </div>

        <div className="space-y-3">
            {offers.map((offer, index) => (
                <OfferCard key={index} offer={offer} playerGold={playerGold} onPurchase={onPurchase} />
            ))}
        </div>
        
        <button
          onClick={onSkip}
          className="mt-2 w-full bg-slate-700 hover:bg-slate-600 text-white font-bold py-2 px-6 rounded-lg transition"
        >
          Skip
        </button>
      </div>
    </div>
  );
};

export default ItemOfferScreen;