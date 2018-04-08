# RealTimeDelivery
Live video distribution apps by using SkyWay

ライブ配信ができるアプリです  
アプリ同士で配信、受信が可能です

## How to build
Download this repository and move Projects
```
cd RealTimeDelivery
```

Install library in Cocoapods
```
pod install
```

Create Firebase Project. Download GoogleService-Info.plist and this file include. 
```
RealTimeDelivery/GoogleService-Info.plist
```

Open projects in Xcode(then not .xcodeproj but .xcworkspace)
```
open RealTimeDelivery.xcworkspace
```

Input your API Key
```
SkyWayConfig.swift
static let apiKey = "***************** Enter your API KEY *******************"
```

Exec Build!

---

If you run this project, not Simulator but actual machine

## ビルド方法
このリポジトリをダウンロード後、プロジェクトに移動
```
cd RealTimeDelivery
```

Cocoapodsでライブラリをインストール
```
pod install
```

Firebaseプロジェクトを作成し、GoogleService-Info.plistをダウンロードしプロジェクトに組み込み
```
RealTimeDelivery/GoogleService-Info.plist
```

プロジェクトをXcodeで開く（.xcodeprojではなく.xcworkspaceを開く）
```
open RealTimeDelivery.xcworkspace
```

API Keyを入力
```
SkyWayConfig.swift
static let apiKey = "***************** Enter your API KEY *******************"
```

ビルドして実行！

---

シミュレーターでは動かないため、実機でテストしてください。

## License
MIT License
