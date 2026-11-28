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
  static const VerificationMeta _customMeta = const VerificationMeta('custom');
  @override
  late final GeneratedColumn<bool> custom = GeneratedColumn<bool>(
    'custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("custom" IN (0, 1))',
    ),
  );
  static const VerificationMeta _macrosAdjustedMeta = const VerificationMeta(
    'macrosAdjusted',
  );
  @override
  late final GeneratedColumn<bool> macrosAdjusted = GeneratedColumn<bool>(
    'macros_adjusted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("macros_adjusted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _recommendedCaloriesMeta =
      const VerificationMeta('recommendedCalories');
  @override
  late final GeneratedColumn<int> recommendedCalories = GeneratedColumn<int>(
    'recommended_calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedProteinGMeta =
      const VerificationMeta('recommendedProteinG');
  @override
  late final GeneratedColumn<int> recommendedProteinG = GeneratedColumn<int>(
    'recommended_protein_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedFatGMeta = const VerificationMeta(
    'recommendedFatG',
  );
  @override
  late final GeneratedColumn<int> recommendedFatG = GeneratedColumn<int>(
    'recommended_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedCarbsGMeta = const VerificationMeta(
    'recommendedCarbsG',
  );
  @override
  late final GeneratedColumn<int> recommendedCarbsG = GeneratedColumn<int>(
    'recommended_carbs_g',
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
    custom,
    macrosAdjusted,
    recommendedCalories,
    recommendedProteinG,
    recommendedFatG,
    recommendedCarbsG,
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
    if (data.containsKey('custom')) {
      context.handle(
        _customMeta,
        custom.isAcceptableOrUnknown(data['custom']!, _customMeta),
      );
    } else if (isInserting) {
      context.missing(_customMeta);
    }
    if (data.containsKey('macros_adjusted')) {
      context.handle(
        _macrosAdjustedMeta,
        macrosAdjusted.isAcceptableOrUnknown(
          data['macros_adjusted']!,
          _macrosAdjustedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_macrosAdjustedMeta);
    }
    if (data.containsKey('recommended_calories')) {
      context.handle(
        _recommendedCaloriesMeta,
        recommendedCalories.isAcceptableOrUnknown(
          data['recommended_calories']!,
          _recommendedCaloriesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedCaloriesMeta);
    }
    if (data.containsKey('recommended_protein_g')) {
      context.handle(
        _recommendedProteinGMeta,
        recommendedProteinG.isAcceptableOrUnknown(
          data['recommended_protein_g']!,
          _recommendedProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedProteinGMeta);
    }
    if (data.containsKey('recommended_fat_g')) {
      context.handle(
        _recommendedFatGMeta,
        recommendedFatG.isAcceptableOrUnknown(
          data['recommended_fat_g']!,
          _recommendedFatGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedFatGMeta);
    }
    if (data.containsKey('recommended_carbs_g')) {
      context.handle(
        _recommendedCarbsGMeta,
        recommendedCarbsG.isAcceptableOrUnknown(
          data['recommended_carbs_g']!,
          _recommendedCarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedCarbsGMeta);
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
      custom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom'],
      )!,
      macrosAdjusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}macros_adjusted'],
      )!,
      recommendedCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_calories'],
      )!,
      recommendedProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_protein_g'],
      )!,
      recommendedFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_fat_g'],
      )!,
      recommendedCarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_carbs_g'],
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
  final Value<bool> custom;
  final Value<bool> macrosAdjusted;
  final Value<int> recommendedCalories;
  final Value<int> recommendedProteinG;
  final Value<int> recommendedFatG;
  final Value<int> recommendedCarbsG;
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
    this.custom = const Value.absent(),
    this.macrosAdjusted = const Value.absent(),
    this.recommendedCalories = const Value.absent(),
    this.recommendedProteinG = const Value.absent(),
    this.recommendedFatG = const Value.absent(),
    this.recommendedCarbsG = const Value.absent(),
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
    required bool custom,
    required bool macrosAdjusted,
    required int recommendedCalories,
    required int recommendedProteinG,
    required int recommendedFatG,
    required int recommendedCarbsG,
    this.rowid = const Value.absent(),
  }) : calories = Value(calories),
       proteinG = Value(proteinG),
       fatG = Value(fatG),
       carbsG = Value(carbsG),
       maintenanceCalories = Value(maintenanceCalories),
       atMinimum = Value(atMinimum),
       aboveTestedAge = Value(aboveTestedAge),
       goal = Value(goal),
       goalAdjustmentPercent = Value(goalAdjustmentPercent),
       custom = Value(custom),
       macrosAdjusted = Value(macrosAdjusted),
       recommendedCalories = Value(recommendedCalories),
       recommendedProteinG = Value(recommendedProteinG),
       recommendedFatG = Value(recommendedFatG),
       recommendedCarbsG = Value(recommendedCarbsG);
  static Insertable<Targets> createCustom({
    Expression<int>? calories,
    Expression<int>? proteinG,
    Expression<int>? fatG,
    Expression<int>? carbsG,
    Expression<int>? maintenanceCalories,
    Expression<bool>? atMinimum,
    Expression<bool>? aboveTestedAge,
    Expression<String>? goal,
    Expression<int>? goalAdjustmentPercent,
    Expression<bool>? custom,
    Expression<bool>? macrosAdjusted,
    Expression<int>? recommendedCalories,
    Expression<int>? recommendedProteinG,
    Expression<int>? recommendedFatG,
    Expression<int>? recommendedCarbsG,
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
      if (custom != null) 'custom': custom,
      if (macrosAdjusted != null) 'macros_adjusted': macrosAdjusted,
      if (recommendedCalories != null)
        'recommended_calories': recommendedCalories,
      if (recommendedProteinG != null)
        'recommended_protein_g': recommendedProteinG,
      if (recommendedFatG != null) 'recommended_fat_g': recommendedFatG,
      if (recommendedCarbsG != null) 'recommended_carbs_g': recommendedCarbsG,
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
    Value<bool>? custom,
    Value<bool>? macrosAdjusted,
    Value<int>? recommendedCalories,
    Value<int>? recommendedProteinG,
    Value<int>? recommendedFatG,
    Value<int>? recommendedCarbsG,
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
      custom: custom ?? this.custom,
      macrosAdjusted: macrosAdjusted ?? this.macrosAdjusted,
      recommendedCalories: recommendedCalories ?? this.recommendedCalories,
      recommendedProteinG: recommendedProteinG ?? this.recommendedProteinG,
      recommendedFatG: recommendedFatG ?? this.recommendedFatG,
      recommendedCarbsG: recommendedCarbsG ?? this.recommendedCarbsG,
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
    if (custom.present) {
      map['custom'] = Variable<bool>(custom.value);
    }
    if (macrosAdjusted.present) {
      map['macros_adjusted'] = Variable<bool>(macrosAdjusted.value);
    }
    if (recommendedCalories.present) {
      map['recommended_calories'] = Variable<int>(recommendedCalories.value);
    }
    if (recommendedProteinG.present) {
      map['recommended_protein_g'] = Variable<int>(recommendedProteinG.value);
    }
    if (recommendedFatG.present) {
      map['recommended_fat_g'] = Variable<int>(recommendedFatG.value);
    }
    if (recommendedCarbsG.present) {
      map['recommended_carbs_g'] = Variable<int>(recommendedCarbsG.value);
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
          ..write('custom: $custom, ')
          ..write('macrosAdjusted: $macrosAdjusted, ')
          ..write('recommendedCalories: $recommendedCalories, ')
          ..write('recommendedProteinG: $recommendedProteinG, ')
          ..write('recommendedFatG: $recommendedFatG, ')
          ..write('recommendedCarbsG: $recommendedCarbsG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodTableTable extends FoodTable with TableInfo<$FoodTableTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesPer100gMeta = const VerificationMeta(
    'caloriesPer100g',
  );
  @override
  late final GeneratedColumn<int> caloriesPer100g = GeneratedColumn<int>(
    'calories_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<int> proteinPer100g = GeneratedColumn<int>(
    'protein_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<int> carbsPer100g = GeneratedColumn<int>(
    'carbs_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<int> fatPer100g = GeneratedColumn<int>(
    'fat_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    nameEn,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('calories_per_100g')) {
      context.handle(
        _caloriesPer100gMeta,
        caloriesPer100g.isAcceptableOrUnknown(
          data['calories_per_100g']!,
          _caloriesPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesPer100gMeta);
    }
    if (data.containsKey('protein_per_100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per_100g']!,
          _proteinPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100gMeta);
    }
    if (data.containsKey('carbs_per_100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per_100g']!,
          _carbsPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100gMeta);
    }
    if (data.containsKey('fat_per_100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(
          data['fat_per_100g']!,
          _fatPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatPer100gMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food.fromColumns(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      caloriesPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_per_100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_per_100g'],
      )!,
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_per_100g'],
      )!,
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_per_100g'],
      )!,
    );
  }

  @override
  $FoodTableTable createAlias(String alias) {
    return $FoodTableTable(attachedDatabase, alias);
  }
}

