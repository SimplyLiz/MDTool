import { startRpcServer } from './rpc/server.js';
import { createLogger } from './logging/logger.js';
import { methods as methodRegistry } from './methods/index.js';

const args = parseArgs(process.argv.slice(2));
const log = createLogger({ level: (process.env.LOG_LEVEL as any) ?? 'info' });

const handle = await startRpcServer({ socketPath: args.socket, methods: methodRegistry });
log.info({ socket: args.socket }, 'mdtool-ai-worker listening');

const shutdown = async () => { log.info('shutdown'); await handle.close(); process.exit(0); };
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

function parseArgs(argv: string[]) {
  const i = argv.indexOf('--socket');
  if (i < 0 || !argv[i + 1]) throw new Error('Usage: --socket <path>');
  return { socket: argv[i + 1] };
}
