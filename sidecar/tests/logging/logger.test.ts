import { describe, it, expect, vi } from 'vitest';
import { createLogger } from '../../src/logging/logger.js';

describe('logger', () => {
  it('redacts known API key shapes', () => {
    const sink: unknown[] = [];
    const log = createLogger({ level: 'debug', destination: (line) => sink.push(JSON.parse(line)) });
    log.info({ apiKey: 'sk-ant-abc123def456' }, 'attempt');
    const last = sink.at(-1) as { apiKey: string };
    expect(last.apiKey).toBe('[REDACTED]');
  });

  it('redacts inside nested objects', () => {
    const sink: unknown[] = [];
    const log = createLogger({ level: 'debug', destination: (line) => sink.push(JSON.parse(line)) });
    log.info({ provider: { token: 'ghp_xxxxxxxxxxxxxxxxxxxx' } }, 'auth');
    const last = sink.at(-1) as { provider: { token: string } };
    expect(last.provider.token).toBe('[REDACTED]');
  });
});
