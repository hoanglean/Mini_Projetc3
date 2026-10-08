import 'package:flutter/foundation.dart';
import 'transaction_repository.dart';
import 'transaction_repository_memory.dart' as memory;
import 'transaction_repository_sqlite.dart'
    if (dart.library.js_interop) 'transaction_repository_memory.dart'
    if (dart.library.html) 'transaction_repository_memory.dart' as impl;

/// Factory function using conditional imports and [kIsWeb]
/// to supply the appropriate [TransactionRepository] implementation.
TransactionRepository buildDefaultTransactionRepository() {
  if (kIsWeb) {
    return memory.InMemoryTransactionRepository(
      initialItems: memory.getInitialWebSampleTransactions(),
    );
  }
  return impl.createRepository();
}