class FoodTableCompanion extends UpdateCompanion<Food> {
  final Value<String> id;
  final Value<String?> nameAr;
  final Value<String?> nameEn;
  final Value<int> caloriesPer100g;
  final Value<int> proteinPer100g;
  final Value<int> carbsPer100g;
  final Value<int> fatPer100g;
  final Value<int> rowid;
  const FoodTableCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodTableCompanion.insert({
    required String id,
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    required int caloriesPer100g,
    required int proteinPer100g,
    required int carbsPer100g,
    required int fatPer100g,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caloriesPer100g = Value(caloriesPer100g),
       proteinPer100g = Value(proteinPer100g),
       carbsPer100g = Value(carbsPer100g),
       fatPer100g = Value(fatPer100g);
  static Insertable<Food> custom({
    Expression<String>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<int>? caloriesPer100g,
    Expression<int>? proteinPer100g,
    Expression<int>? carbsPer100g,
    Expression<int>? fatPer100g,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (caloriesPer100g != null) 'calories_per_100g': caloriesPer100g,
      if (proteinPer100g != null) 'protein_per_100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per_100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per_100g': fatPer100g,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? nameAr,
    Value<String?>? nameEn,
    Value<int>? caloriesPer100g,
    Value<int>? proteinPer100g,
    Value<int>? carbsPer100g,
    Value<int>? fatPer100g,
    Value<int>? rowid,
  }) {
    return FoodTableCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (caloriesPer100g.present) {
      map['calories_per_100g'] = Variable<int>(caloriesPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per_100g'] = Variable<int>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per_100g'] = Variable<int>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per_100g'] = Variable<int>(fatPer100g.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodTableCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodLogEntryTableTable extends FoodLogEntryTable
    with TableInfo<$FoodLogEntryTableTable, FoodLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodLogEntryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Meal, String> meal =
      GeneratedColumn<String>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Meal>($FoodLogEntryTableTable.$convertermeal);
  static const VerificationMeta _mealNameMeta = const VerificationMeta(
    'mealName',
  );
  @override
  late final GeneratedColumn<String> mealName = GeneratedColumn<String>(
    'meal_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diaryDayMeta = const VerificationMeta(
    'diaryDay',
  );
  @override
  late final GeneratedColumn<String> diaryDay = GeneratedColumn<String>(
    'diary_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<int> grams = GeneratedColumn<int>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesPer100gMeta = const VerificationMeta(
    'caloriesPer100g',
  );
  @override
  late final GeneratedColumn<int> caloriesPer100g = GeneratedColumn<int>(
    'calories_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<int> proteinPer100g = GeneratedColumn<int>(
    'protein_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<int> carbsPer100g = GeneratedColumn<int>(
    'carbs_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<int> fatPer100g = GeneratedColumn<int>(
    'fat_per_100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sentRevisionMeta = const VerificationMeta(
    'sentRevision',
  );
  @override
  late final GeneratedColumn<int> sentRevision = GeneratedColumn<int>(
    'sent_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _refusedMeta = const VerificationMeta(
    'refused',
  );
  @override
  late final GeneratedColumn<bool> refused = GeneratedColumn<bool>(
    'refused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("refused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    foodId,
    meal,
    mealName,
    diaryDay,
    grams,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    calories,
    protein,
    carbs,
    fat,
    loggedAt,
    revision,
    sentRevision,
    deleted,
    refused,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('meal_name')) {
      context.handle(
        _mealNameMeta,
        mealName.isAcceptableOrUnknown(data['meal_name']!, _mealNameMeta),
      );
    }
    if (data.containsKey('diary_day')) {
      context.handle(
        _diaryDayMeta,
        diaryDay.isAcceptableOrUnknown(data['diary_day']!, _diaryDayMeta),
      );
    } else if (isInserting) {
      context.missing(_diaryDayMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('calories_per_100g')) {
      context.handle(
        _caloriesPer100gMeta,
        caloriesPer100g.isAcceptableOrUnknown(
          data['calories_per_100g']!,
          _caloriesPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesPer100gMeta);
    }
    if (data.containsKey('protein_per_100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per_100g']!,
          _proteinPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100gMeta);
    }
    if (data.containsKey('carbs_per_100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per_100g']!,
          _carbsPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100gMeta);
    }
    if (data.containsKey('fat_per_100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(
          data['fat_per_100g']!,
          _fatPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatPer100gMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sent_revision')) {
      context.handle(
        _sentRevisionMeta,
        sentRevision.isAcceptableOrUnknown(
          data['sent_revision']!,
          _sentRevisionMeta,
        ),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('refused')) {
      context.handle(
        _refusedMeta,
        refused.isAcceptableOrUnknown(data['refused']!, _refusedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodLogEntry.fromColumns(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      meal: $FoodLogEntryTableTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal'],
        )!,
      ),
      mealName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_name'],
      ),
      diaryDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diary_day'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grams'],
      )!,
      caloriesPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_per_100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_per_100g'],
      )!,
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_per_100g'],
      )!,
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_per_100g'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      sentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_revision'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      refused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}refused'],
      )!,
    );
  }

  @override
  $FoodLogEntryTableTable createAlias(String alias) {
    return $FoodLogEntryTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Meal, String, String> $convertermeal =
      const EnumNameConverter<Meal>(Meal.values);
}

