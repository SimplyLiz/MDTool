export type StreamEvent =
  | { kind: 'delta'; text: string }
  | { kind: 'done'; tokenUsage: { input: number; output: number }; cost: number }
  | { kind: 'error'; message: string; recoverable: boolean };

export interface RefineRequest {
  systemPrompt: string;
  userSelection: string;
  instruction: string;       // e.g. "improve clarity"
  abort?: AbortSignal;
}

export interface ProviderClient {
  refineStream(req: RefineRequest): AsyncIterable<StreamEvent>;
}
