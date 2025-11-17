import React from 'react';
import { AccountProgression, ClassDefinition } from '../types';
import { getClassLevel } from '../services/progression';

interface ClassCardProps {
  classDef: ClassDefinition;
  classProgress?: { xp: number; level: number };
  onSelect: () => void;
}

const ClassCard: React.FC<ClassCardProps> = ({ classDef, classProgress, onSelect }) => {
    const level = classProgress?.level || 1;
    const { xpForNext, currentLevelXp } = getClassLevel(classProgress?.xp || 0);
    const xpInCurrentLevel = (classProgress?.xp || 0) - currentLevelXp;
    const xpToNextInLevel = xpForNext - currentLevelXp;
    const xpProgressPercent = xpToNextInLevel > 0 ? (xpInCurrentLevel / xpToNextInLevel) * 100 : 0;

    return (
        <button
            onClick={onSelect}
            className="w-full bg-slate-800 p-4 rounded-lg shadow-lg text-left flex flex-col items-start space-y-3
                       transition-transform transform hover:bg-slate-700 hover:scale-105"
        >
            <div className="flex items-center space-x-4 w-full">
                <div className="text-4xl">{classDef.icon}</div>
                <div>
                    <h3 className="text-xl font-bold text-cyan-300">{classDef.name}</h3>
                    <p className="text-sm text-slate-400">Level {level}</p>
                </div>
            </div>
            <p className="text-sm text-slate-300 flex-grow min-h-[3rem]">{classDef.description}</p>
            
            {/* XP Bar */}
            <div className="w-full pt-1">
                <div className="relative w-full bg-slate-900 rounded-full h-2.5">
                    <div
                        className="bg-purple-500 h-2.5 rounded-full"
                        style={{ width: `${xpProgressPercent}%` }}
                    />
                </div>
                 <p className="text-xs text-slate-500 text-center mt-1">{xpInCurrentLevel.toLocaleString()} / {xpToNextInLevel.toLocaleString()} XP</p>
            </div>
        </button>
    );
};


interface ClassSelectionScreenProps {
  classes: ClassDefinition[];
  progression: AccountProgression;
  onSelectClass: (classId: string) => void;
}

const ClassSelectionScreen: React.FC<ClassSelectionScreenProps> = ({ classes, progression, onSelectClass }) => {
  return (
    <div className="w-full max-w-sm sm:max-w-4xl mx-auto flex flex-col p-4">
      <h1 className="text-3xl font-bold text-center text-white mb-6">Choose Your Class</h1>
      <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
        {classes.map(classDef => (
            <ClassCard
            key={classDef.id}
            classDef={classDef}
            classProgress={progression.classData[classDef.id]}
            onSelect={() => onSelectClass(classDef.id)}
            />
        ))}
      </div>
    </div>
  );
};

export default ClassSelectionScreen;
