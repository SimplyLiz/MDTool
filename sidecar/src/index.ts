import { startRpcServer } from './rpc/server.js';
import { createLogger } from './logging/logger.js';
import { buildMethods } from './methods/index.js';

const args = parseArgs(process.argv.slice(2));
const log = createLogger({ level: (process.env.LOG_LEVEL as any) ?? 'info' });

const apiKey = process.env.ANTHROPIC_API_KEY ?? '';
if (!apiKey) log.warn('ANTHROPIC_API_KEY missing — refine() will fail');

const handle = await startRpcServer({ socketPath: args.socket, methods: {} });
const methods = buildMethods({ anthropicApiKey: apiKey, broadcast: handle.broadcast });
handle.setMethods(methods);
log.info({ socket: args.socket }, 'mdtool-ai-worker listening');

const shutdown = async () => { log.info('shutdown'); await handle.close(); process.exit(0); };
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

function parseArgs(argv: string[]) {
  const i = argv.indexOf('--socket');
  const socket = argv[i + 1];
  if (i < 0 || !socket) throw new Error('Usage: --socket <path>');
  return { socket };
}
