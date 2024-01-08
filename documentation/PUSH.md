# Push notifications
Exponea allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable push notifications.

There is some setup required for each of the native platforms.
* [iOS Push notification setup](./PUSH_IOS.md)
* [Android Push notification setup](./PUSH_ANDROID.md)

> To test your push notification setup, send push notifications to your device from Exponea backend following [Sending Push notifications guide](./PUSH_SEND.md)

## Responding to push notifications
Once you perform platform setup, your application should be able to receive push notifications. To respond to push notification interaction, you can setup a listener to `ExponeaPlugin().openedPushStream`. The SDK will hold last push notification and call the listener once it's set, but it's still recommended to set the listener as soon as possible to keep good flow of your application.
```dart
import 'package:exponea/exponea.dart';

final _plugin = ExponeaPlugin();
final subscription = _plugin.openedPushStream.listen((openedPush) {
  switch(openedPush.action) {
    case PushActionType.app:
      // last push directed user to your app with no link

      // log data defined on Exponea backend
      print('app - ${openedPush.data}'); 
      break;
    case PushActionType.deeplink:
      // last push directed user to your app with deeplink
      print('deeplink - ${openedPush.url}');
      break;
    case PushActionType.web:
      // last push directed user to web, nothing to do here
      print('web');
      break;
  }
});
```
Don't forget to call `subscription.cancel()` when no longer needed.

> There is additional setup required for deeplinking, see native platform push notification setup guides. You can always just use `Open App` action and put your payload to `Additional data`.

## Received push notifications
You can set up a listener for received push notifications using `ExponeaPlugin.receivedPushStream`, which is mostly useful for silent push notifications. The SDK will hold last push notification and call the listener once it's set, but it's still recommended to set the listener as soon as possible.
> The listener is called for both regular and silent push notifications on Android and **only** for silent push notifications on iOS due to technical limitations.

```dart
final subscription = _plugin.receivedPushStream.listen((receivedPush) {
  print(receivedPush);
});
```
Don't forget to call `subscription.cancel()` when no longer needed.
