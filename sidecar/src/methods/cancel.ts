import type { OpRegistry } from '../ops/op-registry.js';

export function createCancelHandler(registry: OpRegistry) {
  return async (p: { opId: string }): Promise<{ cancelled: boolean }> => {
    return { cancelled: registry.cancel(p.opId) };
  };
}
