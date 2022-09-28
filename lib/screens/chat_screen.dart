import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import '../bloc/message_bloc.dart';
import '../message_model.dart';

enum DeviceType { advertiser, browser }

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({super.key, required this.deviceType});

  final DeviceType deviceType;

  @override
  DevicesListScreenState createState() => DevicesListScreenState();
}

class DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;
  List<MessageModel> chatData = [];

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Text(widget.deviceType == DeviceType.advertiser
                ? 'Host'
                : 'Receiver')),
        backgroundColor: Colors.white,
        body: ListView.builder(
            itemCount: getItemCount(),
            itemBuilder: (context, index) {
              final device = widget.deviceType == DeviceType.advertiser
                  ? connectedDevices[index]
                  : devices[index];
              return Container(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabItemListener(device),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(device.deviceName),
                                    Text(
                                      getStateName(device.state),
                                      style: TextStyle(
                                          color: getStateColor(device.state)),
                                    ),
                                  ]),
                            )),
                        GestureDetector(
                          onTap: () => _onButtonClicked(device),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            height: 35,
                            width: 100,
                            color: getButtonColor(device.state),
                            child: Center(
                              child: Text(
                                getButtonStateName(device.state),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    const Divider(
                      height: 1,
                      color: Colors.grey,
                    )
                  ],
                ),
              );
            }));
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return "disconnected";
      case SessionState.connecting:
        return "waiting";
      default:
        return "connected";
    }
  }

  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return "Connect";
      default:
        return "Disconnect";
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  _onTabItemListener(Device device) {
    if (device.state == SessionState.connected) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            final myController = TextEditingController();
            return SingleChildScrollView(
              child: AlertDialog(
                title: const Text("Send message"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300.0,
                        width: 300.0,
                        child: BlocBuilder<MessageBloc, MessageState>(
                          builder: (context, state) {
                            if (state is MessageBlocState) {
                              return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: state.chatData.length,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      color: (state.chatData[index].alignment ==
                                          Alignment.centerLeft)
                                          ? Colors.white
                                          : Colors.blue,
                                      child: Text(
                                          (state.chatData[index].alignment ==
                                              Alignment.centerLeft)
                                              ? state.chatData[index].data
                                              : state.chatData[index].data),
                                    );
                                  });
                            } else {
                              return const CircularProgressIndicator.adaptive();
                            }
                          },
                        ),
                      ),
                      TextField(controller: myController),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text("Send"),
                    onPressed: () {
                      chatData.add(MessageModel(
                          data: myController.text,
                          alignment: Alignment.centerRight));
                      nearbyService.sendMessage(
                          device.deviceId, myController.text);
                      BlocProvider.of<MessageBloc>(context)
                          .add(MessageEventBloc(chatData: chatData));
                      myController.text = '';
                    },
                  )
                ],
              ),
            );
          });
    }
  }

  int getItemCount() {
    if (widget.deviceType == DeviceType.advertiser) {
      return connectedDevices.length;
    } else {
      return devices.length;
    }
  }

  _onButtonClicked(Device device) {
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
        break;
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceID: device.deviceId);
        break;
      case SessionState.connecting:
        break;
    }
  }

  void init() async {
    nearbyService = NearbyService();
    String devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
        serviceType: 'mpconn',
        deviceName: devInfo,
        strategy: Strategy.P2P_STAR,
        callback: (isRunning) async {
          if (isRunning) {
            if (widget.deviceType == DeviceType.browser) {
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(const Duration(microseconds: 200));
              await nearbyService.startBrowsingForPeers();
            } else {
              await nearbyService.stopAdvertisingPeer();
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(const Duration(microseconds: 200));
              await nearbyService.startAdvertisingPeer();
              await nearbyService.startBrowsingForPeers();
              //for 1 only
            }
          }
        });
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
          for (var element in devicesList) {
            if (Platform.isAndroid) {
              if (element.state == SessionState.connected) {
                nearbyService.stopBrowsingForPeers();
              } else {
                nearbyService.startBrowsingForPeers();
              }
            }
          }

          setState(() {
            devices.clear();
            devices.addAll(devicesList);
            connectedDevices.clear();
            connectedDevices.addAll(devicesList
                .where((d) => d.state == SessionState.connected)
                .toList());
          });
        });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (data) {
          Map j = json.decode(jsonEncode(data));
          showToast(jsonEncode(data),
              context: context,
              axis: Axis.horizontal,
              alignment: Alignment.center,
              position: StyledToastPosition.bottom);
          chatData.add(
              MessageModel(data: j['message'], alignment: Alignment.centerLeft));
          BlocProvider.of<MessageBloc>(context)
              .add(MessageEventBloc(chatData: chatData));
        });
  }
}
