// This is a test harness for your module
// You should do something interesting in this harness
// to test out the module and to provide instructions
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();

// TODO: write your module tests here
var ti_inapppush = require('de.marcbender.inapppush');
Ti.API.info("module is => " + ti_inapppush);


// your device token --- now need to get the token from other user!!!!
var deviceToken = null;


  function deviceTokenError(e) {
      alert('Failed to register for push notifications! ' + e.error);
  }

  function deviceTokenSuccess(e) {
      Ti.API.info('\n\n +++++++++++++   Success to register for push notifications! ' + JSON.stringify(e));
      deviceToken = e.deviceToken;

  }


// Process incoming push notifications
function receivePush(e) {
    Ti.API.info('Received push: ' + JSON.stringify(e));
}


var registerForPush = function() {
    // Remove event listener once registered for push notifications
    Ti.App.iOS.removeEventListener('usernotificationsettings', registerForPush);

    Ti.Network.registerForPushNotifications({
        success: deviceTokenSuccess,
        error: deviceTokenError,
        callback: receivePush
    });
 }

 Ti.App.iOS.addEventListener('usernotificationsettings', registerForPush);

  // //Check if the device is running iOS 8 or later, before registering for local notifications
  if (parseInt(Ti.Platform.version.split(".")[0]) >= 8){
      Ti.App.iOS.registerUserNotificationSettings({
        types: [
              Ti.App.iOS.USER_NOTIFICATION_TYPE_ALERT,
              Ti.App.iOS.USER_NOTIFICATION_TYPE_SOUND,
              Ti.App.iOS.USER_NOTIFICATION_TYPE_BADGE
          ]
      });
  }



Ti.App.iOS.addEventListener('silentpush', function(e) {
        // Initiate a download operation
        // Put the application back to sleep
        Ti.API.info("\n\n******** SILENT PUSH RECEIVED");
});


 Ti.App.addEventListener('silentpushend', function(e) {

    Ti.API.info("******** ENDPROCESSING SILENT PUSH ");

    Ti.App.iOS.scheduleLocalNotification({
        date: new Date(new Date().getTime() + 1500),
        alertBody: "SILENT PUSH RECEIVED",
        badge: Ti.UI.iOS.appBadge + 1,
        sound: "Default",
        category: "MESSAGE_CATEGORY"
    });  

 });



/**
/* at the start somewhere in your app
**/

ti_inapppush.setupPush({
		keyId:'XXXXXXXXXX', // keyId of your P8 file
		teamId:'YYYYYYYYYY', // your Apple Developer teamId
		bundleId:'your.app.bundleid', // the bundleId of your app
		environment:'development', // 'development' (sandbox) or 'production'
		p8FilePath:Ti.Filesystem.resourcesDirectory+'AuthKey_XXXXXXXXXX.p8' // your p8 authKeyFile -> https://developer.apple.com/account/resources/authkeys/list
});
  


// YOU NEED a messaging layer (chat or whatever) to exchange the deviceTokens !!!!!


/**
/* when you send a message to the user or whenever you want to send push to the other user
**/

ti_inapppush.sendPushToUser({
              deviceToken : '000dc4dc79b05c81ec286d000f023f9ae0dd55780503d033dd9dd7f6ad000000', // deviceToken of user B
              payloadType : 'background', // 'alert' or 'background' or 'voip' or 'complication' or 'fileprovider' or 'mdm'
              payload : {
                'aps' : {
                  'alert' : 'Push test!', // message -- for silent push, if you want to show notification -> use local notification, because silent push does not trigger a visible notifiction
                  'content-available' : 1, // for background silent-push
                  'sound' : 'default', // 'default' or path to sound file
                  'badge' : 1 // integer for updating the app-icon badge counter
                }
              },
              callback : function(e){alert('result of sendPushToUser:'+JSON.stringify(e))} // optional, function that will be called after push send or error
});

