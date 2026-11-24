import '../auth/auth_session.dart';
import 'food.dart';

class FoodsApi {
  const FoodsApi(this._session);

  final AuthSession _session;

  /// The server's best matches for [query], in Arabic or English
  /// (docs/decisions.md, 29).
  Future<List<Food>> search(String query) => _session.getList(
    '/foods?q=${Uri.encodeQueryComponent(query)}',
    Food.fromJson,
  );
}
