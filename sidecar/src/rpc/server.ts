import { createServer, type Server, type Socket } from 'node:net';
import { unlink, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';
import { encodeFrame, FrameDecoder } from './framing.js';
import { dispatch, type RpcMethods, type RpcRequest } from './methods.js';

export interface RpcServerConfig {
  socketPath: string;  // Unix socket path on macOS; `\\.\pipe\name` on Windows
  methods: RpcMethods;
  /** Called to push a server-initiated notification to a connected client. */
  onConnect?: (push: (msg: unknown) => void) => void;
}

export interface RpcServerHandle {
  close(): Promise<void>;
  /** Broadcast a notification to all currently connected clients. */
  broadcast(msg: unknown): void;
  /** Replace the active method registry (lets the caller wire methods that
   *  depend on `handle.broadcast` after `startRpcServer` returns). */
  setMethods(m: RpcMethods): void;
}

export async function startRpcServer(cfg: RpcServerConfig): Promise<RpcServerHandle> {
  // Ensure stale socket file is removed on POSIX
  try { await unlink(cfg.socketPath); } catch { /* ignore */ }
  await mkdir(dirname(cfg.socketPath), { recursive: true }).catch(() => {});

  let activeMethods: RpcMethods = cfg.methods;
  const clients = new Set<Socket>();
  const server: Server = createServer((sock) => {
    clients.add(sock);
    const dec = new FrameDecoder();
    const push = (msg: unknown) => sock.write(encodeFrame(msg));
    cfg.onConnect?.(push);

    sock.on('data', async (chunk) => {
      let msgs: unknown[];
      try { msgs = dec.push(chunk); }
      catch (e) {
        sock.write(encodeFrame({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }));
        return;
      }
      for (const m of msgs) {
        const req = m as RpcRequest;
        const reply = await dispatch(activeMethods, req);
        sock.write(encodeFrame(reply));
      }
    });
    sock.on('close', () => clients.delete(sock));
    sock.on('error', () => clients.delete(sock));
  });

  await new Promise<void>((res, rej) => {
    server.once('error', rej);
    server.listen(cfg.socketPath, () => res());
  });

  return {
    async close() {
      for (const c of clients) c.destroy();
      await new Promise<void>((res) => server.close(() => res()));
      try { await unlink(cfg.socketPath); } catch { /* ignore */ }
    },
    broadcast(msg) {
      const b = encodeFrame(msg);
      for (const c of clients) c.write(b);
    },
    setMethods(m) { activeMethods = m; },
  };
}
