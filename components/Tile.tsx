import React from 'react';
import { TileData, TileType, EnemyTrait } from '../types';

interface TileProps {
  tile: TileData;
  row: number;
  col: number;
  tileSize: number;
  isSelected: boolean;
  isFadingOut: boolean;
}

const traitIcons: Record<EnemyTrait, React.ReactNode> = {
  POISON: <div title="Poison" className="w-3 h-3 bg-green-600 border border-black rounded-full" />,
  ARMOR_PIERCING: <div title="Armor Piercing" className="w-3 h-3 bg-fuchsia-600 border border-black rounded-full" />,
  HEAL_ALLIES: <div title="Heals Allies" className="w-3 h-3 bg-lime-400 border border-black rounded-full" />,
  SPAWN_SKULLS: <div title="Spawns Skulls" className="w-3 h-3 bg-purple-700 border border-black rounded-full" />,
};

const tileTypeClasses: Record<TileType, { bg: string; icon: React.ReactNode }> = {
  [TileType.SWORD]: { bg: 'bg-gradient-to-br from-red-500 to-gray-700 hover:from-red-400 hover:to-gray-600', icon: <SwordIcon className="w-1/2 h-1/2 text-white" /> },
  [TileType.SHIELD]: { bg: 'bg-blue-500 hover:bg-blue-400', icon: <ShieldIcon className="w-1/2 h-1/2 text-white" /> },
  [TileType.POTION]: { bg: 'bg-green-500 hover:bg-green-400', icon: <HeartIcon className="w-1/2 h-1/2 text-white" /> },
  [TileType.COIN]: { bg: 'bg-yellow-500 hover:bg-yellow-400', icon: <CoinIcon className="w-1/2 h-1/2 text-slate-800" /> },
  [TileType.SKULL]: { bg: 'bg-gray-700 hover:bg-gray-600', icon: <SkullIcon className="w-1/2 h-1/2 text-red-300" /> },
};

const Tile: React.FC<TileProps> = ({ tile, row, col, tileSize, isSelected, isFadingOut }) => {
  const { type, hp, maxHp, name, traits, isNew } = tile;
  const style = tileTypeClasses[type];
  const healthPercentage = (hp && maxHp) ? (hp / maxHp) * 100 : 0;

  return (
    <div
      className="absolute"
      style={{
        width: tileSize,
        height: tileSize,
        transform: `translate(${col * tileSize}px, ${row * tileSize}px)`,
        transition: 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
        zIndex: isSelected ? 10 : 1,
      }}
    >
      <div
        className={`w-full h-full p-1 transition-opacity duration-300 ${isNew ? 'animate-fall-in' : ''}`}
      >
        <div
          className={`relative w-full h-full rounded-lg shadow-lg flex items-center justify-center transition-all duration-200 flex-col ${style.bg} ${isSelected ? 'transform scale-110 ring-4 ring-white' : ''} ${isFadingOut ? 'opacity-0 scale-50' : 'opacity-100 scale-100'}`}
        >
          <div className="flex-grow flex items-center justify-center w-full">{style.icon}</div>
          
          {type === TileType.SKULL && (
            <div className="absolute top-1 right-1 flex space-x-0.5">
              {traits?.map(trait => <React.Fragment key={trait}>{traitIcons[trait]}</React.Fragment>)}
            </div>
          )}

          {type === TileType.SKULL && name && (
            <div className="text-center text-[8px] leading-tight font-semibold text-white mt-1 absolute bottom-4">
                {name}
            </div>
          )}

          {type === TileType.SKULL && hp !== undefined && maxHp !== undefined && (
            <div className="absolute bottom-1 left-1 right-1 h-2 bg-gray-900 rounded-full overflow-hidden border border-black">
              <div
                className="h-full bg-red-600 transition-all duration-300"
                style={{ width: `${healthPercentage}%` }}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// SVG Icons (no changes)
function SwordIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14.5 17.5L3 6V3h3l11.5 11.5" />
      <path d="M13 19l6-6" />
      <path d="M16 16l4 4" />
      <path d="M19 13l-1.5 1.5" />
    </svg>
  );
}
function ShieldIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
function HeartIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </svg>
  );
}
function CoinIcon(props: React.SVGProps<SVGSVGElement>) {
    return (
      <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="8" />
        <path d="M12 18V6" />
        <path d="M16 14c-1.5 0-3-1.33-3-4 0-2.67 1.5-4 3-4" />
      </svg>
    );
}
function StarIcon(props: React.SVGProps<SVGSVGElement>) {
    return (
      <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round">
        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
      </svg>
    );
}
function SkullIcon(props: React.SVGProps<SVGSVGElement>) {
    return (
      <svg {...props} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="9" cy="12" r="1" />
        <circle cx="15" cy="12" r="1" />
        <path d="M8 20v2h8v-2" />
        <path d="M12.5 17.5c-.3.3-.8.5-1.5.5s-1.2-.2-1.5-.5" />
        <path d="M20 20a8 8 0 00-16 0" />
        <path d="M16 4.3A8.8 8.8 0 0012 3a8.8 8.8 0 00-4 1.3" />
      </svg>
    );
}

export default Tile;