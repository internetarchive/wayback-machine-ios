## Wayback Machine iOS App


### Install Dependencies

```
sudo gem install cocoapods
pod install
```

### Troubleshooting

#### Pod Install returns an error?

Try editing **Podfile** and remove or comment out targets 'WMTests' and 'WMUITests'. (which should have already been done...)


#### *IQKeyboardManager* framework not compiling?

Try this quick fix:

Pods > IQKeyboardManagerSwift (dropdown) > Build Settings > Build Options > Require Only App-Extension-Safe API > Set to NO
