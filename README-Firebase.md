# SwiftSurvey Firebase Example

Firebase can be integrated into the app to load surveys remotely and store responses. This project uses Firebase Realtime Database. Additionally, firebase [Remote Config](https://firebase.google.com/products/remote-config) can be employed to turn the survey on and off.

1. [Create a firebase project for your iOS app and Register your app with Firebase](https://firebase.google.com/docs/ios/setup)

2. Add Firebase to your project via [PODS](https://firebase.google.com/docs/ios/setup) or [Swift Package Manager](https://firebase.google.com/docs/ios/swift-package-manager)

Include the following packages
- remote config
- database

Make sure to replace "GoogleServices-Info.plist" with your own.

3. Create Database under "Realtime Database" in Firebase Console

4. (Optional) Remote Config If you want load survey remotely -- output survey as json with function  "Survey.SaveToFile" - and add to Firebase Remote Config as variable -- this example uses "SURVEY_DATA" as the key








