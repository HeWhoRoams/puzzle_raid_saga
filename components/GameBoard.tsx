import React, { useState, useEffect, useRef } from 'react';
import { Board, Position } from '../types';
import Tile from './Tile';

interface GameBoardProps {
  board: Board;
  selectedPath: Position[];
  fadingTiles: Position[];
  onMouseDown: (pos: Position) => void;
  onMouseEnter: (pos: Position) => void;
  onMouseUp: () => void;
}

const GameBoard: React.FC<GameBoardProps> = ({ board, selectedPath, fadingTiles, onMouseDown, onMouseEnter, onMouseUp }) => {
  const gameBoardRef = useRef<HTMLDivElement>(null);
  const [tileSize, setTileSize] = useState(0);

  useEffect(() => {
    const boardEl = gameBoardRef.current;
    if (boardEl) {
      const handleResize = () => {
        // In landscape, width is determined by height, so use offsetHeight if it's the constraint
        const isLandscape = window.innerWidth > window.innerHeight;
        const dimension = isLandscape ? boardEl.offsetHeight : boardEl.offsetWidth;
        setTileSize(dimension / board.length);
      };
      
      handleResize();
      const resizeObserver = new ResizeObserver(handleResize);
      resizeObserver.observe(boardEl);
      
      return () => resizeObserver.disconnect();
    }
  }, [board.length]);
  
  const isSelected = (row: number, col: number) =>
    selectedPath.some(p => p.row === row && p.col === col);

  const isFading = (row: number, col: number) =>
    fadingTiles.some(p => p.row === row && p.col === col);
  
  const getPositionForEvent = (e: React.MouseEvent | React.TouchEvent<HTMLDivElement>) => {
      if (!gameBoardRef.current || tileSize === 0) return null;
      const rect = gameBoardRef.current.getBoundingClientRect();
      const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
      const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
      
      const x = clientX - rect.left;
      const y = clientY - rect.top;

      const col = Math.floor(x / tileSize);
      const row = Math.floor(y / tileSize);

      if (row >= 0 && row < board.length && col >= 0 && col < board.length) {
          return { row, col };
      }
      return null;
  }

  return (
    <div
      ref={gameBoardRef}
      className="relative touch-none bg-slate-800 p-1 rounded-xl shadow-inner select-none w-full h-auto sm:w-auto sm:h-full"
      style={{
        aspectRatio: '1 / 1',
      }}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
      onTouchEnd={onMouseUp}
      onTouchCancel={onMouseUp}
      onMouseDown={(e) => {
          const pos = getPositionForEvent(e);
          if (pos) onMouseDown(pos);
      }}
      onMouseMove={(e) => {
          const pos = getPositionForEvent(e);
          if (pos) onMouseEnter(pos);
      }}
      onTouchStart={(e) => {
          e.preventDefault();
          const pos = getPositionForEvent(e);
          if (pos) onMouseDown(pos);
      }}
      onTouchMove={(e) => {
          e.preventDefault();
          const pos = getPositionForEvent(e);
          if (pos) onMouseEnter(pos);
      }}
    >
      {tileSize > 0 && board.map((rowArr, rowIndex) =>
        rowArr.map((tile, colIndex) =>
          tile ? (
            <Tile
              key={tile.id}
              tile={tile}
              row={rowIndex}
              col={colIndex}
              tileSize={tileSize}
              isSelected={isSelected(rowIndex, colIndex)}
              isFadingOut={isFading(rowIndex, colIndex)}
            />
          ) : null
        )
      )}
    </div>
  );
};

export default GameBoard;