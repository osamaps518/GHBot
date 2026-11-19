// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfileTableTable extends ProfileTable
    with TableInfo<$ProfileTableTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthMonthMeta = const VerificationMeta(
    'birthMonth',
  );
  @override
  late final GeneratedColumn<int> birthMonth = GeneratedColumn<int>(
    'birth_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Sex, String> sex =
      GeneratedColumn<String>(
        'sex',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Sex>($ProfileTableTable.$convertersex);
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, String>
  activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ActivityLevel>($ProfileTableTable.$converteractivityLevel);
  @override
  late final GeneratedColumnWithTypeConverter<Goal, String> goal =
      GeneratedColumn<String>(
        'goal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Goal>($ProfileTableTable.$convertergoal);
  @override
  List<GeneratedColumn> get $columns => [
    birthYear,
    birthMonth,
    sex,
    heightCm,
    weightKg,
    activityLevel,
    goal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    } else if (isInserting) {
      context.missing(_birthYearMeta);
    }
    if (data.containsKey('birth_month')) {
      context.handle(
        _birthMonthMeta,
        birthMonth.isAcceptableOrUnknown(data['birth_month']!, _birthMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_birthMonthMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      )!,
      birthMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_month'],
      )!,
      sex: $ProfileTableTable.$convertersex.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sex'],
        )!,
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      activityLevel: $ProfileTableTable.$converteractivityLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}activity_level'],
        )!,
      ),
      goal: $ProfileTableTable.$convertergoal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goal'],
        )!,
      ),
    );
  }

  @override
  $ProfileTableTable createAlias(String alias) {
    return $ProfileTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, String, String> $convertersex =
      const EnumNameConverter<Sex>(Sex.values);
  static JsonTypeConverter2<ActivityLevel, String, String>
  $converteractivityLevel = const EnumNameConverter<ActivityLevel>(
    ActivityLevel.values,
  );
  static JsonTypeConverter2<Goal, String, String> $convertergoal =
      const EnumNameConverter<Goal>(Goal.values);
}

