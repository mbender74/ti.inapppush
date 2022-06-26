# Titanium InAppPush iOS Module
iOS 12+ 


## Info for 1.0.0
Send Push notifications from device or also simulator to an other device (app)
P2P push over Apple Push Services -- no own push server needed!

- User A with app YOURAPP can send push notification to user B of the same YOUAPP
- User A needs to know the deviceToken of user B, than user A can send push directly to user B
- also silent push is possible - the app of user B will then wakeup and can perform some processing or download content in the timeframe Apple allows (about 30 seconds)

MacCatalyst compatible


## Methods
### `setupPush({Dictionary})`
***inital setup for the module***
### Properties

* **keyId**:`STRING`<br/>keyId of your P8 file
* **teamId**:`STRING`<br/>your Apple Developer teamId
* **bundleId**:`STRING`<br/>the bundleId of your app
* **environment**:`STRING`<br/>'development' (sandbox) or 'production'
* **p8FilePath**:`STRING`<br/>path to your p8 authKeyFile -> https://developer.apple.com/account/resources/authkeys/list

<br/>

### `sendPushToUser({Dictionary})`
### Properties

* **deviceToken:**`STRING`<br/>deviceToken of user B (or user you want to send push to)
* **payloadType**:`STRING`<br/>'**alert**' or '**background**' or '**voip**' or '**complication**' or '**fileprovider**' or '**mdm**'
* **payload**:`Object`<br/>the payload JSON object -> see example
* **callback**:`JSFunction`<br/>optional, function that will be called after push send



## Example

```js
/**
/* at the start somewhere in your app
**/

inAppPushModule.setupPush({
		keyId:'XXXXXXXXXX', // keyId of your P8 file
		teamId:'YYYYYYYYYY', // your Apple Developer teamId
		bundleId:'your.app.bundleid', // the bundleId of your app
		environment:'development', // 'development' (sandbox) or 'production'
		p8FilePath:Ti.Filesystem.resourcesDirectory+'AuthKey_XXXXXXXXXX.p8' // your p8 authKeyFile -> https://developer.apple.com/account/resources/authkeys/list
});
  

/**
/* when you send a message to the user or whenever you want to send push to the other user
**/

inAppPushModule.sendPushToUser({
              deviceToken : '000dc4dc79b05c81ec286d000f023f9ae0dd55780503d033dd9dd7f6ad000000', // deviceToken of user B
              payloadType : 'background', // 'alert' or 'background' or 'voip' or 'complication' or 'fileprovider' or 'mdm'
              payload : {
                'aps' : {
                  'alert' : 'Push test!', // message -- for silent push, if you want to show notification -> use local notification, because silent push does not trigger a visible notifiction
                  'content-available' : 1, // for background silent-push
                  'sound' : 'default' // 'default' or path to sound file
                  'badge' : 1 // integer for updating the app-icon badge counter
                }
              },
              callback : function(){} // optional, function that will be called after push send or error
});

```

## License

MIT

## Author

Marc Bender