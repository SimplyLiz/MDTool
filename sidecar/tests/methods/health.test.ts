import { describe, it, expect } from 'vitest';
import { health } from '../../src/methods/health.js';

describe('health method', () => {
  it('returns ok with version', async () => {
    const out = await health({});
    expect(out.ok).toBe(true);
    expect(out.version).toMatch(/^\d+\.\d+\.\d+$/);
    expect(Array.isArray(out.sources)).toBe(true);
  });
});
