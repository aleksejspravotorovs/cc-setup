import { cubicBezier } from 'motion';

export const easings = {
  outCubic: cubicBezier(0.33, 1, 0.68, 1),
  inOutCubic: cubicBezier(0.65, 0, 0.35, 1),
  outQuart: cubicBezier(0.25, 1, 0.5, 1),
  inOutQuart: cubicBezier(0.76, 0, 0.24, 1),
  snappy: cubicBezier(0.2, 0.21, 0, 1),
};
