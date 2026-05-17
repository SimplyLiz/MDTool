import { randomUUID } from 'node:crypto';

export class OpRegistry {
  private map = new Map<string, AbortController>();

  start(): { opId: string; signal: AbortSignal } {
    const opId = randomUUID();
    const ac = new AbortController();
    this.map.set(opId, ac);
    return { opId, signal: ac.signal };
  }

  cancel(opId: string): boolean {
    const ac = this.map.get(opId);
    if (!ac) return false;
    ac.abort();
    this.map.delete(opId);
    return true;
  }

  finish(opId: string): void { this.map.delete(opId); }
}
