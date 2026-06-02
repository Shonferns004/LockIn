import { GROQ_API_KEY } from '../config/env.js';

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'llama-3.1-8b-instant';

const SYSTEM_PROMPTS = {
  workout_reminder: {
    tone: 'You are a tough-love fitness coach. Respond in 1 short sentence. Be direct, no emojis, no greetings.',
    prompt: (laziness) => {
      if (laziness >= 7) return 'The user is very lazy. Be gentle, understanding, but persuasive. Remind them that even 5 minutes counts. Use soft guilt.';
      if (laziness >= 4) return 'The user has average motivation. Give a balanced push. Remind them of their goals. Be firm but encouraging.';
      return 'The user is highly motivated. Be intense and challenging. Use aggressive motivation. Short and powerful.';
    },
  },
  workout_missed: {
    tone: 'You are a disappointed but caring coach. Respond in 1 short sentence. No emojis. No greetings.',
    prompt: (laziness) => {
      if (laziness >= 7) return 'The user is very lazy and skipped training. Be sad, not angry. Use gentle disappointment. Make them feel a little guilty but not ashamed.';
      if (laziness >= 4) return 'The user has average motivation but skipped. Show moderate disappointment mixed with encouragement. Remind them tomorrow is a new chance.';
      return 'The user is motivated but still skipped. Be stark and challenging. Remind them that consistency is everything. Short punch.';
    },
  },
  workout_completed: {
    tone: 'You are a proud hype coach. Respond in 1 short sentence. No emojis. No greetings.',
    prompt: (laziness) => {
      if (laziness >= 7) return 'The user is very lazy but still finished their workout. Be very proud and warm. Celebrate this win.';
      if (laziness >= 4) return 'The user has average motivation and finished. Give solid praise. Acknowledge the effort.';
      return 'The user is highly motivated and finished. Give a short, intense hype. Respect the grind.';
    },
  },
  water_reminder: {
    tone: 'You are a caring health buddy. Respond in 1 short sentence. No emojis. No greetings.',
    prompt: (laziness) => {
      if (laziness >= 7) return 'The user likely ignores hydration. Be gentle, ask them nicely. Mention how good water feels.';
      if (laziness >= 4) return 'The user might forget to hydrate. Give a friendly practical reminder about water.';
      return 'The user is disciplined. Give a sharp reminder about performance and hydration.';
    },
  },
};

let lastMessages = {};

export async function generateMessage(type, laziness = 5) {
  const cfg = SYSTEM_PROMPTS[type];
  if (!cfg) return fallback(type, laziness);

  const lazinessKey = laziness >= 7 ? 'high' : laziness >= 4 ? 'mid' : 'low';
  const cacheKey = `${type}_${lazinessKey}`;
  const last = lastMessages[cacheKey];

  if (!GROQ_API_KEY) return fallback(type, laziness);

  try {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          { role: 'system', content: cfg.tone },
          { role: 'user', content: cfg.prompt(laziness) },
          ...(last ? [{ role: 'user', content: `Do NOT use this message: "${last}"` }] : []),
        ],
        temperature: 0.9,
        max_tokens: 40,
      }),
    });

    const data = await res.json();
    const text = data?.choices?.[0]?.message?.content?.trim();
    if (text && text.length < 120) {
      lastMessages[cacheKey] = text;
      return text;
    }
  } catch {}

  return fallback(type, laziness);
}

const FALLBACKS = {
  workout_reminder: {
    high: ['Hey... even 5 minutes is better than nothing. Try?', 'Just start. The hardest part is the first step.', 'Come on, just a little bit today. Please?'],
    mid: ['Time to earn it. Get moving.', 'Your workout is waiting. Go crush it.', "Don't overthink it. Just start."],
    low: ['Stop waiting. Train now.', 'Your future self is watching. Get up.', 'Comfort is a thief. Go train.'],
  },
  workout_missed: {
    high: ["I'm not mad, just sad. Tomorrow, ok?", "You skipped today... and that's ok. But let's not make it two.", 'Your body wanted to move today. Give it what it needs tomorrow.'],
    mid: ['You missed today. Tomorrow you come back stronger.', "One missed day won't break you. But two will. Show up tomorrow.", 'Today slipped away. Lock in tomorrow.'],
    low: ["You skipped? That's not like you. Get back on track tomorrow.", 'Missed days add up. You know better. Tomorrow, no excuses.', 'One day off is fine. Two is a trend. Stay sharp.'],
  },
  workout_completed: {
    high: ['You did it! Im proud of you.', 'One workout done. You showed up. That is everything.', 'You finished! Be proud of yourself.'],
    mid: ['Solid work. That is how you build.', 'Another one in the books. Keep stacking.', 'Nice work. Consistency is key.'],
    low: ['Locked in. Respect.', 'Work done. One step closer.', 'That is how champions train. Well done.'],
  },
  water_reminder: {
    high: ['Please drink some water. For me?', 'Your body needs water. Take a sip please.', "You haven't had water in a while. Go drink."],
    mid: ['Time to hydrate. Your body needs it.', 'Drink water now. Your muscles will thank you.', 'Hydrate. It fuels everything.'],
    low: ['Water break. Yes, right now.', 'Hydrate or die-drate. You know the drill.', "You're dehydrated. Fix it. Now."],
  },
};

function fallback(type, laziness) {
  const tier = laziness >= 7 ? 'high' : laziness >= 4 ? 'mid' : 'low';
  const pool = FALLBACKS[type]?.[tier] ?? ['Stay hydrated!'];
  const key = `${type}_${tier}`;
  let idx = Math.floor(Math.random() * pool.length);
  if (pool.length > 1 && pool[idx] === lastMessages[key]) {
    idx = (idx + 1) % pool.length;
  }
  lastMessages[key] = pool[idx];
  return pool[idx];
}
