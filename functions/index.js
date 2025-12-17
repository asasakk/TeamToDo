const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendTaskAssignmentNotification = functions.firestore
  .document("projects/{projectId}/tasks/{taskId}")
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const assignedTo = task.assignedTo;

    if (!assignedTo) {
      console.log("No assignee for this task");
      return;
    }

    try {
      // 担当者の情報を取得
      const userDoc = await admin.firestore().collection("users").document(assignedTo).get();
      if (!userDoc.exists) {
        console.log("Assigned user not found");
        return;
      }

      const user = userDoc.data();
      const fcmToken = user.fcmToken;

      if (!fcmToken) {
        console.log("No FCM token for user");
        return;
      }

      // 通知メッセージを作成
      const message = {
        to: fcmToken,
        notification: {
          title: "新しいタスクが割り当てられました",
          body: `${task.title}`,
        },
        data: {
          projectId: context.params.projectId,
          taskId: context.params.taskId,
        },
      };

      // FCMを送信
      await admin.messaging().send(message); // or sendToDevice depending on SDK version preferred
      console.log("Notification sent successfully");
      
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });

// タスク更新時の通知（オプション）
exports.onTaskUpdate = functions.firestore
  .document("projects/{projectId}/tasks/{taskId}")
  .onUpdate(async (change, context) => {
      const newData = change.after.data();
      const oldData = change.before.data();
      
      // 担当者が変更された場合のみ通知
      if (newData.assignedTo && newData.assignedTo !== oldData.assignedTo) {
          const assignedTo = newData.assignedTo;
          // ... (同様の通知ロジック)
          
          try {
              const userDoc = await admin.firestore().collection("users").document(assignedTo).get();
              if (userDoc.exists && userDoc.data().fcmToken) {
                  const message = {
                      token: userDoc.data().fcmToken,
                      notification: {
                          title: "タスクが割り当てられました",
                          body: `${newData.title}`,
                      }
                  };
                  await admin.messaging().send(message);
              }
          } catch(e) {
              console.error(e);
          }
      }
  });
