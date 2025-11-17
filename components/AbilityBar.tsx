import React from 'react';
import { PlayerAbility, AbilityDefinition } from '../types';
import AbilityButton from './AbilityButton';

interface AbilityBarProps {
  abilities: (PlayerAbility & { definition?: AbilityDefinition })[];
  onActivate: (abilityId: string) => void;
}

const AbilityBar: React.FC<AbilityBarProps> = ({ abilities, onActivate }) => {
  return (
    <div className="w-full bg-slate-800/50 p-2 rounded-xl flex justify-center items-center space-x-2 sm:flex-col sm:space-y-2 sm:space-x-0">
      {abilities.map(ability => (
        ability.definition ? (
          <AbilityButton
            key={ability.id}
            ability={ability}
            definition={ability.definition}
            onActivate={() => onActivate(ability.id)}
          />
        ) : null
      ))}
    </div>
  );
};

export default AbilityBar;