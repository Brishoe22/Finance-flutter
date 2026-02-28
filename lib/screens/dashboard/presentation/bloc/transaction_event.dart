import 'package:application/screens/dashboard/domain/entity/transaction_entity.dart';

abstract class TransactionEvent {}

// Load all transactions
class LoadTransactionsEvent extends TransactionEvent {}

// Add a new transaction
class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  AddTransactionEvent(this.transaction);
}

// Soft delete a transaction
class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  DeleteTransactionEvent(this.id);
}

// Sync unsynced transactions
class SyncTransactionsEvent extends TransactionEvent {}

// Temporary UI: Change transaction type in AddTransactionSheet
class TempTransactionTypeChangedEvent extends TransactionEvent {
  final String type; // "debit" or "credit"
  TempTransactionTypeChangedEvent(this.type);
}

// Temporary UI: Select category in AddTransactionSheet
class TempCategorySelectedEvent extends TransactionEvent {
  final String categoryId;
  TempCategorySelectedEvent(this.categoryId);
}