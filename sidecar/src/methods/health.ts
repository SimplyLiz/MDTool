import pkg from '../../package.json' with { type: 'json' };

export interface SourceStatus { id: string; ok: boolean; reason?: string; }
export interface HealthResult { ok: boolean; version: string; sources: SourceStatus[]; }

export async function health(_params?: unknown): Promise<HealthResult> {
  // Phase 1: no external sources registered yet; the array is intentionally empty.
  // Phase 2+ will push to this from a Source registry.
  return { ok: true, version: (pkg as { version: string }).version, sources: [] };
}
