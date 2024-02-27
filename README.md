# Teegarden

## Getting Started

1. Install the software: [Xcode 15](https://developer.apple.com/download/all/?q=Xcode)

2. Come ask us for `GoogleService-Info.plist` which includes credentials.

3. Place `GoogleService-Info.plist` under /booksp (the root directory).

4. Confirm your Firebase(firebase-ios-sdk) package version is Exact 10.13.0.

5. Open with the following command.

    ```open --env FIREBASE_SOURCE_FIRESTORE /path/to/project.xcodeproj```

      * If you had installed Xcode, make sure the open command of Xcode CLI trigger Xcode-Beta, instead of standard Xcode. 
      
        To switch, Execute ```$ sudo xcode-select -s /Applications/Xcode-beta.app```.
