part of 'message_bloc.dart';

abstract class MessageEvent {}

class MessageEventBloc extends MessageEvent {
  List<MessageModel> chatData;

  MessageEventBloc({required this.chatData});
}
