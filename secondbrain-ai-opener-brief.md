# Second Brain — AI Opener Message Brief
> The message waiting for you when you open a note

---

## What we're building

When a user opens a note in the detail view, the AI may have left a message. It reads the note content, checks the user's recent note history from Supabase, and decides whether there's something worth saying. If there is, a message appears at the bottom of the note like a conversation starter. The user can reply, and a thread continues from there.

This is not a chatbot. It's a warm, curious friend who has read your notes and occasionally notices something worth mentioning.

---

## Where it lives in the UI

At the bottom of the note detail view, below the note content and existing fields — a conversation thread section.

If the AI has something to say, it appears as a message bubble on the left (AI side).
If the AI has nothing to say, this section is completely hidden. No empty state, no placeholder text.

The user can reply to the AI message. Their reply appears on the right. The AI can respond once more if relevant. Keep threads short — this is not a full chat interface, it's a nudge and a response.

---

## When the AI should speak

The AI should leave a message when it notices something genuinely interesting. Examples:

- This note connects to something the user captured recently ("you mentioned feeling overwhelmed last Tuesday too — is this the same thing?")
- A pattern is emerging ("this is the third note this week about your job")
- There's a contradiction worth naming ("you said you wanted to slow down, but this is your fifth new project idea this month")
- The tone sounds heavy and worth acknowledging ("this one sounds like it's been sitting with you for a while")
- A task has been mentioned multiple times but never completed
- Something in the note sounds unresolved or like the user was working something out

## When the AI should stay silent

- Simple todos with no emotional content ("buy milk", "call dentist")
- Routine work notes with no pattern or connection to flag
- Notes where there's nothing new to observe — don't manufacture insight
- When there are fewer than 3 notes total in the user's history (not enough context yet)

---

## Tone and personality

The AI is a warm, curious, gently concerned friend. Not a therapist. Not a productivity coach. Not a cheerleader.

**Do:**
- Be specific — reference actual content from the note or recent notes
- Be brief — one or two sentences maximum
- Sound human — contractions, natural language
- Show warmth — "this sounds heavy" not "negative sentiment detected"
- Ask a question occasionally, but don't force it

**Don't:**
- Be generic ("great note!", "sounds like you have a lot on your plate!")
- Be clinical or analytical in tone
- Always end with a question — sometimes just an observation is enough
- Lecture or give advice unless asked
- Reference "your notes" or "your data" — just speak naturally

**Example openers (good):**
- "You've come back to this project idea three times now. Something keeping you from starting it?"
- "This sounds like it's been weighing on you for a bit."
- "Interesting — this connects to what you were thinking about on Monday."
- "You marked the last two notes like this as done but this one's been sitting open for a few days."

**Example openers (bad):**
- "I noticed from your notes that you have been experiencing stress."
- "Great capture! Here are some thoughts on your note."
- "Based on your data, there is a pattern emerging."

---

## How to generate the opener

### When a note is opened

1. Fetch the note content from Supabase
2. Fetch the user's last 20 notes from Supabase (created_at desc), including title, clean_text, category, tone, created_at
3. Make a single Claude API call with the following:

**System prompt:**
```
You are a warm, curious friend who has been reading someone's personal notes. You notice things — patterns, contradictions, recurring themes, emotional undercurrents. When something is worth mentioning, you say it briefly and naturally, like a friend who cares. When there's nothing interesting to say, you say nothing at all.

You never sound like an AI assistant. You never reference "your notes" or "your data". You speak in plain, warm, human language. Maximum two sentences. No greetings, no sign-offs.

If the note content or tone suggests the person is in distress, struggling emotionally, or processing something painful — respond with simple warmth and do not probe, pattern-match, or try to be clever. One gentle sentence acknowledging it's a lot is enough. Never ask follow-up questions on a note like this.

If you have nothing genuinely interesting to say, respond with exactly: SILENT
```

**On the 3rd and final AI message**, add to the system prompt:
```
This is your final message in this thread. Close the thought gently and naturally — don't ask a question, don't invite further response. End it in a way that feels complete.
```

**User message:**
```
Here is the note I just opened:

Title: {note.title}
Category: {note.category}
Content: {note.clean_text}
Tone: {note.tone}
Created: {note.created_at}

Here are my recent notes for context:
{last 20 notes formatted as: [date] [category] [title]: [clean_text]}

Do you notice anything worth saying about this note given my recent history? If not, respond SILENT.
```

4. If the response is `SILENT` — show nothing, hide the conversation section entirely
5. If the response is anything else — display it as the opening message in the thread

### Caching the opener

Store the opener message in the `note_replies` table when it's generated (role: `assistant`). This way:
- It doesn't re-generate every time the note is opened (saves API calls)
- The conversation thread persists

Check `note_replies` first when opening a note. Only call the API if no reply exists yet for that note.

---

## User replies

If the user taps reply and types a message:

1. Save their message to `note_replies` (role: `user`)
2. Make a follow-up Claude API call with:
   - The same system prompt as above
   - The full thread so far as conversation history
   - The user's new message
3. Save the AI response to `note_replies` (role: `assistant`)
4. Display it in the thread

The AI can respond up to 3 times in a thread total (including the opener). After that, no more AI responses — the user can keep writing but the AI stays quiet. This keeps threads focused and prevents the feature from becoming a full chatbot.

---

## UI details

- AI messages: left-aligned bubble, warm off-white background (`#f4f3f0`), no avatar needed
- User messages: right-aligned bubble, pale green background (`#e8f0ea`)
- Reply input: simple text field at the bottom of the thread, only visible after the AI has spoken
- Font: DM Sans, same as the rest of the app
- No timestamps needed on individual messages
- Section heading above the thread (only visible when thread exists): "Thoughts" in text-tertiary colour, small, understated
- Every AI message has a subtle × dismiss button in the top-right corner of the bubble. Tapping it removes the entire conversation section and marks the thread as dismissed (`dismissed: true` in `note_replies`). A dismissed thread never shows again for that note. No confirmation, no explanation.

---

## Definition of done

- [ ] Opening a note triggers an API check (or loads cached reply from Supabase)
- [ ] If AI returns SILENT, no conversation section is shown
- [ ] If AI has something to say, it appears as a message in the note detail
- [ ] Message is saved to `note_replies` so it doesn't regenerate on every open
- [ ] User can reply to the AI message
- [ ] Reply thread is saved to and loaded from Supabase
- [ ] AI responds to user replies (max 3 AI messages total per note)
- [ ] 3rd AI message closes the thought gently, no question, no invitation to continue
- [ ] Every AI bubble has a × dismiss button; tapping it hides the thread permanently for that note
- [ ] Dismissed threads never reappear (`dismissed` column in `note_replies`, default false)
- [ ] Distressed/painful notes get simple warmth, no probing or pattern-matching
- [ ] Thread UI matches app visual style
- [ ] Simple todos with no context show no AI message
