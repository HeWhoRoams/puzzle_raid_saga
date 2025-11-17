
import React, { useEffect, useRef } from 'react';

interface GameLogProps {
  messages: string[];
}

const GameLog: React.FC<GameLogProps> = ({ messages }) => {
  const logEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="w-full h-20 bg-slate-800/50 p-3 rounded-xl shadow-inner">
      <div className="h-full overflow-y-auto text-sm text-slate-300 space-y-1">
        {messages.map((msg, index) => (
          <p key={index} dangerouslySetInnerHTML={{ __html: msg }} />
        ))}
        <div ref={logEndRef} />
      </div>
    </div>
  );
};

export default GameLog;