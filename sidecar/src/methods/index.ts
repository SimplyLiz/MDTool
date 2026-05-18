import type { RpcMethods } from '../rpc/methods.js';
import { health } from './health.js';
import { createRefineHandler } from './refine.js';
import { createCancelHandler } from './cancel.js';
import { OpRegistry } from '../ops/op-registry.js';
import { createAnthropicProvider } from '../providers/anthropic.js';

export interface BuildMethodsCfg {
  anthropicApiKey: string;
  broadcast: (msg: unknown) => void;
}

export function buildMethods(cfg: BuildMethodsCfg): RpcMethods {
  const registry = new OpRegistry();
  const provider = createAnthropicProvider({ apiKey: cfg.anthropicApiKey });
  return {
    health: async () => health(),
    refine: createRefineHandler({ provider, registry, broadcast: cfg.broadcast }),
    cancel: createCancelHandler(registry),
  };
}

// Legacy export for tests that don't need the provider yet:
export const methods: RpcMethods = { health: async () => health() };
