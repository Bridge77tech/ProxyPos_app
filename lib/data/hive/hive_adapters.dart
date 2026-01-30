import 'package:hive_ce/hive.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';

import '../../features/auth/data/model/token_model.dart';

@GenerateAdapters([
  AdapterSpec<Token>(),
  AdapterSpec<UserToken>(),
])

part 'hive_adapters.g.dart';