import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { Slot } from "radix-ui";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex cursor-pointer items-center justify-center gap-2 whitespace-nowrap rounded-full text-sm font-medium tracking-tight transition-[transform,opacity,background-color,border-color,box-shadow,filter] duration-[var(--motion-duration-micro)] ease-[var(--ease-out-strong)] disabled:pointer-events-none disabled:opacity-40 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:ring-2 focus-visible:ring-ring/70 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-950 hover:-translate-y-[1.5px] active:translate-y-0 active:scale-[0.96] active:duration-[80ms] aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 select-none",
  {
    variants: {
      variant: {
        default:
          "border border-white/12 bg-slate-900/80 text-slate-50 shadow-[0_1px_0_rgba(255,255,255,0.06)_inset,0_2px_8px_rgba(0,0,0,0.3)] backdrop-blur-md hover:border-white/18 hover:bg-slate-800/85 hover:shadow-[0_0_0_1px_rgba(125,211,252,0.12),0_2px_12px_rgba(0,0,0,0.4)] active:bg-slate-900 active:shadow-[0_1px_0_rgba(255,255,255,0.04)_inset]",
        destructive:
          "border border-red-500/30 bg-red-900/60 text-red-100 shadow-[0_1px_0_rgba(255,255,255,0.06)_inset,0_0_18px_rgba(239,68,68,0.12)] hover:bg-red-800/70 hover:border-red-400/40 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40",
        outline:
          "bg-transparent border border-white/14 text-slate-100 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] hover:bg-white/5 hover:border-white/22 hover:text-slate-50 hover:shadow-[inset_0_1px_0_rgba(255,255,255,0.06)]",
        secondary:
          "border border-white/10 bg-white/8 text-white/88 shadow-[inset_0_1px_0_rgba(255,255,255,0.08)] hover:bg-white/12 hover:border-white/16 hover:text-white active:bg-white/6",
        ghost:
          "text-slate-300 hover:bg-white/6 hover:text-slate-50 border border-transparent hover:border-white/8 active:bg-white/4",
        link: "text-sky-400 underline-offset-4 hover:text-sky-300 hover:underline bg-transparent border-none shadow-none",
      },
      size: {
        default: "h-10 px-5 has-[>svg]:px-4",
        xs: "h-7 gap-1 rounded-full px-3 text-xs has-[>svg]:px-2 [&_svg:not([class*='size-'])]:size-3",
        sm: "h-9 rounded-full gap-1.5 px-4 has-[>svg]:px-3",
        lg: "h-11 rounded-full px-7 has-[>svg]:px-5",
        icon: "size-9 rounded-full",
        "icon-xs": "size-7 rounded-full [&_svg:not([class*='size-'])]:size-3",
        "icon-sm": "size-8 rounded-full",
        "icon-lg": "size-11 rounded-full",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
  }) {
  const Comp = asChild ? Slot.Root : "button";

  return (
    <Comp
      data-slot="button"
      data-variant={variant}
      data-size={size}
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  );
}

export { Button, buttonVariants };
