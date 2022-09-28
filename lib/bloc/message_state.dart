part of 'message_bloc.dart';

abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageBlocState extends MessageState {
  List<MessageModel> chatData;

  MessageBlocState({required this.chatData});
}
