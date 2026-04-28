// Edge Function: notify-on-log
// يرسل إشعارات FCM للمدير عند كل المعاملات

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';

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
    console.log('📥 Request received at:', new Date().toISOString());
    const payload = await req.json();
    console.log('📦 Payload:', JSON.stringify(payload, null, 2));

    // Validate payload structure
    if (!payload.record) {
      console.log('❌ No record in payload');
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const record = payload.record;
    console.log('📝 Record creator:', record.creator);
    console.log('📝 Transaction type:', record.transaction_type);
    console.log('📝 Client ID:', record.client_id);
    console.log('📝 Price:', record.price);

    // Send notifications for ALL transactions (removed creator filter)
    console.log('✅ Transaction detected - proceeding with notification');

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get client name from database
    let clientName = 'غير محدد';
    if (record.client_id) {
      try {
        const { data: client, error: clientError } = await supabase
          .from('client')
          .select('name')
          .eq('id', record.client_id)
          .single();
        
        if (clientError) {
          console.log('⚠️ Error fetching client:', clientError);
        } else if (client?.name) {
          clientName = client.name;
          console.log('👤 Client name:', clientName);
        }
      } catch (e) {
        console.log('⚠️ Exception fetching client:', e);
      }
    }

    // Get user name from database
    let userName = 'غير محدد';
    if (record.creator) {
      try {
        const { data: user, error: userError } = await supabase
          .from('users')
          .select('name')
          .eq('id', record.creator)
          .single();
        
        if (userError) {
          console.log('⚠️ Error fetching user:', userError);
        } else if (user?.name) {
          userName = user.name;
          console.log('👤 User name:', userName);
        }
      } catch (e) {
        console.log('⚠️ Exception fetching user:', e);
      }
    }

    // Get FCM token from database
    const { data: tokenRow, error: tokenError } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('device', 'manager')
      .single();

    if (tokenError) {
      console.log('❌ Error fetching FCM token:', tokenError);
      return new Response(JSON.stringify({ skipped: true, reason: 'token fetch error', error: tokenError }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!tokenRow?.token) {
      console.log('❌ No FCM token found in database');
      return new Response(JSON.stringify({ skipped: true, reason: 'no token' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('🔑 FCM token found:', tokenRow.token.substring(0, 20) + '...');

    // Prepare notification text
    const typeNames: Record<number, string> = {
      0: 'تم استلام نقدية',
      1: 'تم حذف نقدية',
      2: 'تم دفع حساب الخدمات',
    };

    const typeName = typeNames[record.transaction_type] ?? 'معاملة';
    const title = 'Phone System';
    const body = `${typeName} - بواسطة: ${userName}\nالعميل: ${clientName} - المبلغ: ${record.price} جنيه`;

    console.log('📧 Notification title:', title);
    console.log('📧 Notification body:', body);

    // Get Firebase access token
    console.log('🔐 Getting Firebase access token...');
    const accessToken = await getFirebaseAccessToken();
    console.log('🔐 Got Firebase access token');

    // Send FCM notification
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/phone-system-app/messages:send`;
    console.log('📤 Sending FCM request to:', fcmUrl);

    const fcmPayload = {
      message: {
        token: tokenRow.token,
        notification: { title, body },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'fcm_channel',
            icon: 'launcher_icon',
            color: '#2196F3',
            notification_priority: 'PRIORITY_MAX',
            notification_count: 1, // ✅ This increments the badge
          },
        },
        data: {
          clientId: String(record.client_id || ''),
          price: String(record.price || ''),
          type: String(record.transaction_type || ''),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          badge: '1', // ✅ Badge count for iOS/Android
        },
      },
    };

    console.log('📤 FCM payload:', JSON.stringify(fcmPayload, null, 2));

    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmPayload),
    });

    const result = await fcmResponse.json();
    console.log('📥 FCM response status:', fcmResponse.status);
    console.log('📥 FCM response:', JSON.stringify(result, null, 2));
    
    if (!fcmResponse.ok) {
      console.log('❌ FCM request failed with status:', fcmResponse.status);
      return new Response(JSON.stringify({ 
        error: 'FCM failed', 
        status: fcmResponse.status,
        details: result 
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('✅ FCM notification sent successfully!');
    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Notification sent',
      result 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('❌ Unexpected error:', error);
    console.error('❌ Error stack:', error instanceof Error ? error.stack : 'No stack trace');
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      message: String(error),
      stack: error instanceof Error ? error.stack : undefined
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

async function getFirebaseAccessToken(): Promise<string> {
  try {
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not set');
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    console.log('🔐 Service account email:', serviceAccount.client_email);

    // Import private key using djwt-compatible method
    const privateKey = await importPrivateKey(serviceAccount.private_key);

    const now = Math.floor(Date.now() / 1000);
    const header = { alg: 'RS256' as const, typ: 'JWT' as const };
    const payload = {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    };

    // Create JWT using djwt library
    const jwt = await create(header, payload, privateKey);
    console.log('🔐 JWT created, exchanging for access token...');

    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error('❌ Token exchange failed:', errorText);
      throw new Error(`Failed to get access token: ${tokenResponse.status} - ${errorText}`);
    }

    const tokenData = await tokenResponse.json();
    
    if (!tokenData.access_token) {
      throw new Error('No access token in response');
    }

    console.log('🔐 Access token obtained successfully');
    return tokenData.access_token;
  } catch (error) {
    console.error('❌ Error getting Firebase access token:', error);
    throw error;
  }
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  // Remove PEM header/footer and whitespace
  const cleanKey = pem
    .replaceAll('\\n', '')
    .replaceAll('\n', '')
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .trim();
  
  // Decode base64
  const binaryString = atob(cleanKey);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  // Import key
  return await crypto.subtle.importKey(
    'pkcs8',
    bytes.buffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    true,
    ['sign']
  );
}
