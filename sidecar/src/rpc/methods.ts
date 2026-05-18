export type RpcMethod = (params: any) => Promise<unknown>;
export type RpcMethods = Record<string, RpcMethod>;

export interface RpcRequest { jsonrpc: '2.0'; id: number | string | null; method: string; params?: any; }
export interface RpcSuccess { jsonrpc: '2.0'; id: number | string | null; result: unknown; }
export interface RpcError   { jsonrpc: '2.0'; id: number | string | null; error: { code: number; message: string; data?: unknown }; }
export type RpcResponse = RpcSuccess | RpcError;

export async function dispatch(methods: RpcMethods, req: RpcRequest): Promise<RpcResponse> {
  const fn = methods[req.method];
  if (!fn) {
    return { jsonrpc: '2.0', id: req.id, error: { code: -32601, message: `Method not found: ${req.method}` } };
  }
  try {
    const result = await fn(req.params ?? {});
    return { jsonrpc: '2.0', id: req.id, result };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return { jsonrpc: '2.0', id: req.id, error: { code: -32603, message } };
  }
}
