import pino, { type Logger, type LoggerOptions } from 'pino';

export interface LoggerConfig {
  level?: LoggerOptions['level'];
  destination?: (line: string) => void;
}

const REDACT_PATHS = [
  'apiKey', '*.apiKey',
  'token', '*.token',
  'authorization', '*.authorization',
  '*.provider.token',
];

export function createLogger(cfg: LoggerConfig = {}): Logger {
  const stream = cfg.destination
    ? { write: (line: string) => cfg.destination!(line) }
    : undefined;
  return pino(
    {
      level: cfg.level ?? 'info',
      redact: { paths: REDACT_PATHS, censor: '[REDACTED]' },
      base: undefined,
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    stream
  );
}
