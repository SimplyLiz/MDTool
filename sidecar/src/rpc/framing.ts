export function encodeFrame(msg: unknown): Buffer {
  return Buffer.from(JSON.stringify(msg) + '\n', 'utf8');
}

export class FrameDecoder {
  private buf = '';

  push(chunk: Buffer): unknown[] {
    this.buf += chunk.toString('utf8');
    const out: unknown[] = [];
    let idx: number;
    while ((idx = this.buf.indexOf('\n')) >= 0) {
      const line = this.buf.slice(0, idx);
      this.buf = this.buf.slice(idx + 1);
      const trimmed = line.trim();
      if (!trimmed) continue;
      out.push(JSON.parse(trimmed));
    }
    return out;
  }
}
