import React from 'react';
import { PlayerStats, ClassDefinition } from '../types';

interface TopBarProps {
  stats: PlayerStats;
  xpToNextLevel: number;
  depth: number;
  classDef: ClassDefinition;
}

const StatBar: React.FC<{ value: number; maxValue: number; color: string; label: string }> = ({ value, maxValue, color, label }) => (
    <div className="relative w-full bg-slate-900/50 rounded-full h-3.5 shadow-inner overflow-hidden">
        <div title={label} className={`absolute top-0 left-0 h-full rounded-full transition-all duration-300 ${color}`} style={{ width: `${(value / maxValue) * 100}%` }} />
        <div className="absolute inset-0 text-white text-[10px] font-bold flex justify-center items-center">
            {value} / {maxValue}
        </div>
    </div>
);

const TopBar: React.FC<TopBarProps> = ({ stats, xpToNextLevel, depth, classDef }) => {
  return (
    <div className="w-full bg-slate-800/50 backdrop-blur-sm p-2 rounded-xl shadow-lg flex items-center sm:flex-col space-x-3 sm:space-x-0 sm:space-y-3">
      {/* Player Portrait */}
      <div className="flex-shrink-0 text-center">
        <div className="w-14 h-14 bg-slate-700 rounded-full flex items-center justify-center text-3xl border-2 border-slate-600">
            {classDef.icon}
        </div>
        <p className="text-sm font-bold text-cyan-300 mt-1">Lvl {stats.level}</p>
      </div>
      
      {/* Stats Area */}
      <div className="flex-grow sm:w-full space-y-1.5">
        <StatBar value={stats.hp} maxValue={stats.maxHp} color="bg-red-500" label="HP" />
        <StatBar value={stats.armor} maxValue={stats.maxArmor} color="bg-blue-500" label="Armor"/>
        <StatBar value={stats.xp} maxValue={xpToNextLevel} color="bg-purple-500" label="XP" />
      </div>

      {/* Gold and Depth */}
      <div className="flex-shrink-0 text-right sm:w-full sm:flex sm:justify-around space-y-2 sm:space-y-0">
         <div className="text-lg font-semibold text-yellow-400 bg-slate-900/50 px-2 py-0.5 rounded-md">
          <span className="mr-1">💰</span>{stats.gold}
        </div>
         <div className="text-lg font-semibold text-gray-300 bg-slate-900/50 px-2 py-0.5 rounded-md">
          <span className="mr-1">B</span>{depth}
        </div>
      </div>
    </div>
  );
};

export default TopBar;