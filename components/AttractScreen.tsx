import React from 'react';

interface AttractScreenProps {
  hasSavedGame: boolean;
  onNewGame: () => void;
  onContinue: () => void;
  onShowHistory: () => void;
}

const AttractScreen: React.FC<AttractScreenProps> = ({ hasSavedGame, onNewGame, onContinue, onShowHistory }) => {
  return (
    <div className="w-full max-w-sm mx-auto flex flex-col items-center justify-center h-full text-center p-4">
      <h1 className="text-5xl font-bold text-cyan-300 mb-4">Puzzle Raid Saga</h1>
      <p className="text-slate-400 mb-12">Match tiles, defeat monsters, and delve deep into the dungeon.</p>
      <div className="w-full space-y-4">
        {hasSavedGame && (
          <button
            onClick={onContinue}
            className="w-full bg-green-600 hover:bg-green-500 text-white font-bold py-3 px-6 rounded-lg transition-transform transform hover:scale-105 text-lg"
          >
            Continue Run
          </button>
        )}
        <button
          onClick={onNewGame}
          className="w-full bg-cyan-500 hover:bg-cyan-400 text-white font-bold py-3 px-6 rounded-lg transition-transform transform hover:scale-105 text-lg"
        >
          New Game
        </button>
        <button
          onClick={onShowHistory}
          className="w-full bg-slate-700 hover:bg-slate-600 text-white font-bold py-3 px-6 rounded-lg transition-transform transform hover:scale-105 text-lg"
        >
          Run History
        </button>
      </div>
    </div>
  );
};

export default AttractScreen;
