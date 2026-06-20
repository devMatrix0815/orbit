const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

exports.sendInviteNotification = onDocumentCreated(
  "invites/{inviteId}",
  async (event) => {
    const invite = event.data.data();
    const invitedEmail = invite?.invitedEmail;
    const circleName = invite?.circleName;

    if (!invitedEmail || !circleName) return;

    try {
      // UID über Firebase Auth anhand der E-Mail holen
      const userRecord = await getAuth().getUserByEmail(invitedEmail);
      const uid = userRecord.uid;

      // FCM-Token aus Firestore holen
      const userDoc = await getFirestore()
        .collection("users")
        .doc(uid)
        .get();

      if (!userDoc.exists) return;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return;

      // Notification senden
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Neue Gruppen-Einladung 🔵",
          body: `Du wurdest in die Gruppe "${circleName}" eingeladen!`,
        },
        android: {
          notification: {
            channelId: "orbit_invites",
            priority: "high",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default" },
          },
        },
      });
    } catch (e) {
      console.error("Fehler beim Senden der Einladungs-Notification:", e);
    }
  }
);
