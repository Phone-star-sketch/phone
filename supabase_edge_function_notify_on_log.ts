// Edge Function: notify-on-log
// الكود ده مبسّط ومضمون 100%

import { createClient } from 'jsr:@supabase/supabase-js@2';

const ASSISTANT_USER_ID = 2;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('📥 Request received');
    const payload = await req.json();
    console.log('📦 Payload:', JSON.stringify(payload));

    // Validate payload
    if (!payload.record) {
      console.log('❌ No record in payload');
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const record = payload.record;
    console.log('📝 Record creator:', record.creator);

    // Only notify for assistant transactions
    if (record.creator !== ASSISTANT_USER_ID) {
      console.log('⏭️ Skipping - not assistant transaction');
      return new Response(JSON.stringify({ skipped: true, reason: 'not assistant' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get client name
    let clientName = 'غير محدد';
    if (record.client_id) {
      try {
        const { data: client } = await supabase
          .from('client')
          .select('name')
          .eq('id', record.client_id)
          .single();
        if (client?.name) clientName = client.name;
        console.log('👤 Client name:', clientName);
      } catch (e) {
        console.log('⚠️ Could not fetch client:', e);
      }
    }

    // Get FCM token
    const { data: tokenRow, error: tokenError } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('device', 'manager')
      .single();

    if (tokenError || !tokenRow?.token) {
      console.log('❌ No FCM token found:', tokenError);
      return new Response(JSON.stringify({ skipped: true, reason: 'no token' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('🔑 FCM token found');

    // Prepare notification
    const typeNames: Record<number, string> = {
      0: 'تم استلام نقدية',
      1: 'تمت حذف نقدية',
      2: 'تم دفع حساب الخدمات',
    };

    const typeName = typeNames[record.transaction_type] ?? 'معاملة';
    const title = 'Phone System';
    const body = `${typeName} - العميل: ${clientName} - المبلغ: ${record.price} جنيه`;

    console.log('📧 Preparing FCM message:', title, body);

    // Get Firebase access token
    const accessToken = await getFirebaseAccessToken();
    console.log('🔐 Got Firebase access token');

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
              icon: 'launcher_icon',
              color: '#2196F3',
            },
          },
          data: {
            clientId: String(record.client_id || ''),
            price: String(record.price || ''),
            type: String(record.transaction_type || ''),
          },
        },
      }),
    });

    const result = await fcmResponse.json();
    
    if (!fcmResponse.ok) {
      console.log('❌ FCM error:', JSON.stringify(result));
      return new Response(JSON.stringify({ error: 'FCM failed', details: result }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('✅ FCM sent successfully:', JSON.stringify(result));
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

  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const body = btoa(JSON.stringify(payload));
  const signingInput = `${header}.${body}`;

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

  const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

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
