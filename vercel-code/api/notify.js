const admin = require('firebase-admin');

if (!admin.apps.length) {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT.replace(/^﻿/, '');
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(raw)),
  });
}

function buildBody(locale, senderName, circleName, type) {
  if (locale === 'en') {
    if (type === 'reply')   return `${senderName} replied to your message in "${circleName}"`;
    if (type === 'invite')  return `${senderName} invited you to "${circleName}"`;
                            return `${senderName} mentioned you in "${circleName}"`;
  }
  if (type === 'reply')   return `${senderName} hat auf deine Nachricht in "${circleName}" geantwortet`;
  if (type === 'invite')  return `${senderName} hat dich zu "${circleName}" eingeladen`;
                          return `${senderName} hat dich in "${circleName}" erwähnt`;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { recipients, senderName, circleName, idToken } = req.body;

    await admin.auth().verifyIdToken(idToken);

    if (!recipients || recipients.length === 0) {
      return res.status(200).json({ sent: 0 });
    }

    // Fetch all user docs in parallel
    const userDocs = await Promise.all(
      recipients.map(({ uid }) =>
        admin.firestore().collection('users').doc(uid).get()
      )
    );

    const sends = userDocs.map((doc, i) => {
      const fcmToken = doc.data()?.fcmToken;
      if (!fcmToken) return null;
      const locale = doc.data()?.notifLocale ?? 'de';
      const { type } = recipients[i];
      return admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'Orbit',
          body: buildBody(locale, senderName, circleName, type),
        },
        android: { priority: 'high' },
      }).catch(() => null);
    }).filter(Boolean);

    await Promise.all(sends);
    return res.status(200).json({ sent: sends.length });
  } catch (err) {
    console.error('notify error:', err.message);
    return res.status(500).json({ error: err.message });
  }
};
