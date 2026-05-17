import { describe, it, expect } from 'vitest';
import { createLogger } from '../../src/logging/logger.js';

describe('logger', () => {
  it('redacts known API key shapes', () => {
    const sink: unknown[] = [];
    const log = createLogger({ level: 'debug', destination: (line) => sink.push(JSON.parse(line)) });
    log.info({ apiKey: 'sk-ant-abc123def456' }, 'attempt');
    const last = sink.at(-1) as { apiKey: string };
    expect(last.apiKey).toBe('[REDACTED]');
    const raw = JSON.stringify(sink.at(-1));
    expect(raw).not.toContain('sk-ant-abc123def456');
  });

  it('redacts inside nested objects', () => {
    const sink: unknown[] = [];
    const log = createLogger({ level: 'debug', destination: (line) => sink.push(JSON.parse(line)) });
    log.info({ provider: { token: 'ghp_xxxxxxxxxxxxxxxxxxxx' } }, 'auth');
    const last = sink.at(-1) as { provider: { token: string } };
    expect(last.provider.token).toBe('[REDACTED]');
    const raw = JSON.stringify(sink.at(-1));
    expect(raw).not.toContain('ghp_xxxxxxxxxxxxxxxxxxxx');
  });

  it('respects level config (warn suppresses info)', () => {
    const sink: unknown[] = [];
    const log = createLogger({ level: 'warn', destination: (line) => sink.push(JSON.parse(line)) });
    log.info({}, 'should-be-dropped');
    log.warn({}, 'should-appear');
    expect(sink.length).toBe(1);
    expect((sink[0] as { msg: string }).msg).toBe('should-appear');
  });
});
