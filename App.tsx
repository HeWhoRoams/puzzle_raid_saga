
import React, { useState, useCallback, useMemo, useEffect, useRef } from 'react';
import { Board, Position, TileType, PlayerStats, DifficultyLevel, AccountProgression, ClassDefinition, TileData, ItemOffer, PathPreviewData, RunHistoryEntry, GameConfig } from './types';
import { BASE_PLAYER_STATS } from './constants';
import { 
    initializeBoard, 
    isAdjacent, 
    applyGravityAndRefill,
    getXpForLevel,
    resolvePlayerAction,
    resolveEnemyPreAttacks,
    resolveEnemyAttacks,
    tickDownCooldownsAndBuffs,
    resolveLevelUps,
    activateAbility,
    calculatePathPreview,
} from './services/gameLogic';
import { loadProgression, processEndOfRun, initializePlayerForClass, saveProgression } from './services/progression';
import { saveActiveRun, loadActiveRun, clearActiveRun, loadRunHistory, addRunToHistory } from './services/persistence';
import { calculateEffectivePlayerStats } from './services/statCalculator';
import { generateItemOffers } from './services/itemLogic';
import { loadAndValidateGameConfig } from './services/contentLoader';
import GameBoard from './components/GameBoard';
import GameLog from './components/GameLog';
import AbilityBar from './components/AbilityBar';
import ClassSelectionScreen from './components/ClassSelectionScreen';
import ItemOfferScreen from './components/ItemOfferScreen';
import PathPreview from './components/PathPreview';
import AttractScreen from './components/AttractScreen';
import RunHistoryScreen from './components/RunHistoryScreen';
import TopBar from './components/TopBar';
import FloatingText from './components/FloatingText';

type GameState = 'attract' | 'classSelection' | 'runHistory' | 'playing' | 'gameOver' | 'itemOffer';

interface FloatingTextData {
  id: number;
  text: string;
  type: 'damage' | 'heal' | 'armor' | 'gold' | 'xp';
  elementRef: React.RefObject<HTMLDivElement>;
}

const GameOverScreen: React.FC<{
    score: PlayerStats;
    depth: number;
    finalScore: number;
    onAcknowledge: () => void;
    endOfRunInfo: { xpGained: number; newUnlocks: string[] };
}> = ({ score, depth, finalScore, onAcknowledge, endOfRunInfo }) => (
    <div className="absolute inset-0 bg-black/80 flex flex-col justify-center items-center z-20 p-4">
        <div className="bg-slate-800 p-6 sm:p-8 rounded-xl shadow-2xl text-center max-w-sm w-full">
            <h2 className="text-4xl font-bold text-red-500 mb-2">Game Over</h2>
            <p className="text-2xl font-bold text-yellow-300 mb-4">Final Score: {finalScore.toLocaleString()}</p>
            <p className="text-slate-300">You reached level {score.level} at depth {depth}.</p>
            <p className="text-slate-300 mb-4">Final Gold: {score.gold}</p>
            <div className="bg-slate-900/50 p-3 rounded-lg mb-4 text-left">
                <p className="font-bold text-cyan-300">Class XP Gained: <span className="text-white">{endOfRunInfo.xpGained}</span></p>
                {endOfRunInfo.newUnlocks.length > 0 && (
                    <div className="mt-2">
                        <p className="font-bold text-yellow-300">New Unlocks!</p>
                        <ul className="list-disc list-inside text-sm">
                            {endOfRunInfo.newUnlocks.map(unlock => <li key={unlock}>{unlock}</li>)}
                        </ul>
                    </div>
                )}
            </div>
            <button
                onClick={onAcknowledge}
                className="bg-cyan-500 hover:bg-cyan-400 text-white font-bold py-2 px-6 rounded-lg transition-transform transform hover:scale-105"
            >
                Continue
            </button>
        </div>
    </div>
);

