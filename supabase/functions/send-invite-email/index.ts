import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const resendApiKey = Deno.env.get("RESEND_API_KEY")
const supabaseUrl = Deno.env.get("SUPABASE_URL")
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

const supabase = createClient(supabaseUrl!, supabaseServiceKey!)

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record // newly inserted row from invite_queue

    // ✅ Input guard — reject malformed webhook payloads early
    if (!record?.invitee_email || !record?.inviter_id || !record?.id) {
      return new Response("Invalid payload", { status: 400 })
    }

    if (record.status !== 'pending') {
      return new Response("Not pending, skipping", { status: 200 })
    }

    // 1. Fetch related data (inviter, action_item, session)
    const { data: inviter } = await supabase
      .from('users') // or auth.users if accessed through a view
      .select('raw_user_meta_data')
      .eq('id', record.inviter_id)
      .single()

    const hostName = inviter?.raw_user_meta_data?.name || 'Your teammate'

    const { data: actionItem } = await supabase
      .from('action_items')
      .select('task, deadline')
      .eq('id', record.action_item_id)
      .single()

    const { data: session } = await supabase
      .from('sessions')
      .select('title')
      .eq('id', record.session_id)
      .single()

    const { data: recapLink } = await supabase
      .from('recap_links')
      .select('hash')
      .eq('id', record.recap_link_id)
      .single()

    const taskText = actionItem?.task || 'A task'
    const deadlineText = actionItem?.deadline || 'No deadline set'
    const sessionTitle = session?.title || 'a meeting'
    const recapUrl = `https://wrapd.ai/r/${recapLink?.hash || ''}`
    const joinUrl = `https://wrapd.ai/join?invite=${record.id}`

    // 2. Build email body
    const emailBody = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #111827;">
        <h1 style="font-weight: 800; letter-spacing: 2px;">WRAPD</h1>
        <p>${hostName} just wrapped a meeting and assigned you a task:</p>
        
        <div style="background-color: #F4F5F8; padding: 16px; border-radius: 8px; border-left: 4px solid #00D97E; margin: 24px 0;">
          <p style="margin: 0 0 8px 0;"><strong>Task:</strong> ${taskText}</p>
          <p style="margin: 0 0 8px 0;"><strong>Deadline:</strong> ${deadlineText}</p>
          <p style="margin: 0;"><strong>Meeting:</strong> ${sessionTitle}</p>
        </div>

        <a href="${recapUrl}" style="display: inline-block; background-color: #0A5CFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">View the full meeting recap →</a>
        
        <hr style="border: 0; border-top: 1px solid #E6E8EE; margin: 32px 0;" />
        
        <a href="${joinUrl}" style="color: #0A5CFF; font-weight: bold; text-decoration: none;">Join your team on WRAPD to track this action →</a>
        
        <p style="color: #6B7280; font-size: 12px; margin-top: 32px;">
          You received this because ${hostName} assigned an action to ${record.invitee_email}.
        </p>
      </div>
    `

    // 3. Send via Resend
    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${resendApiKey}`
      },
      body: JSON.stringify({
        from: "WRAPD <notifications@wrapd.ai>",
        to: [record.invitee_email],
        subject: `${hostName} assigned you an action in WRAPD`,
        html: emailBody
      })
    })

    if (!resendRes.ok) {
      throw new Error(`Resend API error: ${await resendRes.text()}`)
    }

    // 4. Update invite_queue status
    await supabase
      .from('invite_queue')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', record.id)

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
