import 'dart:async';

import 'package:mobx/mobx.dart';
part 'pomodoro_store.g.dart';

enum TimerType {
  WORK,
  BREAK,
}

class PomodoroStore = _PomodoroStoreBase with _$PomodoroStore;

abstract class _PomodoroStoreBase with Store {
  //Stream to trigger Dialog when work and break timer ends
  //For the user to know that the time is up

  static MultiStreamController<TimerType?>? _controller;
  static final _dialogStream = Stream<TimerType>.multi((controller) {
    _controller = controller;
  });

  Stream get dialogStream => _dialogStream;

  @observable
  bool timerStarted = false;

//Minutes in seconds for the CircularPercentIndicator total
  @observable
  int minutesInSec = 0;

  //Percentage of CircularPercentIndicator every second of Timer
  @observable
  int percent = 0;

  @observable
  int workTime = 5;

  @observable
  int breakTime = 2;

  //Timer minutes
  @observable
  int minutes = 5;

  //Timer Seconds
  @observable
  int seconds = 0;

  //Task being performed
  @observable
  String task = '';

  //What activity is being performed
  @observable
  TimerType timerType = TimerType.WORK;

  Timer? timer;

  @action
  void incrementWorkTime() {
    workTime++;
    //When setting time assigns to the Timer minutes
    if (isWorkTime) {
      minutes = workTime;
    }
    //Resets the Timer with the new minute value
    restartTimer();
  }

  @action
  void decrementWorkTime() {
    if (workTime > 1) {
      workTime--;
      //When setting time assigns to the Timer minutes
      if (isWorkTime) {
        minutes = workTime;
      }
    }
    //Resets the Timer with the new minute value
    restartTimer();
  }

  @action
  void incrementBreakTime() {
    breakTime++;
    if (isBreakTime) {
      minutes = breakTime;
    }
    restartTimer();
  }

  @action
  void decrementBreakTime() {
    if (breakTime > 1) {
      breakTime--;
      if (isBreakTime) {
        minutes = breakTime;
      }
    }
    restartTimer();
  }

  @action
  void setTask(String value) {
    task = value;
    restartTimer();
  }

  bool get isWorkTime => timerType == TimerType.WORK;

  bool get isBreakTime => timerType == TimerType.BREAK;

  //When the Activity Timer ends, it switches to another
  //controller for Stream to fire the Dialog of the activity that ended
  void changeTimerType() {
    if (timerType == TimerType.BREAK) {
      _controller?.add(TimerType.BREAK);
      timerType = TimerType.WORK;
      minutes = workTime;
    } else {
      _controller?.add(TimerType.WORK);
      timerType = TimerType.BREAK;
      minutes = breakTime;
    }
    seconds = 0;
  }

  //Method that starts the Timer
  @action
  void startTimer() {
    timerStarted = true;

    //Turns the minutes of each activity into seconds to use in the CircularPercentIndicator

    minutesInSec = isWorkTime ? workTime * 60 : breakTime * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (minutes == 0 && seconds == 0) {
        //Stops the Timer whenever an activity ends
        //need to start again to start the other activity
        stopTimer();
        changeTimerType();
        percent = 0; //percent 0 because it restarted the Timer

      } else if (seconds == 0) {
        seconds = 59;
        minutes--;
        //Every second +1 in percent, until equal to minutesInSec
        //which indicates that the time has been completed and the CircularPercentIndicator also
        percent++;
      } else {
        seconds--;
        percent++;
      }
    });
  }

  @action
  void stopTimer() {
    timerStarted = false;
    timer?.cancel();
  }

  @action
  void restartTimer() {
    timerStarted = false;
    stopTimer();
    minutes = isWorkTime ? workTime : breakTime;
    seconds = 0;
    percent = 0;
  }
}
