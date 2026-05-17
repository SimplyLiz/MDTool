import { describe, it, expect, vi } from 'vitest';
import { createAnthropicProvider } from '../../src/providers/anthropic.js';

describe('AnthropicProvider', () => {
  it('emits delta events then done', async () => {
    const fakeSdk = {
      messages: {
        stream: vi.fn(async function* () {
          yield { type: 'content_block_delta', delta: { type: 'text_delta', text: 'Hel' } };
          yield { type: 'content_block_delta', delta: { type: 'text_delta', text: 'lo' } };
          yield { type: 'message_stop' };
          return { usage: { input_tokens: 10, output_tokens: 2 } };
        }),
      },
    };
    const prov = createAnthropicProvider({ sdk: fakeSdk as any, apiKey: 'x', model: 'claude-opus-4-7' });
    const events: any[] = [];
    for await (const ev of prov.refineStream({ systemPrompt: 's', userSelection: 'u', instruction: 'i' })) {
      events.push(ev);
    }
    expect(events.map((e) => e.kind)).toEqual(['delta', 'delta', 'done']);
    expect(events[0].text).toBe('Hel');
    expect(events[2].tokenUsage).toEqual({ input: 10, output: 2 });
  });

  it('propagates abort as error event', async () => {
    const fakeSdk = {
      messages: {
        stream: vi.fn(async function* () {
          throw Object.assign(new Error('aborted'), { name: 'AbortError' });
        }),
      },
    };
    const prov = createAnthropicProvider({ sdk: fakeSdk as any, apiKey: 'x', model: 'claude-opus-4-7' });
    const events: any[] = [];
    const ac = new AbortController();
    ac.abort();
    for await (const ev of prov.refineStream({ systemPrompt: 's', userSelection: 'u', instruction: 'i', abort: ac.signal })) {
      events.push(ev);
    }
    expect(events[0].kind).toBe('error');
    expect(events[0].recoverable).toBe(true);
  });
});
