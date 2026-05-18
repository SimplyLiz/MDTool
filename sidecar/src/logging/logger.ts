import pino, { type Logger, type LoggerOptions } from 'pino';

export interface LoggerConfig {
  level?: LoggerOptions['level'];
  destination?: (line: string) => void;
}

const REDACT_PATHS = [
  'apiKey', '*.apiKey',
  'token', '*.token',
  'authorization', '*.authorization',
  'password', '*.password',
  'secret', '*.secret',
  'accessToken', '*.accessToken',
  'refreshToken', '*.refreshToken',
  'headers.authorization',
  'headers["x-api-key"]',
  '*.provider.token',
];

export function createLogger(cfg: LoggerConfig = {}): Logger {
  const sink = cfg.destination;
  const stream = sink ? { write: (line: string) => sink(line) } : undefined;
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
