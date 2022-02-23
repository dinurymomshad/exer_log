import 'package:exerlog/Bloc/exercise_bloc.dart';
import 'package:exerlog/Models/exercise.dart';
import 'package:exerlog/Models/sets.dart';
import 'package:exerlog/Models/workout.dart';
import 'package:exerlog/UI/exercise/exercise_card.dart';
import 'package:exerlog/UI/exercise/set_widget.dart';
import 'package:exerlog/UI/exercise/totals_widget.dart';
import 'package:exerlog/UI/prev_workout/prev_exercise_card.dart';
import 'package:exerlog/UI/workout/workout_toatals_widget.dart';

class PrevWorkoutData {
  Function(Workout) updateTotals;
  Workout workout;
  WorkoutTotals totals;
  Function(Exercise, Sets, int) addNewSet;
  List<PrevExerciseCard> exerciseWidgets = [];

  PrevWorkoutData(this.workout, this.totals, this.updateTotals, this.addNewSet) {
    workout = this.workout;
    
      loadWorkoutData().then((value) {
        workout = value;
        setExerciseWidgets();
        for (Exercise exercise in this.workout.exercises) {
          updateExisitingExercise(exercise);
        }
      });
  }

  addSet(exercise, newSet, id) {
    exercise.sets[id] = newSet;
    //updateExisitingExercise(exercise);
    setTotals(exercise);
  }

  void setTotals(exercise) {
    TotalsData returnTotals = exercise.totalWidget.totals;
    int totalSets = 0;
    int totalReps = 0;
    double totalKgs = 0;
    for (Sets sets in exercise.sets) {
      totalSets += sets.sets;
      int reps = sets.sets > 0 ? sets.sets * sets.reps : sets.reps;
      totalReps += reps;
      totalKgs += reps * sets.weight;
    }
    double avgKgs = (totalKgs / totalReps).roundToDouble();
    returnTotals.total[0] = totalSets.toString() + " sets";
    returnTotals.total[1] = totalReps.toString() + " reps";
    returnTotals.total[2] = totalKgs.toString() + " kgs";
    returnTotals.total[3] = avgKgs.toString() + " kg/rep";
    exercise.totalWidget.totals = returnTotals;
    updateExisitingExercise(exercise);
  }

  Future<Workout> loadWorkoutData() async {
    Workout loaded_workout =
        new Workout(workout.exercises, '', '', 0, '', '', true);
    List<Sets> setList = [];
    List<Exercise> exerciseList = [];
    List<Exercise> newExerciseList = [];
    Exercise newExercise;
    try {
      for (String exercise_id in workout.exercises) {
        await getSpecificExercise(exercise_id)
            .then((value) async => {exerciseList.add(value)});
      }
      Future.delayed(Duration(seconds: 3));
      int totalSets = 0;
      int totalReps = 0;
      double totalKgs = 0;
      int reps = 0;
      double avgKgs = 0;
      for (Exercise exercise in exerciseList) {
        await getExerciseByName(exercise.name).then((newexercise) => {
              setList = [],
              for (var sets in newexercise.sets)
                {
                  setList.add(new Sets(sets['reps'], sets['rest'],
                      sets['weight'], sets['sets'])),
                  totalSets += sets['sets']! as int,
                  reps = sets['sets'] * sets['reps'],
                  totalReps += reps,
                  totalKgs += reps * sets['weight']
                },
              newExercise =
                  new Exercise(exercise.name, setList, exercise.bodyParts),
              avgKgs = (totalKgs / totalReps).roundToDouble(),
              setTotals(newExercise),
              newExerciseList.add(newExercise),
            });
      }
      loaded_workout.exercises = newExerciseList;
      //workout = loaded_workout;
    } catch (Exception) {
      print("Helloooo");
      print(Exception);
    }
    return loaded_workout;
    //updateTotals(loaded_workout);
    //print(loaded_workout.exercises[0]);
  }

  List<PrevExerciseCard> setExerciseWidgets() {
    exerciseWidgets = [];
    for (Exercise exercise in workout.exercises) {
      List<SetWidget> setList = [];
      int i = 0;
      for (Sets sets in exercise.sets) {
        setList.add(new SetWidget(
            name: exercise.name,
            exercise: exercise,
            addNewSet: addSet,
            id: i,
            isTemplate: workout.template));
        i++;
      }
      exerciseWidgets.add(new PrevExerciseCard(
        name: exercise.name,
        exercise: exercise,
        addExercise: addExercise,
        updateExisitingExercise: updateExisitingExercise,
        isTemplate: workout.template,
        setList: setList,
        prevworkoutData: this,
      ));
    }
    return exerciseWidgets;
  }

  updateExisitingExercise(exercise) {
    try {
      totals = new WorkoutTotals(0, 0, 0, 0, 0);
      for (Exercise oldexercise in workout.exercises) {
        totals.exercises++;
        if (oldexercise.name == exercise.name) {
          oldexercise = exercise;
        }
        for (Sets sets in oldexercise.sets) {
          totals.sets += sets.sets;
          int reps_set = sets.sets * sets.reps;
          totals.weight += reps_set * sets.weight;
          totals.reps += reps_set;
        }
        totals.avgKgs = (totals.weight / totals.reps).roundToDouble();
      }
      //setTotals(exercise);
      updateTotals(workout);
    } catch (Exception) {
      print("problem");
      print(Exception);
    }
  }

  addExercise(exercise) {
    try {
      for (Exercise existingExercise in workout.exercises) {
        if (existingExercise.name == exercise.name) {
          existingExercise = exercise;
          return;
        }
      }

      if (exercise.name != '') {
        workout.exercises.add(exercise);
      }
    } catch (Exception) {
      print(Exception);
    }
    updateTotals(workout);
  }
}