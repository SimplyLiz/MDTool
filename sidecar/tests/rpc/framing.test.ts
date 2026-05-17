import { describe, it, expect } from 'vitest';
import { FrameDecoder, encodeFrame } from '../../src/rpc/framing.js';

describe('framing', () => {
  it('encodes a message with trailing newline', () => {
    const out = encodeFrame({ jsonrpc: '2.0', id: 1, method: 'ping' });
    expect(out.toString('utf8')).toBe('{"jsonrpc":"2.0","id":1,"method":"ping"}\n');
  });

  it('decodes one message split across two writes', () => {
    const dec = new FrameDecoder();
    const a = dec.push(Buffer.from('{"jsonrpc":"2.0"'));
    expect(a).toEqual([]);
    const b = dec.push(Buffer.from(',"id":2,"method":"x"}\n'));
    expect(b).toEqual([{ jsonrpc: '2.0', id: 2, method: 'x' }]);
  });

  it('decodes two messages in one write', () => {
    const dec = new FrameDecoder();
    const msgs = dec.push(Buffer.from('{"id":1}\n{"id":2}\n'));
    expect(msgs).toEqual([{ id: 1 }, { id: 2 }]);
  });

  it('skips empty lines', () => {
    const dec = new FrameDecoder();
    expect(dec.push(Buffer.from('\n\n{"id":3}\n'))).toEqual([{ id: 3 }]);
  });
});
