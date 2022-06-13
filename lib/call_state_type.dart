enum CallStateType {
  idle,
  calling,
}

extension CallStateTypeEx on CallStateType {
  static CallStateType? create(int value) {
    switch (value) {
      case 0:
        return CallStateType.idle;
      case 1:
        return CallStateType.calling;
      default:
        return null;
    }
  }

  String get value {
    switch (this) {
      case CallStateType.idle:
        return 'idle';
      case CallStateType.calling:
        return 'calling';
    }
  }
}
