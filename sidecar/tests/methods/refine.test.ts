import { describe, it, expect, vi } from 'vitest';
import { createRefineHandler } from '../../src/methods/refine.js';
import { OpRegistry } from '../../src/ops/op-registry.js';

describe('refine method', () => {
  it('returns an opId synchronously and pushes notifications', async () => {
    const sentMsgs: unknown[] = [];
    const fakeProvider = {
      refineStream: async function* () {
        yield { kind: 'delta', text: 'foo' };
        yield { kind: 'done', tokenUsage: { input: 1, output: 1 }, cost: 0 };
      },
    };
    const handler = createRefineHandler({
      provider: fakeProvider as any,
      registry: new OpRegistry(),
      broadcast: (m) => sentMsgs.push(m),
    });

    const { opId } = await handler({ selection: 'hello', op: 'refine' });
    expect(opId).toMatch(/^[0-9a-f-]{36}$/);

    // Allow the async streaming task to complete.
    await new Promise((r) => setTimeout(r, 5));
    expect(sentMsgs).toEqual([
      { jsonrpc: '2.0', method: 'stream.delta', params: { opId, blockIdx: 0, deltaType: 'add', text: 'foo' } },
      { jsonrpc: '2.0', method: 'stream.done', params: { opId, totalBlocks: 1, tokenUsage: { input: 1, output: 1 }, cost: 0 } },
    ]);
  });
});
