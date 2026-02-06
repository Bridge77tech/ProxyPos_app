import 'package:hive_ce/hive.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';

@GenerateAdapters([
  AdapterSpec<APUserModel>()
])

part 'hive_adapters.g.dart';