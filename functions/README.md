# Cloud Functions Deployment Guide

サーバーサイド通知（Cloud Functions）をデプロイするための手順です。

## 前提条件
- Node.js がインストールされていること
- Firebase CLI がインストールされていること (`npm install -g firebase-tools`)
- Firebase プロジェクトの管理者権限があること

## 手順

1. `functions` ディレクトリに移動します。
   ```bash
   cd functions
   ```

2. 必要なパッケージをインストールします。
   ```bash
   npm install firebase-functions firebase-admin
   ```

3. `package.json` が作成されていない場合は、`firebase init functions` を実行して初期化してください（既存の `index.js` を上書きしないように注意）。あるいは、以下の `package.json` を作成します。

   ```json
   {
     "name": "functions",
     "description": "Cloud Functions for TeamToDo",
     "engines": {
       "node": "18"
     },
     "main": "index.js",
     "dependencies": {
       "firebase-admin": "^11.0.0",
       "firebase-functions": "^4.0.0"
     },
     "private": true
   }
   ```

4. デプロイを実行します。
   ```bash
   firebase deploy --only functions
   ```

## 注意点
- Cloud Functions を使用するには、Firebase プロジェクトのプランを **Blaze (従量課金)** にアップグレードする必要があります。
- 通知を受け取るには、iOSアプリ側で「プッシュ通知」のCapabilitiesを追加し、Apple Developer PortalでAPNsキーを設定してFirebase Consoleにアップロードする必要があります。
