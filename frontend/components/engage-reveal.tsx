"use client";

import { motion, useReducedMotion } from "framer-motion";

type EngageRevealProps = {
  children: React.ReactNode;
  className?: string;
  delay?: number;
};

export function EngageReveal({ children, className, delay = 0 }: EngageRevealProps) {
  const reduceMotion = useReducedMotion();

  if (reduceMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-48px 0px" }}
      transition={{ duration: 0.5, delay, ease: [0.23, 1, 0.32, 1] }}
    >
      {children}
    </motion.div>
  );
}