class ProfileTableCompanion extends UpdateCompanion<Profile> {
  final Value<int> birthYear;
  final Value<int> birthMonth;
  final Value<Sex> sex;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<ActivityLevel> activityLevel;
  final Value<Goal> goal;
  final Value<int> rowid;
  const ProfileTableCompanion({
    this.birthYear = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.goal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileTableCompanion.insert({
    required int birthYear,
    required int birthMonth,
    required Sex sex,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required Goal goal,
    this.rowid = const Value.absent(),
  }) : birthYear = Value(birthYear),
       birthMonth = Value(birthMonth),
       sex = Value(sex),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       activityLevel = Value(activityLevel),
       goal = Value(goal);
  static Insertable<Profile> custom({
    Expression<int>? birthYear,
    Expression<int>? birthMonth,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? activityLevel,
    Expression<String>? goal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (birthYear != null) 'birth_year': birthYear,
      if (birthMonth != null) 'birth_month': birthMonth,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goal != null) 'goal': goal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileTableCompanion copyWith({
    Value<int>? birthYear,
    Value<int>? birthMonth,
    Value<Sex>? sex,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<ActivityLevel>? activityLevel,
    Value<Goal>? goal,
    Value<int>? rowid,
  }) {
    return ProfileTableCompanion(
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (birthMonth.present) {
      map['birth_month'] = Variable<int>(birthMonth.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(
        $ProfileTableTable.$convertersex.toSql(sex.value),
      );
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(
        $ProfileTableTable.$converteractivityLevel.toSql(activityLevel.value),
      );
    }
    if (goal.present) {
      map['goal'] = Variable<String>(
        $ProfileTableTable.$convertergoal.toSql(goal.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileTableCompanion(')
          ..write('birthYear: $birthYear, ')
          ..write('birthMonth: $birthMonth, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('goal: $goal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TargetsTableTable extends TargetsTable
    with TableInfo<$TargetsTableTable, Targets> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<int> proteinG = GeneratedColumn<int>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<int> fatG = GeneratedColumn<int>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<int> carbsG = GeneratedColumn<int>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maintenanceCaloriesMeta =
      const VerificationMeta('maintenanceCalories');
  @override
  late final GeneratedColumn<int> maintenanceCalories = GeneratedColumn<int>(
    'maintenance_calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMinimumMeta = const VerificationMeta(
    'atMinimum',
  );
  @override
  late final GeneratedColumn<bool> atMinimum = GeneratedColumn<bool>(
    'at_minimum',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("at_minimum" IN (0, 1))',
    ),
  );
  static const VerificationMeta _aboveTestedAgeMeta = const VerificationMeta(
    'aboveTestedAge',
  );
  @override
  late final GeneratedColumn<bool> aboveTestedAge = GeneratedColumn<bool>(
    'above_tested_age',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("above_tested_age" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Goal, String> goal =
      GeneratedColumn<String>(
        'goal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Goal>($TargetsTableTable.$convertergoal);
  static const VerificationMeta _goalAdjustmentPercentMeta =
      const VerificationMeta('goalAdjustmentPercent');
  @override
  late final GeneratedColumn<int> goalAdjustmentPercent = GeneratedColumn<int>(
    'goal_adjustment_percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    calories,
    proteinG,
    fatG,
    carbsG,
    maintenanceCalories,
    atMinimum,
    aboveTestedAge,
    goal,
    goalAdjustmentPercent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Targets> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('maintenance_calories')) {
      context.handle(
        _maintenanceCaloriesMeta,
        maintenanceCalories.isAcceptableOrUnknown(
          data['maintenance_calories']!,
          _maintenanceCaloriesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceCaloriesMeta);
    }
    if (data.containsKey('at_minimum')) {
      context.handle(
        _atMinimumMeta,
        atMinimum.isAcceptableOrUnknown(data['at_minimum']!, _atMinimumMeta),
      );
    } else if (isInserting) {
      context.missing(_atMinimumMeta);
    }
    if (data.containsKey('above_tested_age')) {
      context.handle(
        _aboveTestedAgeMeta,
        aboveTestedAge.isAcceptableOrUnknown(
          data['above_tested_age']!,
          _aboveTestedAgeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aboveTestedAgeMeta);
    }
    if (data.containsKey('goal_adjustment_percent')) {
      context.handle(
        _goalAdjustmentPercentMeta,
        goalAdjustmentPercent.isAcceptableOrUnknown(
          data['goal_adjustment_percent']!,
          _goalAdjustmentPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_goalAdjustmentPercentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Targets map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Targets(
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_g'],
      )!,
      maintenanceCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_calories'],
      )!,
      atMinimum: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}at_minimum'],
      )!,
      aboveTestedAge: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}above_tested_age'],
      )!,
      goal: $TargetsTableTable.$convertergoal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goal'],
        )!,
      ),
      goalAdjustmentPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_adjustment_percent'],
      )!,
    );
  }

  @override
  $TargetsTableTable createAlias(String alias) {
    return $TargetsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Goal, String, String> $convertergoal =
      const EnumNameConverter<Goal>(Goal.values);
}

class TargetsTableCompanion extends UpdateCompanion<Targets> {
  final Value<int> calories;
  final Value<int> proteinG;
  final Value<int> fatG;
  final Value<int> carbsG;
  final Value<int> maintenanceCalories;
  final Value<bool> atMinimum;
  final Value<bool> aboveTestedAge;
  final Value<Goal> goal;
  final Value<int> goalAdjustmentPercent;
  final Value<int> rowid;
  const TargetsTableCompanion({
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.maintenanceCalories = const Value.absent(),
    this.atMinimum = const Value.absent(),
    this.aboveTestedAge = const Value.absent(),
    this.goal = const Value.absent(),
    this.goalAdjustmentPercent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TargetsTableCompanion.insert({
    required int calories,
    required int proteinG,
    required int fatG,
    required int carbsG,
    required int maintenanceCalories,
    required bool atMinimum,
    required bool aboveTestedAge,
    required Goal goal,
    required int goalAdjustmentPercent,
    this.rowid = const Value.absent(),
  }) : calories = Value(calories),
       proteinG = Value(proteinG),
       fatG = Value(fatG),
       carbsG = Value(carbsG),
       maintenanceCalories = Value(maintenanceCalories),
       atMinimum = Value(atMinimum),
       aboveTestedAge = Value(aboveTestedAge),
       goal = Value(goal),
       goalAdjustmentPercent = Value(goalAdjustmentPercent);
  static Insertable<Targets> custom({
    Expression<int>? calories,
    Expression<int>? proteinG,
    Expression<int>? fatG,
    Expression<int>? carbsG,
    Expression<int>? maintenanceCalories,
    Expression<bool>? atMinimum,
    Expression<bool>? aboveTestedAge,
    Expression<String>? goal,
    Expression<int>? goalAdjustmentPercent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (maintenanceCalories != null)
        'maintenance_calories': maintenanceCalories,
      if (atMinimum != null) 'at_minimum': atMinimum,
      if (aboveTestedAge != null) 'above_tested_age': aboveTestedAge,
      if (goal != null) 'goal': goal,
      if (goalAdjustmentPercent != null)
        'goal_adjustment_percent': goalAdjustmentPercent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TargetsTableCompanion copyWith({
    Value<int>? calories,
    Value<int>? proteinG,
    Value<int>? fatG,
    Value<int>? carbsG,
    Value<int>? maintenanceCalories,
    Value<bool>? atMinimum,
    Value<bool>? aboveTestedAge,
    Value<Goal>? goal,
    Value<int>? goalAdjustmentPercent,
    Value<int>? rowid,
  }) {
    return TargetsTableCompanion(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbsG: carbsG ?? this.carbsG,
      maintenanceCalories: maintenanceCalories ?? this.maintenanceCalories,
      atMinimum: atMinimum ?? this.atMinimum,
      aboveTestedAge: aboveTestedAge ?? this.aboveTestedAge,
      goal: goal ?? this.goal,
      goalAdjustmentPercent:
          goalAdjustmentPercent ?? this.goalAdjustmentPercent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<int>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<int>(fatG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<int>(carbsG.value);
    }
    if (maintenanceCalories.present) {
      map['maintenance_calories'] = Variable<int>(maintenanceCalories.value);
    }
    if (atMinimum.present) {
      map['at_minimum'] = Variable<bool>(atMinimum.value);
    }
    if (aboveTestedAge.present) {
      map['above_tested_age'] = Variable<bool>(aboveTestedAge.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(
        $TargetsTableTable.$convertergoal.toSql(goal.value),
      );
    }
    if (goalAdjustmentPercent.present) {
      map['goal_adjustment_percent'] = Variable<int>(
        goalAdjustmentPercent.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TargetsTableCompanion(')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('maintenanceCalories: $maintenanceCalories, ')
          ..write('atMinimum: $atMinimum, ')
          ..write('aboveTestedAge: $aboveTestedAge, ')
          ..write('goal: $goal, ')
          ..write('goalAdjustmentPercent: $goalAdjustmentPercent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfileTableTable profileTable = $ProfileTableTable(this);
  late final $TargetsTableTable targetsTable = $TargetsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profileTable,
    targetsTable,
  ];
}

typedef $$ProfileTableTableCreateCompanionBuilder =
    ProfileTableCompanion Function({
      required int birthYear,
      required int birthMonth,
      required Sex sex,
      required double heightCm,
      required double weightKg,
      required ActivityLevel activityLevel,
      required Goal goal,
      Value<int> rowid,
    });
typedef $$ProfileTableTableUpdateCompanionBuilder =
    ProfileTableCompanion Function({
      Value<int> birthYear,
      Value<int> birthMonth,
      Value<Sex> sex,
      Value<double> heightCm,
      Value<double> weightKg,
      Value<ActivityLevel> activityLevel,
      Value<Goal> goal,
      Value<int> rowid,
    });

class $$ProfileTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Sex, Sex, String> get sex =>
      $composableBuilder(
        column: $table.sex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, String>
  get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Goal, Goal, String> get goal =>
      $composableBuilder(
        column: $table.goal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ProfileTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileTableTable> {
  $$ProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Sex, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, String> get activityLevel =>
      $composableBuilder(
        column: $table.activityLevel,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Goal, String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);
}

class $$ProfileTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileTableTable,
          Profile,
          $$ProfileTableTableFilterComposer,
          $$ProfileTableTableOrderingComposer,
          $$ProfileTableTableAnnotationComposer,
          $$ProfileTableTableCreateCompanionBuilder,
          $$ProfileTableTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfileTableTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfileTableTableTableManager(_$AppDatabase db, $ProfileTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> birthYear = const Value.absent(),
                Value<int> birthMonth = const Value.absent(),
                Value<Sex> sex = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<ActivityLevel> activityLevel = const Value.absent(),
                Value<Goal> goal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileTableCompanion(
                birthYear: birthYear,
                birthMonth: birthMonth,
                sex: sex,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel,
                goal: goal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int birthYear,
                required int birthMonth,
                required Sex sex,
                required double heightCm,
                required double weightKg,
                required ActivityLevel activityLevel,
                required Goal goal,
                Value<int> rowid = const Value.absent(),
              }) => ProfileTableCompanion.insert(
                birthYear: birthYear,
                birthMonth: birthMonth,
                sex: sex,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel,
                goal: goal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileTableTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfileTableTable, Profile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileTableTable,
      Profile,
      $$ProfileTableTableFilterComposer,
      $$ProfileTableTableOrderingComposer,
      $$ProfileTableTableAnnotationComposer,
      $$ProfileTableTableCreateCompanionBuilder,
      $$ProfileTableTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfileTableTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$TargetsTableTableCreateCompanionBuilder =
    TargetsTableCompanion Function({
      required int calories,
      required int proteinG,
      required int fatG,
      required int carbsG,
      required int maintenanceCalories,
      required bool atMinimum,
      required bool aboveTestedAge,
      required Goal goal,
      required int goalAdjustmentPercent,
      Value<int> rowid,
    });
typedef $$TargetsTableTableUpdateCompanionBuilder =
    TargetsTableCompanion Function({
      Value<int> calories,
      Value<int> proteinG,
      Value<int> fatG,
      Value<int> carbsG,
      Value<int> maintenanceCalories,
      Value<bool> atMinimum,
      Value<bool> aboveTestedAge,
      Value<Goal> goal,
      Value<int> goalAdjustmentPercent,
      Value<int> rowid,
    });

class $$TargetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TargetsTableTable> {
  $$TargetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maintenanceCalories => $composableBuilder(
    column: $table.maintenanceCalories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get atMinimum => $composableBuilder(
    column: $table.atMinimum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aboveTestedAge => $composableBuilder(
    column: $table.aboveTestedAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Goal, Goal, String> get goal =>
      $composableBuilder(
        column: $table.goal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get goalAdjustmentPercent => $composableBuilder(
    column: $table.goalAdjustmentPercent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TargetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TargetsTableTable> {
  $$TargetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maintenanceCalories => $composableBuilder(
    column: $table.maintenanceCalories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get atMinimum => $composableBuilder(
    column: $table.atMinimum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aboveTestedAge => $composableBuilder(
    column: $table.aboveTestedAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalAdjustmentPercent => $composableBuilder(
    column: $table.goalAdjustmentPercent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TargetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TargetsTableTable> {
  $$TargetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<int> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<int> get maintenanceCalories => $composableBuilder(
    column: $table.maintenanceCalories,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get atMinimum =>
      $composableBuilder(column: $table.atMinimum, builder: (column) => column);

  GeneratedColumn<bool> get aboveTestedAge => $composableBuilder(
    column: $table.aboveTestedAge,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Goal, String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<int> get goalAdjustmentPercent => $composableBuilder(
    column: $table.goalAdjustmentPercent,
    builder: (column) => column,
  );
}

class $$TargetsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TargetsTableTable,
          Targets,
          $$TargetsTableTableFilterComposer,
          $$TargetsTableTableOrderingComposer,
          $$TargetsTableTableAnnotationComposer,
          $$TargetsTableTableCreateCompanionBuilder,
          $$TargetsTableTableUpdateCompanionBuilder,
          (Targets, BaseReferences<_$AppDatabase, $TargetsTableTable, Targets>),
          Targets,
          PrefetchHooks Function()
        > {
  $$TargetsTableTableTableManager(_$AppDatabase db, $TargetsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TargetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TargetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TargetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> calories = const Value.absent(),
                Value<int> proteinG = const Value.absent(),
                Value<int> fatG = const Value.absent(),
                Value<int> carbsG = const Value.absent(),
                Value<int> maintenanceCalories = const Value.absent(),
                Value<bool> atMinimum = const Value.absent(),
                Value<bool> aboveTestedAge = const Value.absent(),
                Value<Goal> goal = const Value.absent(),
                Value<int> goalAdjustmentPercent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TargetsTableCompanion(
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                maintenanceCalories: maintenanceCalories,
                atMinimum: atMinimum,
                aboveTestedAge: aboveTestedAge,
                goal: goal,
                goalAdjustmentPercent: goalAdjustmentPercent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int calories,
                required int proteinG,
                required int fatG,
                required int carbsG,
                required int maintenanceCalories,
                required bool atMinimum,
                required bool aboveTestedAge,
                required Goal goal,
                required int goalAdjustmentPercent,
                Value<int> rowid = const Value.absent(),
              }) => TargetsTableCompanion.insert(
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                maintenanceCalories: maintenanceCalories,
                atMinimum: atMinimum,
                aboveTestedAge: aboveTestedAge,
                goal: goal,
                goalAdjustmentPercent: goalAdjustmentPercent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TargetsTableTable, Targets>(table),
                  BaseReferences<_$AppDatabase, $TargetsTableTable, Targets>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TargetsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TargetsTableTable,
      Targets,
      $$TargetsTableTableFilterComposer,
      $$TargetsTableTableOrderingComposer,
      $$TargetsTableTableAnnotationComposer,
      $$TargetsTableTableCreateCompanionBuilder,
      $$TargetsTableTableUpdateCompanionBuilder,
      (Targets, BaseReferences<_$AppDatabase, $TargetsTableTable, Targets>),
      Targets,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfileTableTableTableManager get profileTable =>
      $$ProfileTableTableTableManager(_db, _db.profileTable);
  $$TargetsTableTableTableManager get targetsTable =>
      $$TargetsTableTableTableManager(_db, _db.targetsTable);
}
