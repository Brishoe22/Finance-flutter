import 'package:application/screens/dashboard/domain/entity/transaction_entity.dart';
import 'package:application/screens/dashboard/domain/usecase/delete_transactions_usecase.dart';
import 'package:application/screens/dashboard/domain/usecase/get_transactions_usecase.dart';
import 'package:application/screens/dashboard/domain/usecase/sync_transactions_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final SyncTransactionsUseCase syncTransactionsUseCase;
  final DeleteTransactionsUseCase deleteTransactionsUseCase;

  TransactionBloc({
    required this.getTransactionsUseCase,
    required this.syncTransactionsUseCase,
    required this.deleteTransactionsUseCase,
  }) : super(const TransactionState()) {
    // LOAD FROM API
    on<LoadTransactionsEvent>((event, emit) async {
      emit(state.copyWith(status: TransactionStatus.loading));

      final result = await getTransactionsUseCase();

      result.fold(
        (failure) => emit(state.copyWith(
          status: TransactionStatus.error,
          errorMessage: failure.message,
        )),
        (transactions) => emit(state.copyWith(
          status: TransactionStatus.loaded,
          transactions: transactions,
          totalIncome: _calculateIncome(transactions),
          totalExpense: _calculateExpense(transactions),
        )),
      );
    });

    // ADD → LOCAL FIRST
    on<AddTransactionEvent>((event, emit) {
      final updatedList = List<TransactionEntity>.from(state.transactions)
        ..insert(0, event.transaction);

      emit(state.copyWith(
        transactions: updatedList,
        totalIncome: _calculateIncome(updatedList),
        totalExpense: _calculateExpense(updatedList),
      ));
    });

    // DELETE → SOFT DELETE
    on<DeleteTransactionEvent>((event, emit) {
      final updatedList = state.transactions.map((t) {
        if (t.id == event.id) {
          return t.copyWith(isDeleted: true, isSynced: false);
        }
        return t;
      }).toList();

      emit(state.copyWith(
        transactions: updatedList,
        totalIncome: _calculateIncome(updatedList),
        totalExpense: _calculateExpense(updatedList),
      ));
    });

    // SYNC WORKFLOW
    on<SyncTransactionsEvent>((event, emit) async {
      emit(state.copyWith(status: TransactionStatus.syncing));

      final unsyncedTransactions = state.transactions
          .where((t) => !t.isDeleted && !t.isSynced)
          .toList();

      final deletedTransactions =
          state.transactions.where((t) => t.isDeleted).toList();

      // DELETE API FIRST
      if (deletedTransactions.isNotEmpty) {
        final ids = deletedTransactions.map((t) => t.id).toList();
        final deleteResult = await deleteTransactionsUseCase(ids);

        deleteResult.fold(
          (failure) => emit(state.copyWith(
            status: TransactionStatus.error,
            errorMessage: failure.message,
          )),
          (_) {},
        );
      }

      // SYNC ONLY NEW RECORDS
      if (unsyncedTransactions.isEmpty) {
        emit(state.copyWith(status: TransactionStatus.success));
        return;
      }

      final syncResult = await syncTransactionsUseCase(unsyncedTransactions);

      syncResult.fold(
        (failure) => emit(state.copyWith(
          status: TransactionStatus.error,
          errorMessage: failure.message,
        )),
        (_) {
          final updatedList = state.transactions.map((t) {
            if (unsyncedTransactions.any((u) => u.id == t.id)) {
              return t.copyWith(isSynced: true);
            }
            return t;
          }).where((t) => !t.isDeleted).toList();

          emit(state.copyWith(
            status: TransactionStatus.success,
            transactions: updatedList,
            totalIncome: _calculateIncome(updatedList),
            totalExpense: _calculateExpense(updatedList),
          ));
        },
      );
    });

    // TEMP TRANSACTION TYPE CHANGE (replaces setState)
    on<TempTransactionTypeChangedEvent>((event, emit) {
      emit(state.copyWith(tempTransactionType: event.type));
    });

    // TEMP CATEGORY SELECTION (replaces setState)
    on<TempCategorySelectedEvent>((event, emit) {
      emit(state.copyWith(tempCategoryId: event.categoryId));
    });
  }

  double _calculateIncome(List<TransactionEntity> list) {
    return list
        .where((t) => !t.isDeleted)
        .where((t) => t.type.toLowerCase() == "credit")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateExpense(List<TransactionEntity> list) {
    return list
        .where((t) => !t.isDeleted)
        .where((t) => t.type.toLowerCase() == "debit")
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}