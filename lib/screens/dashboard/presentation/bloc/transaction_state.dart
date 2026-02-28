import 'package:application/screens/dashboard/domain/entity/transaction_entity.dart';
import 'package:equatable/equatable.dart';

enum TransactionStatus {
  initial,
  loading,
  loaded,
  syncing,
  success,
  error,
}

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionEntity> transactions;
  final double totalIncome;
  final double totalExpense;
  final String? errorMessage;

  // Temporary UI fields for AddTransactionSheet
  final String? tempTransactionType; 
  final String? tempCategoryId; 

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.errorMessage,
    this.tempTransactionType,
    this.tempCategoryId,
  });

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionEntity>? transactions,
    double? totalIncome,
    double? totalExpense,
    String? errorMessage,
    String? tempTransactionType,
    String? tempCategoryId,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      errorMessage: errorMessage,
      tempTransactionType: tempTransactionType ?? this.tempTransactionType,
      tempCategoryId: tempCategoryId ?? this.tempCategoryId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        totalIncome,
        totalExpense,
        errorMessage,
        tempTransactionType,
        tempCategoryId,
      ];
}