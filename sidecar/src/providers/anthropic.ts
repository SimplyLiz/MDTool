import Anthropic from '@anthropic-ai/sdk';
import type { ProviderClient, RefineRequest, StreamEvent } from './types.js';

export interface AnthropicConfig {
  apiKey: string;
  model?: string;
  /** Inject a fake SDK in tests. */
  sdk?: Pick<Anthropic, 'messages'>;
}

const PROMPT_VERSION = 'v1.0';

export function createAnthropicProvider(cfg: AnthropicConfig): ProviderClient {
  const client = cfg.sdk ?? new Anthropic({ apiKey: cfg.apiKey });
  const model = cfg.model ?? 'claude-opus-4-7';

  async function* refineStream(req: RefineRequest): AsyncIterable<StreamEvent> {
    try {
      const stream = (client as any).messages.stream(
        {
          model,
          max_tokens: 2048,
          system: [
            {
              type: 'text',
              text: `${req.systemPrompt}\n\nPrompt version: ${PROMPT_VERSION}`,
              cache_control: { type: 'ephemeral' },
            },
          ],
          messages: [
            {
              role: 'user',
              content: `Operation: ${req.instruction}\n\n---\n${req.userSelection}`,
            },
          ],
        },
        { signal: req.abort },
      );

      let usage = { input: 0, output: 0 };
      for await (const ev of stream as AsyncIterable<any>) {
        if (ev.type === 'content_block_delta' && ev.delta?.type === 'text_delta') {
          yield { kind: 'delta', text: ev.delta.text };
        } else if (ev.type === 'message_delta' && ev.usage) {
          usage = {
            input: ev.usage.input_tokens ?? usage.input,
            output: ev.usage.output_tokens ?? usage.output,
          };
        } else if (ev.type === 'message_stop') {
          yield { kind: 'done', tokenUsage: usage, cost: estimateCost(usage, model) };
        }
      }
    } catch (err: any) {
      const aborted = err?.name === 'AbortError' || req.abort?.aborted === true;
      yield {
        kind: 'error',
        message: err?.message ?? String(err),
        recoverable: aborted,
      };
    }
  }

  return { refineStream };
}

function estimateCost(usage: { input: number; output: number }, _model: string): number {
  // Placeholder constants; real per-model pricing lives in a future settings adapter.
  return usage.input * 0.000015 + usage.output * 0.000075;
}
