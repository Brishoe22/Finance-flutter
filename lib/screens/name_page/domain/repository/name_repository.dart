import 'package:application/core/failure/failure.dart';
import 'package:dartz/dartz.dart';


abstract class NameRepository {
  Future<Either<Failure, String>> createAccount(String name, String phoneNumber);
}