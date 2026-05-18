import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/ui/widgets/ai/streaming_diff/streaming_diff_model.dart';

void main() {
  test('appends delta text to current block', () {
    var m = StreamingDiffState.start(opId: 'x', originalText: 'old');
    m = m.applyDelta(blockIdx: 0, deltaType: 'add', text: 'Hel');
    m = m.applyDelta(blockIdx: 0, deltaType: 'add', text: 'lo');
    expect(m.blocks.length, 1);
    expect(m.blocks[0].newText, 'Hello');
    expect(m.blocks[0].originalText, 'old');
    expect(m.blocks[0].status, BlockStatus.streaming);
  });

  test('marks block complete on done', () {
    var m = StreamingDiffState.start(opId: 'x', originalText: 'old');
    m = m.applyDelta(blockIdx: 0, deltaType: 'add', text: 'New');
    m = m.markComplete(totalBlocks: 1);
    expect(m.blocks[0].status, BlockStatus.streamed);
    expect(m.isFullyStreamed, true);
  });

  test('accept marks block accepted and computes committed text', () {
    var m = StreamingDiffState.start(opId: 'x', originalText: 'a b c');
    m = m.applyDelta(blockIdx: 0, deltaType: 'add', text: 'A B C');
    m = m.markComplete(totalBlocks: 1);
    m = m.accept(blockIdx: 0);
    expect(m.blocks[0].status, BlockStatus.accepted);
    expect(m.committedText, 'A B C');
  });

  test('reject keeps original text in committed output', () {
    var m = StreamingDiffState.start(opId: 'x', originalText: 'a b c');
    m = m.applyDelta(blockIdx: 0, deltaType: 'add', text: 'X');
    m = m.markComplete(totalBlocks: 1);
    m = m.reject(blockIdx: 0);
    expect(m.committedText, 'a b c');
  });
}
