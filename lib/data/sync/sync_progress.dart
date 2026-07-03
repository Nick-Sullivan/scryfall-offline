/// Progress events emitted by the sync pipeline, rendered by the
/// onboarding/update screens.
sealed class SyncProgress {
  const SyncProgress();
}

class SyncChecking extends SyncProgress {
  const SyncChecking();
}

class SyncDownloading extends SyncProgress {
  final String file; // 'cards' | 'rulings'
  final int receivedBytes;
  final int? totalBytes; // null when the server omits Content-Length

  const SyncDownloading(this.file, this.receivedBytes, this.totalBytes);

  double? get fraction =>
      totalBytes == null || totalBytes == 0 ? null : receivedBytes / totalBytes!;
}

class SyncIngesting extends SyncProgress {
  final String file; // 'cards' | 'rulings'
  final int processed;
  final int approxTotal;

  const SyncIngesting(this.file, this.processed, this.approxTotal);
}

class SyncFinalizing extends SyncProgress {
  const SyncFinalizing();
}

class SyncSwapping extends SyncProgress {
  const SyncSwapping();
}

class SyncDone extends SyncProgress {
  final int cards;
  final int prints;

  const SyncDone(this.cards, this.prints);
}

class SyncFailed extends SyncProgress {
  final String message;

  const SyncFailed(this.message);
}
