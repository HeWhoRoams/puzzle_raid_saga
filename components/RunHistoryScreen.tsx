import React from 'react';
import { RunHistoryEntry } from '../types';

interface RunHistoryScreenProps {
  history: RunHistoryEntry[];
  onBack: () => void;
}

const RunHistoryScreen: React.FC<RunHistoryScreenProps> = ({ history, onBack }) => {
  return (
    <div className="w-full max-w-sm mx-auto flex flex-col h-full p-4">
      <h1 className="text-3xl font-bold text-center text-white mb-6">Run History</h1>
      <div className="flex-grow bg-slate-800/50 p-3 rounded-xl shadow-inner overflow-y-auto">
        {history.length === 0 ? (
          <p className="text-slate-400 text-center mt-8">No runs completed yet.</p>
        ) : (
          <div className="space-y-3">
            {history.map(run => (
              <div key={run.id} className="bg-slate-900/70 p-3 rounded-lg">
                <div className="flex justify-between items-center mb-1">
                  <p className="font-bold text-lg text-cyan-300">{run.className}</p>
                  <p className="font-bold text-lg text-yellow-300">{run.score.toLocaleString()} pts</p>
                </div>
                <div className="flex justify-between text-sm text-slate-400">
                  <span>Depth: {run.finalDepth} | Level: {run.finalLevel}</span>
                  <span>{new Date(run.date).toLocaleDateString()}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      <button
        onClick={onBack}
        className="mt-6 w-full bg-slate-700 hover:bg-slate-600 text-white font-bold py-2 px-6 rounded-lg transition-transform transform hover:scale-105"
      >
        Back
      </button>
    </div>
  );
};

export default RunHistoryScreen;
