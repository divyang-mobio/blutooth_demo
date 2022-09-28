import 'screens/home_Screen.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'bloc/message_bloc.dart';

void main() => runApp(const MyApp());

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const Home());
    case '/browser':
      return MaterialPageRoute(
          builder: (_) =>
              const DevicesListScreen(deviceType: DeviceType.browser));
    case '/advertiser':
      return MaterialPageRoute(
          builder: (_) =>
              const DevicesListScreen(deviceType: DeviceType.advertiser));
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MessageBloc>(
        create: (context) => MessageBloc()..add(MessageEventBloc(chatData: [])),
        child: const MaterialApp(
          onGenerateRoute: generateRoute,
          initialRoute: '/',
        ));
  }
}
