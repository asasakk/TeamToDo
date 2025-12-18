const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Cloud Functions v2のリージョン設定（東京など、プロジェクトのリージョンに合わせる）
// Firestoreが東京(asia-northeast1)にある場合、ここも合わせる必要があります
setGlobalOptions({ region: "asia-northeast1" });

exports.onTaskAssigned = onDocumentCreated("projects/{projectId}/tasks/{taskId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No data associated with the event");
    return;
  }
  const task = snap.data();
  const assignedTo = task.assignedTo;

  // v2では context.params ではなく event.params
  const projectId = event.params.projectId;
  const taskId = event.params.taskId;

  if (!assignedTo) {
    console.log("No assignee for this task");
    return;
  }

  try {
    // 担当者の情報を取得
    const userDoc = await admin.firestore().collection("users").doc(assignedTo).get();

    console.log(`Fetching user for notification: ${assignedTo}`); // LOG UID

    if (!userDoc.exists) {
      console.log("Assigned user not found in Firestore");
      return;
    }

    const user = userDoc.data();
    console.log("User data retrieved:", JSON.stringify(user)); // LOG USER DATA

    const fcmToken = user.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token for user (field is missing or empty)");
      return;
    }

    // 通知メッセージを作成
    const message = {
      token: fcmToken,
      notification: {
        title: "新しいタスクが割り当てられました",
        body: `${task.title}`,
      },
      data: {
        projectId: projectId,
        taskId: taskId,
      },
    };

    // FCMを送信
    await admin.messaging().send(message);
    console.log("Notification sent successfully");

  } catch (error) {
    console.error("Error sending notification:", error);
  }
});

// タスク更新時の通知（オプション）
exports.onTaskUpdated = onDocumentUpdated("projects/{projectId}/tasks/{taskId}", async (event) => {
  const change = event.data;
  if (!change) { return; }

  const newData = change.after.data();
  const oldData = change.before.data();

  // 担当者が変更された場合のみ通知
  if (newData.assignedTo && newData.assignedTo !== oldData.assignedTo) {
    const assignedTo = newData.assignedTo;

    try {
      const userDoc = await admin.firestore().collection("users").doc(assignedTo).get();
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
    } catch (e) {
      console.error(e);
    }
  }
});
