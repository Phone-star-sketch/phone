// Edge Function: notify-on-log
// رفع ده على Supabase Dashboard → Edge Functions → notify-on-log

import { createClient } from 'jsr:@supabase/supabase-js@2';

const ASSISTANT_USER_ID = 2;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    console.log('📥 Received payload:', JSON.stringify(payload));

    if (payload.type !== 'INSERT' || payload.table !== 'log') {
      return new Response(JSON.stringify({ skipped: true, reason: 'not log insert' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const record = payload.record;

    if (record.creator !== ASSISTANT_USER_ID) {
      return new Response(JSON.stringify({ skipped: true, reason: 'not assistant' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get client name
    let clientName = 'غير محدد';
    if (record.client_id) {
      const { data: client } = await supabase
        .from('client')
        .select('name')
        .eq('id', record.client_id)
        .single();
      if (client?.name) clientName = client.name;
    }

    // Get FCM token
    const { data: tokenRow } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('device', 'manager')
      .single();

    if (!tokenRow?.token) {
      console.log('⚠️ No FCM token found');
      return new Response(JSON.stringify({ skipped: true, reason: 'no token' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const typeNames: Record<number, string> = {
      0: 'تم استلام نقدية',
      1: 'تمت حذف نقدية',
      2: 'تم دفع حساب الخدمات',
    };

    const typeName = typeNames[record.transaction_type] ?? 'معاملة';
    const title = 'Phone System'; // اسم التطبيق
    const body = `${typeName} - العميل: ${clientName} - المبلغ: ${record.price} جنيه`;

    // Get Firebase access token
    const accessToken = await getFirebaseAccessToken();

    // Send FCM notification
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/phone-system-app/messages:send`;
    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: tokenRow.token,
          notification: {
            title: title,
            body: body,
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channel_id: 'fcm_channel',
              icon: 'launcher_icon', // أيقونة التطبيق
              color: '#2196F3',
            },
          },
          data: {
            clientId: String(record.client_id),
            price: String(record.price),
            type: String(record.transaction_type),
            logId: String(record.id),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      }),
    });

    const result = await fcmResponse.json();
    console.log('✅ FCM result:', JSON.stringify(result));

    if (!fcmResponse.ok) {
      console.error('❌ FCM error:', result);
      return new Response(JSON.stringify({ error: 'FCM failed', details: result }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

async function getFirebaseAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  };

  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  
  const payloadStr = btoa(JSON.stringify(payload))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const signingInput = `${header}.${payloadStr}`;

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const jwt = `${signingInput}.${sig}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '');
  const binary = atob(base64);
  const buffer = new ArrayBuffer(binary.length);
  const view = new Uint8Array(buffer);
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i);
  }
  return buffer;
}
