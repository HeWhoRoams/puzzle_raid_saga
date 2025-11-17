import React from 'react';
import { PlayerAbility, AbilityDefinition } from '../types';

interface AbilityButtonProps {
  ability: PlayerAbility;
  definition: AbilityDefinition;
  onActivate: () => void;
}

const AbilityButton: React.FC<AbilityButtonProps> = ({ ability, definition, onActivate }) => {
  const isOnCooldown = ability.currentCooldown > 0;

  return (
    <button
      onClick={onActivate}
      disabled={isOnCooldown}
      title={`${definition.name}: ${definition.description}`}
      className={`relative w-14 h-14 bg-slate-700 rounded-lg shadow-md flex items-center justify-center text-2xl
                  transition-transform transform hover:scale-105 active:scale-95
                  disabled:bg-slate-800 disabled:cursor-not-allowed disabled:transform-none`}
    >
      {/* Icon */}
      <span>{definition.icon}</span>

      {/* Cooldown Overlay */}
      {isOnCooldown && (
        <div className="absolute inset-0 bg-black/70 rounded-lg flex items-center justify-center">
          <span className="text-white text-2xl font-bold">
            {ability.currentCooldown}
          </span>
        </div>
      )}
    </button>
  );
};

export default AbilityButton;
