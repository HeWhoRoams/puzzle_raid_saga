import React, { useEffect, useState } from 'react';

interface FloatingTextProps {
  text: string;
  type: 'damage' | 'heal' | 'armor' | 'gold' | 'xp';
  onComplete: () => void;
}

const typeStyles: Record<FloatingTextProps['type'], string> = {
  damage: 'text-red-500',
  heal: 'text-green-400',
  armor: 'text-blue-400',
  gold: 'text-yellow-400',
  xp: 'text-purple-400',
};

const FloatingText: React.FC<FloatingTextProps> = ({ text, type, onComplete }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onComplete();
    }, 1400); // Should match animation duration
    return () => clearTimeout(timer);
  }, [onComplete]);
  
  const [horizontalOffset] = useState(Math.random() * 60 - 30); // -30px to +30px

  return (
    <div
      className={`absolute top-1/4 left-1/2 text-2xl font-bold pointer-events-none z-30 animate-float-up ${typeStyles[type]}`}
      style={{
        transform: `translateX(calc(-50% + ${horizontalOffset}px))`,
        textShadow: '1px 1px 2px black',
      }}
    >
      {text}
    </div>
  );
};

export default FloatingText;
