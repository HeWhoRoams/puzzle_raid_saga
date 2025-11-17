import React from 'react';
import { PathPreviewData, TileType } from '../types';

interface PathPreviewProps {
  previewData: PathPreviewData | null;
}

const previewConfig: Record<TileType, { label: string; icon: string; color: string }> = {
    [TileType.SWORD]: { label: 'Damage', icon: '⚔️', color: 'text-red-400' },
    [TileType.SKULL]: { label: 'Damage', icon: '⚔️', color: 'text-red-400' },
    [TileType.SHIELD]: { label: 'Armor', icon: '🛡️', color: 'text-blue-400' },
    [TileType.POTION]: { label: 'Heal', icon: '❤️', color: 'text-green-400' },
    [TileType.COIN]: { label: 'Gold', icon: '💰', color: 'text-yellow-400' },
};

const PathPreview: React.FC<PathPreviewProps> = ({ previewData }) => {
  if (!previewData) {
    return <div className="h-10 mb-2" />; // Reserve space to prevent layout shift
  }

  const config = previewConfig[previewData.type];

  return (
    <div className="h-10 mb-2 flex items-center justify-center transition-opacity duration-200">
      <div className="bg-slate-800/80 backdrop-blur-sm rounded-lg px-4 py-1 flex items-center space-x-4 text-lg font-bold shadow-lg">
        <div className="flex items-center space-x-2">
            <span className="text-xl">{config.icon}</span>
            <span className={config.color}>{config.label}: {previewData.value}</span>
        </div>
        <div className="text-slate-400">
            <span>({previewData.count} x {previewData.multiplier.toFixed(1)})</span>
        </div>
      </div>
    </div>
  );
};

export default PathPreview;