const App: React.FC = () => {
  const [config, setConfig] = useState<GameConfig | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [difficulty, setDifficulty] = useState<DifficultyLevel | null>(null);
  
  const [progression, setProgression] = useState<AccountProgression | null>(null);
  const [runHistory, setRunHistory] = useState<RunHistoryEntry[]>([]);
  const [hasSavedGame, setHasSavedGame] = useState(false);
  
  const [depth, setDepth] = useState(1);
  const [board, setBoard] = useState<Board | null>(null);
  const [playerStats, setPlayerStats] = useState<PlayerStats | null>(null);
  const [gameLog, setGameLog] = useState<string[]>([]);
  const [selectedPath, setSelectedPath] = useState<Position[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [fadingTiles, setFadingTiles] = useState<Position[]>([]);
  const [gameState, setGameState] = useState<GameState>('attract');
  const [endOfRunInfo, setEndOfRunInfo] = useState({ xpGained: 0, newUnlocks: [] as string[], finalScore: 0 });
  const [itemOffers, setItemOffers] = useState<ItemOffer[]>([]);
  const [pathPreview, setPathPreview] = useState<PathPreviewData | null>(null);

  const [floatingTexts, setFloatingTexts] = useState<FloatingTextData[]>([]);
  const prevStatsRef = useRef<PlayerStats | null>(null);
  const hpBarRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const loadContent = async () => {
      try {
        const loadedConfig = await loadAndValidateGameConfig();
        setConfig(loadedConfig);
        setDifficulty(loadedConfig.difficulty['Normal']);
        setProgression(loadProgression());
        setRunHistory(loadRunHistory());
        setHasSavedGame(!!loadActiveRun());
      } catch (e) {
        if (e instanceof Error) {
            setError(`Failed to load game content: ${e.message}`);
        } else {
            setError('An unknown error occurred while loading game content.');
        }
      }
    };
    loadContent();
  }, []);

  const addFloatingText = useCallback((text: string, type: FloatingTextData['type']) => {
    if (!hpBarRef.current) return;
    setFloatingTexts(prev => [
      ...prev,
      { id: Date.now() + Math.random(), text, type, elementRef: hpBarRef }
    ]);
  }, []);
  
  const removeFloatingText = useCallback((id: number) => {
      setFloatingTexts(prev => prev.filter(ft => ft.id !== id));
  }, []);

  useEffect(() => {
    if (playerStats && prevStatsRef.current) {
        const hpDiff = playerStats.hp - prevStatsRef.current.hp;
        if (hpDiff > 0) addFloatingText(`+${hpDiff}`, 'heal');
        if (hpDiff < 0) addFloatingText(`${hpDiff}`, 'damage');
        
        const armorDiff = playerStats.armor - prevStatsRef.current.armor;
        if (armorDiff > 0) addFloatingText(`+${armorDiff}`, 'armor');
        
        const goldDiff = playerStats.gold - prevStatsRef.current.gold;
        if (goldDiff > 0) addFloatingText(`+${goldDiff}g`, 'gold');
    }
    prevStatsRef.current = playerStats;
  }, [playerStats, addFloatingText]);

  useEffect(() => {
    const hasNewTiles = board?.some(row => row.some(tile => tile?.isNew));
    if (hasNewTiles) {
      const timer = setTimeout(() => {
        setBoard(currentBoard => {
          if (!currentBoard) return null;
          const newBoard = JSON.parse(JSON.stringify(currentBoard));
          let changed = false;
          newBoard.forEach((r: (TileData | null)[]) => r.forEach(t => {
            if (t?.isNew) {
              delete t.isNew;
              changed = true;
            }
          }));
          return changed ? newBoard : currentBoard;
        });
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [board]);

  const addLog = useCallback((message: string | string[]) => {
    const messages = Array.isArray(message) ? message : [message];
    if (messages.length === 0) return;
    setGameLog(prev => [...prev.slice(-10), ...messages]);
  }, []);

  const handleStartNewGame = () => {
    clearActiveRun();
    setHasSavedGame(false);
    setGameState('classSelection');
  }

  const handleContinueRun = () => {
    const savedState = loadActiveRun();
    if (savedState) {
      setBoard(savedState.board);
      setPlayerStats(savedState.playerStats);
      setDepth(savedState.depth);
      setGameLog(savedState.gameLog);
      setGameState('playing');
    }
  };

  const handleShowHistory = () => setGameState('runHistory');
  const handleBackToAttract = () => setGameState('attract');

  const handleSelectClass = useCallback((classId: string) => {
    if (!config || !difficulty) return;
    const newPlayerStats = initializePlayerForClass(classId, config);
    const newDepth = 1;
    const newBoard = initializeBoard(newDepth, config, difficulty);
    const newLog = [`A ${config.classes.find(c=>c.id === classId)?.name} enters the dungeon.`];
    
    setPlayerStats(newPlayerStats);
    setDepth(newDepth);
    setBoard(newBoard);
    setGameLog(newLog);
    setGameState('playing');
    saveActiveRun({ board: newBoard, playerStats: newPlayerStats, depth: newDepth, gameLog: newLog });
    setHasSavedGame(true);
  }, [config, difficulty]);

  const handleActivateAbility = useCallback((abilityId: string) => {
    if (gameState !== 'playing' || !board || !playerStats || !config) return;

    const result = activateAbility(abilityId, board, playerStats, config);
    setBoard(result.newBoard);
    setPlayerStats(result.newPlayerStats);
    addLog(result.logs);

  }, [board, playerStats, config, gameState, addLog]);

  const currentClassDef = useMemo(() => {
    if (!playerStats || !config) return null;
    return config.classes.find(c => c.id === playerStats.classId);
  }, [playerStats, config]);

  const effectivePlayerStats = useMemo(() => {
    if (!playerStats || !config) return null;
    return calculateEffectivePlayerStats(playerStats, config);
  }, [playerStats, config]);

  const resolveTurn = useCallback(() => {
    if (!board || !playerStats || !effectivePlayerStats || !currentClassDef || !config || !difficulty || selectedPath.length < config.minPathLength) return;

    if (selectedPath.length >= 5 && navigator.vibrate) {
        navigator.vibrate(50);
    }

    const actionResult = resolvePlayerAction(board, playerStats, effectivePlayerStats, selectedPath, config);
    let currentBoard = actionResult.newBoard;
    let currentStats = actionResult.newPlayerStats;
    let turnLogs = [...actionResult.logs];
    
    actionResult.defeatedEnemies.forEach(enemy => {
        currentStats.gold += enemy.goldReward;
        currentStats.xp += enemy.xpReward;
        turnLogs.push(`You defeated a ${enemy.name}! (+${enemy.goldReward}G, +${enemy.xpReward}XP)`);
    });

    const preAttackResult = resolveEnemyPreAttacks(currentBoard);
    currentBoard = preAttackResult.newBoard;
    turnLogs.push(...preAttackResult.logs);

    const enemyAttackResult = resolveEnemyAttacks(currentBoard, currentStats, effectivePlayerStats, selectedPath);
    currentStats = enemyAttackResult.newPlayerStats;
    turnLogs.push(...enemyAttackResult.logs);
    
    const endOfTurnResult = tickDownCooldownsAndBuffs(currentStats);
    currentStats = endOfTurnResult.newPlayerStats;
    turnLogs.push(...endOfTurnResult.logs);

    const levelUpResult = resolveLevelUps(currentStats, currentClassDef, config);
    currentStats = levelUpResult.newPlayerStats;
    turnLogs.push(...levelUpResult.logs);
    
    addLog(turnLogs);
    setPlayerStats(currentStats);

    if (levelUpResult.leveledUp && progression) {
        setItemOffers(generateItemOffers(currentStats, progression, config));
        setGameState('itemOffer');
    }

    const tilesToRemove = selectedPath.slice();
    currentBoard.forEach((row, r) => row.forEach((tile, c) => {
        if (tile?.type === TileType.SKULL && tile.hp !== undefined && tile.hp <= 0) {
            tilesToRemove.push({ row: r, col: c });
        }
    }));
    const uniqueTilesToRemove = tilesToRemove.filter((pos, index, self) =>
        index === self.findIndex((p) => p.row === pos.row && p.col === pos.col)
    );

    setFadingTiles(uniqueTilesToRemove);
    const nextDepth = depth + 1;

    setTimeout(() => {
        uniqueTilesToRemove.forEach(pos => {
            currentBoard[pos.row][pos.col] = null;
        });

        const gravityBoard = applyGravityAndRefill(currentBoard, nextDepth, config, difficulty);
        setBoard(gravityBoard);
        setFadingTiles([]);
        setDepth(nextDepth);

        if (currentStats.hp <= 0) { 
            if (progression && currentClassDef) {
                const finalScore = (depth * 100) + (currentStats.gold * 5) + (currentStats.level * 50);
                addRunToHistory({
                    score: finalScore,
                    className: currentClassDef.name,
                    finalLevel: currentStats.level,
                    finalDepth: depth,
                });
                setRunHistory(loadRunHistory()); 

                const { updatedProgression, xpGained, newUnlocks } = processEndOfRun(progression, currentStats, config);
                setProgression(updatedProgression);
                const abilityNames = newUnlocks.map(id => config.abilities.find(a => a.id === id)?.name || id);
                setEndOfRunInfo({ xpGained, newUnlocks: abilityNames, finalScore });
            }
            clearActiveRun();
            setHasSavedGame(false);
            setGameState('gameOver');
        } else { 
            saveActiveRun({ board: gravityBoard, playerStats: currentStats, depth: nextDepth, gameLog });
        }
    }, 300);

  }, [selectedPath, config, board, playerStats, effectivePlayerStats, addLog, depth, difficulty, currentClassDef, progression, gameLog]);

  const handleMouseDown = (pos: Position) => {
    if (gameState !== 'playing' || !board) return;
    const tile = board[pos.row][pos.col];
    if (!tile) return;
    setIsDragging(true);
    setSelectedPath([pos]);
  };

  const handleMouseEnter = (pos: Position) => {
    if (!isDragging || selectedPath.length === 0 || gameState !== 'playing' || !board || !effectivePlayerStats || !config) return;
    
    let currentPath = selectedPath;
    const lastPos = selectedPath[selectedPath.length - 1];
    if (pos.row === lastPos.row && pos.col === lastPos.col) return;
    
    if (selectedPath.length > 1 && pos.row === selectedPath[selectedPath.length - 2].row && pos.col === selectedPath[selectedPath.length - 2].col) {
        currentPath = selectedPath.slice(0, -1);
    } else if (!selectedPath.some(p => p.row === pos.row && p.col === pos.col)) {
        const currentTile = board[pos.row][pos.col];
        const pathType = board[selectedPath[0].row][selectedPath[0].col]?.type;
        if (!currentTile || !pathType) return;
        
        const isAttackPath = pathType === TileType.SWORD || pathType === TileType.SKULL;
        let isValidNextTile = isAttackPath ? (currentTile.type === TileType.SWORD || currentTile.type === TileType.SKULL) : (currentTile.type === pathType);

        if (isValidNextTile && isAdjacent(lastPos, pos)) {
          currentPath = [...selectedPath, pos];
        }
    }
    setSelectedPath(currentPath);
    setPathPreview(calculatePathPreview(board, currentPath, effectivePlayerStats, config));
  };

  const handleMouseUp = () => {
    if (isDragging && config) {
      if (selectedPath.length >= config.minPathLength) {
        resolveTurn();
      }
      setIsDragging(false);
      setSelectedPath([]);
      setPathPreview(null);
    }
  };

  const handlePurchaseOffer = (offer: ItemOffer) => {
    if (!playerStats || !progression) return;
    const cost = offer.type === 'newItem' ? 0 : offer.upgradeDef.cost;
    
    let newPlayerStats = {...playerStats, gold: playerStats.gold - cost};
    let newProgression = {...progression};

    if (offer.type === 'newItem') {
      const { itemDef } = offer;
      newPlayerStats.equipment[itemDef.slot] = { itemId: itemDef.id, currentUpgradeLevel: 1 };
      addLog(`You equipped the <span class="text-green-400">${itemDef.name}</span>.`);
      
      if (!progression.globallyUnlockedItemIds.includes(itemDef.id)) {
        newProgression.globallyUnlockedItemIds.push(itemDef.id);
        setProgression(newProgression);
        saveProgression(newProgression);
        addLog(`New item discovered and unlocked for future runs!`);
      }
    } else { 
      const { item, nextLevel, itemDef } = offer;
      item.currentUpgradeLevel = nextLevel;
      addLog(`You upgraded <span class="text-green-400">${itemDef.name}</span> to Level ${nextLevel}!`);
    }
    setPlayerStats(newPlayerStats);
    setGameState('playing');

    if (board) {
      saveActiveRun({ board, playerStats: newPlayerStats, depth, gameLog });
    }
  };

  const handleSkipOffers = () => {
    setGameState('playing');
    addLog('You decide to save your gold.');
  };
  
  const xpToNextLevel = (effectivePlayerStats && config) ? getXpForLevel(effectivePlayerStats.level, config) : 0;

  const playerAbilitiesWithData = useMemo(() => {
    if (!playerStats || !config) return [];
    return playerStats.abilities.map(pa => {
        const def = config.abilities.find(ad => ad.id === pa.id);
        return { ...pa, definition: def };
    }).filter(a => a.definition);
  }, [playerStats, config]);

  if (error) {
    return (
      <div className="h-screen w-screen flex items-center justify-center p-4 text-center bg-red-900/50">
        <div className="bg-slate-800 p-8 rounded-lg">
            <h2 className="text-2xl font-bold text-red-500 mb-4">Error</h2>
            <p className="text-slate-300">{error}</p>
        </div>
      </div>
    );
  }

  if (!config || !progression) {
      return <div className="h-screen w-screen flex items-center justify-center font-bold text-xl">Loading Game Content...</div>;
  }

  const renderContent = () => {
    switch(gameState) {
      case 'attract':
        return <AttractScreen hasSavedGame={hasSavedGame} onNewGame={handleStartNewGame} onContinue={handleContinueRun} onShowHistory={handleShowHistory} />;
      case 'classSelection':
        return <ClassSelectionScreen classes={config.classes} progression={progression} onSelectClass={handleSelectClass} />;
      case 'runHistory':
        return <RunHistoryScreen history={runHistory} onBack={handleBackToAttract} />;
      case 'playing':
      case 'gameOver':
      case 'itemOffer':
        if (!effectivePlayerStats || !board || !currentClassDef) return null;
        return (
          <div className="relative w-full max-w-sm sm:max-w-4xl h-full mx-auto flex flex-col sm:flex-row font-sans p-2 sm:gap-4 items-stretch justify-center">
            {floatingTexts.map(ft => 
              <FloatingText key={ft.id} text={ft.text} type={ft.type} onComplete={() => removeFloatingText(ft.id)} />
            )}
            {gameState === 'gameOver' && playerStats && <GameOverScreen score={playerStats} depth={depth} finalScore={endOfRunInfo.finalScore} onAcknowledge={handleBackToAttract} endOfRunInfo={endOfRunInfo} />}
            {gameState === 'itemOffer' && playerStats && (
              <ItemOfferScreen offers={itemOffers} playerGold={playerStats.gold} onPurchase={handlePurchaseOffer} onSkip={handleSkipOffers} />
            )}
            
            {/* ---- Game Board and Info Panel Layout ---- */}
            {/* Info panel appears first in portrait, second in landscape */}
            <div className="w-full sm:w-64 flex-shrink-0 flex flex-col gap-2 order-1 sm:order-2">
                 <div ref={hpBarRef}><TopBar stats={effectivePlayerStats} xpToNextLevel={xpToNextLevel} depth={depth} classDef={currentClassDef} /></div>
                 <AbilityBar abilities={playerAbilitiesWithData} onActivate={handleActivateAbility} />
                 
                 {/* Spacer to push log/preview to bottom in landscape */}
                 <div className="flex-grow hidden sm:block" />

                 {/* GameLog and PathPreview for landscape */}
                 <div className="hidden sm:block"><GameLog messages={gameLog} /></div>
                 <div className="hidden sm:block">
                    <PathPreview previewData={pathPreview} />
                 </div>
            </div>

            {/* Game board appears second in portrait, first in landscape */}
            <div className="w-full sm:flex-1 flex flex-col justify-center order-2 sm:order-1 mt-2 sm:mt-0">
                {/* PathPreview only for portrait, above board */}
                <div className="block sm:hidden">
                  <PathPreview previewData={pathPreview} />
                </div>
                <GameBoard board={board} selectedPath={selectedPath} fadingTiles={fadingTiles} onMouseDown={handleMouseDown} onMouseEnter={handleMouseEnter} onMouseUp={handleMouseUp} />
            </div>
            
            {/* GameLog is separate for portrait mode at the bottom */}
            <div className="flex-shrink-0 mt-2 order-3 sm:hidden">
              <GameLog messages={gameLog} />
            </div>

            {/* Spacer for portrait mode */}
            <div className="flex-grow order-4 sm:hidden" />

          </div>
        );
      default:
        return null;
    }
  }

  return (
    <div className="h-screen w-screen bg-slate-900 flex justify-center items-center overflow-hidden">
      {renderContent()}
    </div>
  );
};

export default App;
