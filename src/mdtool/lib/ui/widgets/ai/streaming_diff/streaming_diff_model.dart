enum BlockStatus { streaming, streamed, accepted, rejected }

class StreamingBlock {
  final int idx;
  final String originalText;
  final String newText;
  final BlockStatus status;
  const StreamingBlock({
    required this.idx,
    required this.originalText,
    required this.newText,
    required this.status,
  });

  StreamingBlock copy({String? newText, BlockStatus? status}) => StreamingBlock(
    idx: idx,
    originalText: originalText,
    newText: newText ?? this.newText,
    status: status ?? this.status,
  );
}

class StreamingDiffState {
  final String opId;
  final List<StreamingBlock> blocks;
  final bool isFullyStreamed;
  final String? error;
  const StreamingDiffState({
    required this.opId,
    required this.blocks,
    required this.isFullyStreamed,
    this.error,
  });

  factory StreamingDiffState.start({required String opId, required String originalText}) {
    return StreamingDiffState(
      opId: opId,
      blocks: [StreamingBlock(idx: 0, originalText: originalText, newText: '', status: BlockStatus.streaming)],
      isFullyStreamed: false,
    );
  }

  StreamingDiffState applyDelta({required int blockIdx, required String deltaType, required String text}) {
    // For Phase 1 the sidecar emits only `deltaType: "add"`; `del` is the original above.
    final newBlocks = [...blocks];
    while (newBlocks.length <= blockIdx) {
      newBlocks.add(StreamingBlock(idx: newBlocks.length, originalText: '', newText: '', status: BlockStatus.streaming));
    }
    final b = newBlocks[blockIdx];
    if (deltaType == 'add') {
      newBlocks[blockIdx] = b.copy(newText: b.newText + text);
    }
    return StreamingDiffState(opId: opId, blocks: newBlocks, isFullyStreamed: isFullyStreamed);
  }

  StreamingDiffState markComplete({required int totalBlocks}) {
    final newBlocks = [
      for (final b in blocks)
        b.status == BlockStatus.streaming ? b.copy(status: BlockStatus.streamed) : b
    ];
    return StreamingDiffState(opId: opId, blocks: newBlocks, isFullyStreamed: true);
  }

  StreamingDiffState markError(String msg) {
    return StreamingDiffState(opId: opId, blocks: blocks, isFullyStreamed: true, error: msg);
  }

  StreamingDiffState accept({required int blockIdx}) {
    final newBlocks = [...blocks];
    newBlocks[blockIdx] = blocks[blockIdx].copy(status: BlockStatus.accepted);
    return StreamingDiffState(opId: opId, blocks: newBlocks, isFullyStreamed: isFullyStreamed);
  }

  StreamingDiffState reject({required int blockIdx}) {
    final newBlocks = [...blocks];
    newBlocks[blockIdx] = blocks[blockIdx].copy(status: BlockStatus.rejected);
    return StreamingDiffState(opId: opId, blocks: newBlocks, isFullyStreamed: isFullyStreamed);
  }

  /// Concatenates the final text after all blocks have been decided.
  String get committedText => blocks.map((b) {
    switch (b.status) {
      case BlockStatus.accepted: return b.newText;
      case BlockStatus.rejected: return b.originalText;
      case BlockStatus.streamed: return b.newText;   // default = accept if user didn't choose
      case BlockStatus.streaming: return b.originalText;
    }
  }).join();
}
