
import 'package:bloc/bloc.dart';

import '../message_model.dart';

part 'message_event.dart';

part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc() : super(MessageInitial()) {
    on<MessageEventBloc>((event, emit) {
      emit(MessageBlocState(chatData: event.chatData));
    });
  }
}
