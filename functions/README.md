# Cloud Functions Deployment Guide

サーバーサイド通知（Cloud Functions）をデプロイするための手順です。
基本的に、**黒い画面（Macのターミナル）** で操作します。ブラウザでの操作が必要な場合は明記しています。

## 前提条件
1.  **[Webブラウザ]** Firebase Consoleでプロジェクトのプランを **Blaze (従量課金)** に変更済みであること。
2.  **[Macターミナル]** Node.js と Firebase CLI がインストール済みであること。
    - `node -v` と `firebase --version` コマンドで確認できます。

## デプロイ手順 (Macのターミナルで実行)

1. `functions` ディレクトリに移動します。
   ```bash
   cd functions
   ```

   > 今、どのフォルダにいるかわからない場合は `pwd` コマンドで確認するか、一度 `cd ~/Documents/TeamToDo/functions` と入力すれば確実です。

2. 必要なパッケージをインストールします。
   ```bash
   npm install
   ```

   > `node_modules` フォルダが自動生成されます。

3. Firebaseにログインします（初回のみ）。
   ```bash
   firebase login
   ```
   > 布ブラウザが開き、Googleログインを求められます。許可してください。

4. プロジェクトを選択してデプロイを実行します。
   ```bash
   firebase use --add
   # リストから自分のプロジェクトを選択してください
   
   firebase deploy --only functions
   ```

   > `Deploy complete!` と表示されれば成功です。

## 注意点
- 通知を受け取るには、iOSアプリ側で「プッシュ通知」のCapabilitiesを追加し、Apple Developer PortalでAPNsキーを設定してFirebase Consoleにアップロードする必要があります。

