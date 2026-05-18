import { describe, it, expect, afterEach } from 'vitest';
import { createConnection } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { startRpcServer, type RpcServerHandle } from '../../src/rpc/server.js';
import { encodeFrame, FrameDecoder } from '../../src/rpc/framing.js';

let handle: RpcServerHandle | null = null;

afterEach(async () => {
  if (handle) { await handle.close(); handle = null; }
});

describe('rpc server', () => {
  it('responds to a registered method', async () => {
    const sockPath = join(tmpdir(), `aiworker-test-${Date.now()}.sock`);
    handle = await startRpcServer({
      socketPath: sockPath,
      methods: {
        echo: async (params: { text: string }) => ({ text: params.text + '!' }),
      },
    });

    const reply = await rpcCall(sockPath, { jsonrpc: '2.0', id: 1, method: 'echo', params: { text: 'hi' } });
    expect(reply).toEqual({ jsonrpc: '2.0', id: 1, result: { text: 'hi!' } });
  });

  it('returns -32601 on unknown method', async () => {
    const sockPath = join(tmpdir(), `aiworker-test-${Date.now()}.sock`);
    handle = await startRpcServer({ socketPath: sockPath, methods: {} });
    const reply = await rpcCall(sockPath, { jsonrpc: '2.0', id: 1, method: 'nope' }) as any;
    expect(reply.error.code).toBe(-32601);
  });
});

function rpcCall(path: string, req: unknown): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const sock = createConnection(path);
    const dec = new FrameDecoder();
    sock.on('data', (b) => {
      const msgs = dec.push(b);
      if (msgs.length > 0) { resolve(msgs[0]); sock.end(); }
    });
    sock.on('error', reject);
    sock.on('connect', () => sock.write(encodeFrame(req)));
  });
}
