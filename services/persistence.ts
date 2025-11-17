import { SavedRunState, RunHistoryEntry } from '../types';

const ACTIVE_RUN_KEY = 'puzzleRaidSagaActiveRun';
const RUN_HISTORY_KEY = 'puzzleRaidSagaRunHistory';

// --- Active Run Persistence ---

export const saveActiveRun = (state: SavedRunState): void => {
  try {
    const stateString = JSON.stringify(state);
    localStorage.setItem(ACTIVE_RUN_KEY, stateString);
  } catch (error) {
    console.error("Failed to save active run:", error);
  }
};

export const loadActiveRun = (): SavedRunState | null => {
  try {
    const savedData = localStorage.getItem(ACTIVE_RUN_KEY);
    if (savedData) {
      return JSON.parse(savedData) as SavedRunState;
    }
    return null;
  } catch (error) {
    console.error("Failed to load active run:", error);
    return null;
  }
};

export const clearActiveRun = (): void => {
  try {
    localStorage.removeItem(ACTIVE_RUN_KEY);
  } catch (error) {
    console.error("Failed to clear active run:", error);
  }
};

// --- Run History Persistence ---

export const loadRunHistory = (): RunHistoryEntry[] => {
  try {
    const savedData = localStorage.getItem(RUN_HISTORY_KEY);
    if (savedData) {
      return JSON.parse(savedData) as RunHistoryEntry[];
    }
    return [];
  } catch (error) {
    console.error("Failed to load run history:", error);
    return [];
  }
};

const saveRunHistory = (history: RunHistoryEntry[]): void => {
  try {
    localStorage.setItem(RUN_HISTORY_KEY, JSON.stringify(history));
  } catch (error) {
    console.error("Failed to save run history:", error);
  }
};

export const addRunToHistory = (entry: Omit<RunHistoryEntry, 'id' | 'date'>): void => {
    const history = loadRunHistory();
    const newEntry: RunHistoryEntry = {
        ...entry,
        id: Date.now(),
        date: new Date().toISOString(),
    };
    const newHistory = [newEntry, ...history].slice(0, 50); // Keep last 50 runs
    saveRunHistory(newHistory);
};