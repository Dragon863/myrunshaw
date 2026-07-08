import 'api/api_core.dart';
import 'api/api_auth.dart';
import 'api/api_friends.dart';
import 'api/api_timetable.dart';
import 'api/api_bus.dart';
import 'api/api_payments.dart';

export 'api/api_core.dart' show AccountStatus;

class BaseAPI extends ApiCore
    with ApiFriends, ApiTimetable, ApiAuth, ApiBus, ApiPayments {
  BaseAPI() {
    loadUser();
  }
}
