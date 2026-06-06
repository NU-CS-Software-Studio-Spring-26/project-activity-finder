const BLOCKED_TERMS = [
  "asshole", "bastard", "bitch", "blowjob", "bullshit", "clit", "cock", "cunt", "damn", "dammit",
  "dick", "douche", "fag", "faggot", "fuck", "fucker", "fucking", "handjob", "hell", "hoe",
  "jackass", "jerkoff", "kys", "molest", "motherfucker", "nazi", "nigga",
  "nigger", "pedophile", "paedophile", "piss", "porn", "porno", "pornography", "pussy", "rapist",
  "rape", "raping", "retard", "shit", "slut", "tit", "tits", "twat", "whore", "wtf"
]

const BLOCKED_PHRASES = [
  "child porn",
  "child porno",
  "kill yourself"
]

const BLOCKED_PATTERN = new RegExp(
  `\\b(?:${BLOCKED_TERMS.map((term) => term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|")})\\b`,
  "i"
)

function normalizeForProfanityCheck(text) {
  let normalized = text.toLowerCase()
  normalized = normalized.replace(/@/g, "a")
  normalized = normalized.replace(/[01345$!]/g, (char) => {
    return { "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "$": "s", "!": "i" }[char]
  })
  normalized = normalized.replace(/[^a-z0-9\s]/g, " ")
  return normalized.replace(/\s+/g, " ").trim()
}

function blockedPhrase(normalized) {
  return BLOCKED_PHRASES.some((phrase) => normalized.includes(phrase))
}

export function profanityText(text) {
  if (!text || text.trim() === "") return false

  const normalized = normalizeForProfanityCheck(text)
  if (BLOCKED_PATTERN.test(normalized)) return true
  if (blockedPhrase(normalized)) return true

  return false
}

export const INAPPROPRIATE_LANGUAGE_MESSAGE = "Please use family-friendly language."
