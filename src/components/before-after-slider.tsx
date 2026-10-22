"use client";

import Image from "next/image";
import { useRef, useCallback, useEffect } from "react";

type BeforeAfterSliderProps = {
  beforeSrc: string;
  afterSrc: string;
  beforeAlt: string;
  afterAlt: string;
};

// Position lives in a CSS variable (--ba-pos) written straight to the DOM, not React state, so dragging
// never re-renders and stays smooth. Desktop: the divider follows the mouse. Touch: horizontal drags move
// it while vertical swipes still scroll the page (touch-action: pan-y). A tap or click glides to the spot.
export function BeforeAfterSlider({
  beforeSrc,
  afterSrc,
  beforeAlt,
  afterAlt,
}: BeforeAfterSliderProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const pos = useRef(50);
  const frame = useRef(0);
  const dragging = useRef(false);

  const apply = useCallback((pct: number, glide = false) => {
    const el = containerRef.current;
    if (!el) return;
    pos.current = Math.min(Math.max(pct, 0), 100);
    el.classList.toggle("ba-glide", glide);
    cancelAnimationFrame(frame.current);
    frame.current = requestAnimationFrame(() => {
      el.style.setProperty("--ba-pos", `${pos.current}%`);
      el.setAttribute("aria-valuenow", String(Math.round(pos.current)));
    });
  }, []);

  const pctAt = (clientX: number) => {
    const rect = containerRef.current!.getBoundingClientRect();
    return ((clientX - rect.left) / rect.width) * 100;
  };

  const onPointerDown = (e: React.PointerEvent) => {
    dragging.current = true;
    apply(pctAt(e.clientX), true);
    if (e.pointerType !== "touch") containerRef.current?.setPointerCapture(e.pointerId);
  };
  const onPointerMove = (e: React.PointerEvent) => {
    // Mouse/pen follow on hover; touch moves only while the finger is down.
    if (e.pointerType === "touch" && !dragging.current) return;
    apply(pctAt(e.clientX));
  };
  const onPointerEnd = () => {
    dragging.current = false;
  };

  const onKeyDown = (e: React.KeyboardEvent) => {
    const step = e.shiftKey ? 10 : 2;
    if (e.key === "ArrowLeft") apply(pos.current - step, true);
    else if (e.key === "ArrowRight") apply(pos.current + step, true);
    else if (e.key === "Home") apply(0, true);
    else if (e.key === "End") apply(100, true);
    else return;
    e.preventDefault();
  };

  useEffect(() => () => cancelAnimationFrame(frame.current), []);

  return (
    <div
      ref={containerRef}
      className="ba-slider"
      style={{ "--ba-pos": "50%" } as React.CSSProperties}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerEnd}
      onPointerCancel={onPointerEnd}
      onPointerLeave={onPointerEnd}
      onKeyDown={onKeyDown}
      tabIndex={0}
      role="slider"
      aria-label={`Before and after comparison: ${afterAlt.replace(/ after$/, "")}`}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={50}
    >
      {/* After: base layer, full width. */}
      <div className="ba-layer ba-after">
        <Image src={afterSrc} alt={afterAlt} fill sizes="(max-width:768px) 100vw, 800px" className="ba-img" quality={90} draggable={false} />
        <span className="ba-label ba-label-right">After</span>
      </div>

      {/* Before: clipped to the left of the divider. */}
      <div className="ba-layer ba-before">
        <Image src={beforeSrc} alt={beforeAlt} fill sizes="(max-width:768px) 100vw, 800px" className="ba-img" quality={90} draggable={false} />
        <span className="ba-label ba-label-left">Before</span>
      </div>

      <div className="ba-divider" aria-hidden="true">
        <div className="ba-handle">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M8 7l-5 5 5 5V7zm8 0v10l5-5-5-5z" />
          </svg>
        </div>
      </div>
    </div>
  );
}