class FoodLogEntryTableCompanion extends UpdateCompanion<FoodLogEntry> {
  final Value<String> id;
  final Value<String> foodId;
  final Value<Meal> meal;
  final Value<String?> mealName;
  final Value<String> diaryDay;
  final Value<int> grams;
  final Value<int> caloriesPer100g;
  final Value<int> proteinPer100g;
  final Value<int> carbsPer100g;
  final Value<int> fatPer100g;
  final Value<int> calories;
  final Value<int> protein;
  final Value<int> carbs;
  final Value<int> fat;
  final Value<DateTime> loggedAt;
  final Value<int> revision;
  final Value<int> sentRevision;
  final Value<bool> deleted;
  final Value<bool> refused;
  final Value<int> rowid;
  const FoodLogEntryTableCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.meal = const Value.absent(),
    this.mealName = const Value.absent(),
    this.diaryDay = const Value.absent(),
    this.grams = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.sentRevision = const Value.absent(),
    this.deleted = const Value.absent(),
    this.refused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodLogEntryTableCompanion.insert({
    required String id,
    required String foodId,
    required Meal meal,
    this.mealName = const Value.absent(),
    required String diaryDay,
    required int grams,
    required int caloriesPer100g,
    required int proteinPer100g,
    required int carbsPer100g,
    required int fatPer100g,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required DateTime loggedAt,
    this.revision = const Value.absent(),
    this.sentRevision = const Value.absent(),
    this.deleted = const Value.absent(),
    this.refused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       foodId = Value(foodId),
       meal = Value(meal),
       diaryDay = Value(diaryDay),
       grams = Value(grams),
       caloriesPer100g = Value(caloriesPer100g),
       proteinPer100g = Value(proteinPer100g),
       carbsPer100g = Value(carbsPer100g),
       fatPer100g = Value(fatPer100g),
       calories = Value(calories),
       protein = Value(protein),
       carbs = Value(carbs),
       fat = Value(fat),
       loggedAt = Value(loggedAt);
  static Insertable<FoodLogEntry> custom({
    Expression<String>? id,
    Expression<String>? foodId,
    Expression<String>? meal,
    Expression<String>? mealName,
    Expression<String>? diaryDay,
    Expression<int>? grams,
    Expression<int>? caloriesPer100g,
    Expression<int>? proteinPer100g,
    Expression<int>? carbsPer100g,
    Expression<int>? fatPer100g,
    Expression<int>? calories,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
    Expression<DateTime>? loggedAt,
    Expression<int>? revision,
    Expression<int>? sentRevision,
    Expression<bool>? deleted,
    Expression<bool>? refused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (meal != null) 'meal': meal,
      if (mealName != null) 'meal_name': mealName,
      if (diaryDay != null) 'diary_day': diaryDay,
      if (grams != null) 'grams': grams,
      if (caloriesPer100g != null) 'calories_per_100g': caloriesPer100g,
      if (proteinPer100g != null) 'protein_per_100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per_100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per_100g': fatPer100g,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (revision != null) 'revision': revision,
      if (sentRevision != null) 'sent_revision': sentRevision,
      if (deleted != null) 'deleted': deleted,
      if (refused != null) 'refused': refused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodLogEntryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? foodId,
    Value<Meal>? meal,
    Value<String?>? mealName,
    Value<String>? diaryDay,
    Value<int>? grams,
    Value<int>? caloriesPer100g,
    Value<int>? proteinPer100g,
    Value<int>? carbsPer100g,
    Value<int>? fatPer100g,
    Value<int>? calories,
    Value<int>? protein,
    Value<int>? carbs,
    Value<int>? fat,
    Value<DateTime>? loggedAt,
    Value<int>? revision,
    Value<int>? sentRevision,
    Value<bool>? deleted,
    Value<bool>? refused,
    Value<int>? rowid,
  }) {
    return FoodLogEntryTableCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      meal: meal ?? this.meal,
      mealName: mealName ?? this.mealName,
      diaryDay: diaryDay ?? this.diaryDay,
      grams: grams ?? this.grams,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      loggedAt: loggedAt ?? this.loggedAt,
      revision: revision ?? this.revision,
      sentRevision: sentRevision ?? this.sentRevision,
      deleted: deleted ?? this.deleted,
      refused: refused ?? this.refused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(
        $FoodLogEntryTableTable.$convertermeal.toSql(meal.value),
      );
    }
    if (mealName.present) {
      map['meal_name'] = Variable<String>(mealName.value);
    }
    if (diaryDay.present) {
      map['diary_day'] = Variable<String>(diaryDay.value);
    }
    if (grams.present) {
      map['grams'] = Variable<int>(grams.value);
    }
    if (caloriesPer100g.present) {
      map['calories_per_100g'] = Variable<int>(caloriesPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per_100g'] = Variable<int>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per_100g'] = Variable<int>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per_100g'] = Variable<int>(fatPer100g.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (sentRevision.present) {
      map['sent_revision'] = Variable<int>(sentRevision.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (refused.present) {
      map['refused'] = Variable<bool>(refused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogEntryTableCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('meal: $meal, ')
          ..write('mealName: $mealName, ')
          ..write('diaryDay: $diaryDay, ')
          ..write('grams: $grams, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('revision: $revision, ')
          ..write('sentRevision: $sentRevision, ')
          ..write('deleted: $deleted, ')
          ..write('refused: $refused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PullMarkerTableTable extends PullMarkerTable
    with TableInfo<$PullMarkerTableTable, PullMarkerTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullMarkerTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _markerMeta = const VerificationMeta('marker');
  @override
  late final GeneratedColumn<String> marker = GeneratedColumn<String>(
    'marker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [marker];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_marker';
  @override
  VerificationContext validateIntegrity(
    Insertable<PullMarkerTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('marker')) {
      context.handle(
        _markerMeta,
        marker.isAcceptableOrUnknown(data['marker']!, _markerMeta),
      );
    } else if (isInserting) {
      context.missing(_markerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PullMarkerTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullMarkerTableData(
      marker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marker'],
      )!,
    );
  }

  @override
  $PullMarkerTableTable createAlias(String alias) {
    return $PullMarkerTableTable(attachedDatabase, alias);
  }
}

class PullMarkerTableData extends DataClass
    implements Insertable<PullMarkerTableData> {
  /// Kept exactly as the server sent it: the phone never reads it.
  final String marker;
  const PullMarkerTableData({required this.marker});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['marker'] = Variable<String>(marker);
    return map;
  }

  PullMarkerTableCompanion toCompanion(bool nullToAbsent) {
    return PullMarkerTableCompanion(marker: Value(marker));
  }

  factory PullMarkerTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullMarkerTableData(
      marker: serializer.fromJson<String>(json['marker']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'marker': serializer.toJson<String>(marker)};
  }

  PullMarkerTableData copyWith({String? marker}) =>
      PullMarkerTableData(marker: marker ?? this.marker);
  PullMarkerTableData copyWithCompanion(PullMarkerTableCompanion data) {
    return PullMarkerTableData(
      marker: data.marker.present ? data.marker.value : this.marker,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullMarkerTableData(')
          ..write('marker: $marker')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => marker.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullMarkerTableData && other.marker == this.marker);
}

class PullMarkerTableCompanion extends UpdateCompanion<PullMarkerTableData> {
  final Value<String> marker;
  final Value<int> rowid;
  const PullMarkerTableCompanion({
    this.marker = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PullMarkerTableCompanion.insert({
    required String marker,
    this.rowid = const Value.absent(),
  }) : marker = Value(marker);
  static Insertable<PullMarkerTableData> custom({
    Expression<String>? marker,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (marker != null) 'marker': marker,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PullMarkerTableCompanion copyWith({
    Value<String>? marker,
    Value<int>? rowid,
  }) {
    return PullMarkerTableCompanion(
      marker: marker ?? this.marker,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (marker.present) {
      map['marker'] = Variable<String>(marker.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullMarkerTableCompanion(')
          ..write('marker: $marker, ')
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
  late final $FoodTableTable foodTable = $FoodTableTable(this);
  late final $FoodLogEntryTableTable foodLogEntryTable =
      $FoodLogEntryTableTable(this);
  late final $PullMarkerTableTable pullMarkerTable = $PullMarkerTableTable(
    this,
  );
  late final Index foodLogEntriesDiaryDay = Index(
    'food_log_entries_diary_day',
    'CREATE INDEX food_log_entries_diary_day ON food_log_entries (diary_day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profileTable,
    targetsTable,
    foodTable,
    foodLogEntryTable,
    pullMarkerTable,
    foodLogEntriesDiaryDay,
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
      required bool custom,
      required bool macrosAdjusted,
      required int recommendedCalories,
      required int recommendedProteinG,
      required int recommendedFatG,
      required int recommendedCarbsG,
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
      Value<bool> custom,
      Value<bool> macrosAdjusted,
      Value<int> recommendedCalories,
      Value<int> recommendedProteinG,
      Value<int> recommendedFatG,
      Value<int> recommendedCarbsG,
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

  ColumnFilters<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get macrosAdjusted => $composableBuilder(
    column: $table.macrosAdjusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedCalories => $composableBuilder(
    column: $table.recommendedCalories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedProteinG => $composableBuilder(
    column: $table.recommendedProteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedFatG => $composableBuilder(
    column: $table.recommendedFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedCarbsG => $composableBuilder(
    column: $table.recommendedCarbsG,
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

  ColumnOrderings<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get macrosAdjusted => $composableBuilder(
    column: $table.macrosAdjusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedCalories => $composableBuilder(
    column: $table.recommendedCalories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedProteinG => $composableBuilder(
    column: $table.recommendedProteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedFatG => $composableBuilder(
    column: $table.recommendedFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedCarbsG => $composableBuilder(
    column: $table.recommendedCarbsG,
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

  GeneratedColumn<bool> get custom =>
      $composableBuilder(column: $table.custom, builder: (column) => column);

  GeneratedColumn<bool> get macrosAdjusted => $composableBuilder(
    column: $table.macrosAdjusted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedCalories => $composableBuilder(
    column: $table.recommendedCalories,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedProteinG => $composableBuilder(
    column: $table.recommendedProteinG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedFatG => $composableBuilder(
    column: $table.recommendedFatG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedCarbsG => $composableBuilder(
    column: $table.recommendedCarbsG,
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
                Value<bool> custom = const Value.absent(),
                Value<bool> macrosAdjusted = const Value.absent(),
                Value<int> recommendedCalories = const Value.absent(),
                Value<int> recommendedProteinG = const Value.absent(),
                Value<int> recommendedFatG = const Value.absent(),
                Value<int> recommendedCarbsG = const Value.absent(),
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
                custom: custom,
                macrosAdjusted: macrosAdjusted,
                recommendedCalories: recommendedCalories,
                recommendedProteinG: recommendedProteinG,
                recommendedFatG: recommendedFatG,
                recommendedCarbsG: recommendedCarbsG,
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
                required bool custom,
                required bool macrosAdjusted,
                required int recommendedCalories,
                required int recommendedProteinG,
                required int recommendedFatG,
                required int recommendedCarbsG,
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
                custom: custom,
                macrosAdjusted: macrosAdjusted,
                recommendedCalories: recommendedCalories,
                recommendedProteinG: recommendedProteinG,
                recommendedFatG: recommendedFatG,
                recommendedCarbsG: recommendedCarbsG,
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
typedef $$FoodTableTableCreateCompanionBuilder = FoodTableCompanion Function({
  required String id,
  Value<String?> nameAr,
  Value<String?> nameEn,
  required int caloriesPer100g,
  required int proteinPer100g,
  required int carbsPer100g,
  required int fatPer100g,
  Value<int> rowid,
});
typedef $$FoodTableTableUpdateCompanionBuilder = FoodTableCompanion Function({
  Value<String> id,
  Value<String?> nameAr,
  Value<String?> nameEn,
  Value<int> caloriesPer100g,
  Value<int> proteinPer100g,
  Value<int> carbsPer100g,
  Value<int> fatPer100g,
  Value<int> rowid,
});

class $$FoodTableTableFilterComposer
    extends Composer<_$AppDatabase, $FoodTableTable> {
  $$FoodTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodTableTable> {
  $$FoodTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodTableTable> {
  $$FoodTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );
}

class $$FoodTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodTableTable,
          Food,
          $$FoodTableTableFilterComposer,
          $$FoodTableTableOrderingComposer,
          $$FoodTableTableAnnotationComposer,
          $$FoodTableTableCreateCompanionBuilder,
          $$FoodTableTableUpdateCompanionBuilder,
          (Food, BaseReferences<_$AppDatabase, $FoodTableTable, Food>),
          Food,
          PrefetchHooks Function()
        > {
  $$FoodTableTableTableManager(_$AppDatabase db, $FoodTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<int> caloriesPer100g = const Value.absent(),
                Value<int> proteinPer100g = const Value.absent(),
                Value<int> carbsPer100g = const Value.absent(),
                Value<int> fatPer100g = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodTableCompanion(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> nameAr = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                required int caloriesPer100g,
                required int proteinPer100g,
                required int carbsPer100g,
                required int fatPer100g,
                Value<int> rowid = const Value.absent(),
              }) => FoodTableCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodTableTable, Food>(table),
                  BaseReferences<_$AppDatabase, $FoodTableTable, Food>(
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

typedef $$FoodTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodTableTable,
      Food,
      $$FoodTableTableFilterComposer,
      $$FoodTableTableOrderingComposer,
      $$FoodTableTableAnnotationComposer,
      $$FoodTableTableCreateCompanionBuilder,
      $$FoodTableTableUpdateCompanionBuilder,
      (Food, BaseReferences<_$AppDatabase, $FoodTableTable, Food>),
      Food,
      PrefetchHooks Function()
    >;
typedef $$FoodLogEntryTableTableCreateCompanionBuilder =
    FoodLogEntryTableCompanion Function({
      required String id,
      required String foodId,
      required Meal meal,
      Value<String?> mealName,
      required String diaryDay,
      required int grams,
      required int caloriesPer100g,
      required int proteinPer100g,
      required int carbsPer100g,
      required int fatPer100g,
      required int calories,
      required int protein,
      required int carbs,
      required int fat,
      required DateTime loggedAt,
      Value<int> revision,
      Value<int> sentRevision,
      Value<bool> deleted,
      Value<bool> refused,
      Value<int> rowid,
    });
typedef $$FoodLogEntryTableTableUpdateCompanionBuilder =
    FoodLogEntryTableCompanion Function({
      Value<String> id,
      Value<String> foodId,
      Value<Meal> meal,
      Value<String?> mealName,
      Value<String> diaryDay,
      Value<int> grams,
      Value<int> caloriesPer100g,
      Value<int> proteinPer100g,
      Value<int> carbsPer100g,
      Value<int> fatPer100g,
      Value<int> calories,
      Value<int> protein,
      Value<int> carbs,
      Value<int> fat,
      Value<DateTime> loggedAt,
      Value<int> revision,
      Value<int> sentRevision,
      Value<bool> deleted,
      Value<bool> refused,
      Value<int> rowid,
    });

class $$FoodLogEntryTableTableFilterComposer
    extends Composer<_$AppDatabase, $FoodLogEntryTableTable> {
  $$FoodLogEntryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Meal, Meal, String> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diaryDay => $composableBuilder(
    column: $table.diaryDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentRevision => $composableBuilder(
    column: $table.sentRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get refused => $composableBuilder(
    column: $table.refused,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodLogEntryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodLogEntryTableTable> {
  $$FoodLogEntryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diaryDay => $composableBuilder(
    column: $table.diaryDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentRevision => $composableBuilder(
    column: $table.sentRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get refused => $composableBuilder(
    column: $table.refused,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodLogEntryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodLogEntryTableTable> {
  $$FoodLogEntryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Meal, String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get mealName =>
      $composableBuilder(column: $table.mealName, builder: (column) => column);

  GeneratedColumn<String> get diaryDay =>
      $composableBuilder(column: $table.diaryDay, builder: (column) => column);

  GeneratedColumn<int> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<int> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get sentRevision => $composableBuilder(
    column: $table.sentRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get refused =>
      $composableBuilder(column: $table.refused, builder: (column) => column);
}

class $$FoodLogEntryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodLogEntryTableTable,
          FoodLogEntry,
          $$FoodLogEntryTableTableFilterComposer,
          $$FoodLogEntryTableTableOrderingComposer,
          $$FoodLogEntryTableTableAnnotationComposer,
          $$FoodLogEntryTableTableCreateCompanionBuilder,
          $$FoodLogEntryTableTableUpdateCompanionBuilder,
          (
            FoodLogEntry,
            BaseReferences<
              _$AppDatabase,
              $FoodLogEntryTableTable,
              FoodLogEntry
            >,
          ),
          FoodLogEntry,
          PrefetchHooks Function()
        > {
  $$FoodLogEntryTableTableTableManager(
    _$AppDatabase db,
    $FoodLogEntryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodLogEntryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodLogEntryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodLogEntryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<Meal> meal = const Value.absent(),
                Value<String?> mealName = const Value.absent(),
                Value<String> diaryDay = const Value.absent(),
                Value<int> grams = const Value.absent(),
                Value<int> caloriesPer100g = const Value.absent(),
                Value<int> proteinPer100g = const Value.absent(),
                Value<int> carbsPer100g = const Value.absent(),
                Value<int> fatPer100g = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> fat = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> sentRevision = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> refused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodLogEntryTableCompanion(
                id: id,
                foodId: foodId,
                meal: meal,
                mealName: mealName,
                diaryDay: diaryDay,
                grams: grams,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                loggedAt: loggedAt,
                revision: revision,
                sentRevision: sentRevision,
                deleted: deleted,
                refused: refused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String foodId,
                required Meal meal,
                Value<String?> mealName = const Value.absent(),
                required String diaryDay,
                required int grams,
                required int caloriesPer100g,
                required int proteinPer100g,
                required int carbsPer100g,
                required int fatPer100g,
                required int calories,
                required int protein,
                required int carbs,
                required int fat,
                required DateTime loggedAt,
                Value<int> revision = const Value.absent(),
                Value<int> sentRevision = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> refused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodLogEntryTableCompanion.insert(
                id: id,
                foodId: foodId,
                meal: meal,
                mealName: mealName,
                diaryDay: diaryDay,
                grams: grams,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                loggedAt: loggedAt,
                revision: revision,
                sentRevision: sentRevision,
                deleted: deleted,
                refused: refused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodLogEntryTableTable, FoodLogEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FoodLogEntryTableTable,
                    FoodLogEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodLogEntryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodLogEntryTableTable,
      FoodLogEntry,
      $$FoodLogEntryTableTableFilterComposer,
      $$FoodLogEntryTableTableOrderingComposer,
      $$FoodLogEntryTableTableAnnotationComposer,
      $$FoodLogEntryTableTableCreateCompanionBuilder,
      $$FoodLogEntryTableTableUpdateCompanionBuilder,
      (
        FoodLogEntry,
        BaseReferences<_$AppDatabase, $FoodLogEntryTableTable, FoodLogEntry>,
      ),
      FoodLogEntry,
      PrefetchHooks Function()
    >;
typedef $$PullMarkerTableTableCreateCompanionBuilder =
    PullMarkerTableCompanion Function({
      required String marker,
      Value<int> rowid,
    });
typedef $$PullMarkerTableTableUpdateCompanionBuilder =
    PullMarkerTableCompanion Function({Value<String> marker, Value<int> rowid});

class $$PullMarkerTableTableFilterComposer
    extends Composer<_$AppDatabase, $PullMarkerTableTable> {
  $$PullMarkerTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PullMarkerTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PullMarkerTableTable> {
  $$PullMarkerTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PullMarkerTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullMarkerTableTable> {
  $$PullMarkerTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get marker =>
      $composableBuilder(column: $table.marker, builder: (column) => column);
}

class $$PullMarkerTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PullMarkerTableTable,
          PullMarkerTableData,
          $$PullMarkerTableTableFilterComposer,
          $$PullMarkerTableTableOrderingComposer,
          $$PullMarkerTableTableAnnotationComposer,
          $$PullMarkerTableTableCreateCompanionBuilder,
          $$PullMarkerTableTableUpdateCompanionBuilder,
          (
            PullMarkerTableData,
            BaseReferences<
              _$AppDatabase,
              $PullMarkerTableTable,
              PullMarkerTableData
            >,
          ),
          PullMarkerTableData,
          PrefetchHooks Function()
        > {
  $$PullMarkerTableTableTableManager(
    _$AppDatabase db,
    $PullMarkerTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullMarkerTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PullMarkerTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullMarkerTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> marker = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PullMarkerTableCompanion(marker: marker, rowid: rowid),
          createCompanionCallback: ({
            required String marker,
            Value<int> rowid = const Value.absent(),
          }) => PullMarkerTableCompanion.insert(marker: marker, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PullMarkerTableTable, PullMarkerTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PullMarkerTableTable,
                    PullMarkerTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PullMarkerTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PullMarkerTableTable,
      PullMarkerTableData,
      $$PullMarkerTableTableFilterComposer,
      $$PullMarkerTableTableOrderingComposer,
      $$PullMarkerTableTableAnnotationComposer,
      $$PullMarkerTableTableCreateCompanionBuilder,
      $$PullMarkerTableTableUpdateCompanionBuilder,
      (
        PullMarkerTableData,
        BaseReferences<
          _$AppDatabase,
          $PullMarkerTableTable,
          PullMarkerTableData
        >,
      ),
      PullMarkerTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfileTableTableTableManager get profileTable =>
      $$ProfileTableTableTableManager(_db, _db.profileTable);
  $$TargetsTableTableTableManager get targetsTable =>
      $$TargetsTableTableTableManager(_db, _db.targetsTable);
  $$FoodTableTableTableManager get foodTable =>
      $$FoodTableTableTableManager(_db, _db.foodTable);
  $$FoodLogEntryTableTableTableManager get foodLogEntryTable =>
      $$FoodLogEntryTableTableTableManager(_db, _db.foodLogEntryTable);
  $$PullMarkerTableTableTableManager get pullMarkerTable =>
      $$PullMarkerTableTableTableManager(_db, _db.pullMarkerTable);
}
