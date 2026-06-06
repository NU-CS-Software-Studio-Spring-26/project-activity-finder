const MIN_VOWEL_RATIO = 0.22
const LONG_TOKEN_MIN_LENGTH = 10
const LONG_TOKEN_MIN_VOWEL_RATIO = 0.28
const BIGRAM_CHECK_MIN_LENGTH = 8
const MIN_TOKEN_LENGTH = 3
const CONSONANT_CLUSTER_PATTERN = /[bcdfghjklmnpqrstvwxz]{5,}/i
const TOKEN_CONSONANT_CLUSTER_PATTERN = /[bcdfghjklmnpqrstvwxz]{4,}/i
const REPEATED_CHAR_PATTERN = /(.)\1{4,}/
const KEYBOARD_ROWS = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
const TOKEN_SPLIT_PATTERN = /[\s,.;:!?\-\/&()]+/
const LOCATION_ABBREVIATIONS = new Set([
  "st", "str", "street", "rd", "road", "dr", "drv", "drive", "ln", "lane", "blvd", "boulevard",
  "ave", "av", "avenue", "ct", "court", "pl", "place", "sq", "square", "cir", "circle",
  "ter", "terrace", "pkwy", "parkway", "hwy", "highway", "expy", "fwy",
  "n", "s", "e", "w", "ne", "nw", "se", "sw",
  "apt", "unit", "ste", "suite", "bldg", "fl", "rm", "po", "box"
])
const COMMON_BIGRAMS = new Set([
  "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd", "ti", "es", "or", "te", "of", "ed", "is", "it",
  "al", "ar", "st", "to", "nt", "ng", "se", "ha", "as", "ou", "le", "me", "de", "co", "ne", "ri", "io", "ve",
  "ly", "ra", "ro", "li", "ce", "ea", "ch", "sh", "wh", "la", "ma", "na", "no", "us", "tr", "pr", "pl", "gr",
  "br", "fr", "fl", "bl", "cl", "gl", "sl", "sp", "sk", "sc", "sm", "sn", "sw", "ph", "gh", "ng", "mp", "ck",
  "ld", "lf", "lk", "lm", "lp", "lt", "ct", "pt", "rt", "rd", "rm", "rn", "rs", "ry", "cr", "dr", "el", "em",
  "et", "hi", "ho", "ic", "id", "ig", "il", "im", "ir", "iv", "ob", "oc", "od", "ol", "om", "op", "ot", "ov",
  "ow", "ub", "uc", "ud", "ul", "um", "un", "up", "ur", "ut", "ay", "ew", "oo", "ea", "ai", "ee"
])

export const TITLE_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9\s.\-'&,!?():;\/+]*$/
export const DESCRIPTION_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9\s.\-'&,!?():;\/+\n]*$/
export const LOCATION_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9\s.,#'\-\/&():]*$/
export const SQL_LIKE_PATTERN = /\b(select|insert|update|delete|drop|union|alter|create|truncate)\b[\s\S]{0,80}?\b(from|into|table|database)\b/i

function keyboardMash(text) {
  const downcased = text.toLowerCase()

  return KEYBOARD_ROWS.some((row) => {
    for (let index = 0; index <= row.length - 4; index += 1) {
      const sequence = row.slice(index, index + 4)
      const reversed = sequence.split("").reverse().join("")

      if (downcased.includes(sequence) || downcased.includes(reversed)) {
        return true
      }
    }

    return false
  })
}

function vowelCount(text) {
  return (text.match(/[aeiouy]/gi) || []).length
}

function extractBigrams(tokenLetters) {
  const lower = tokenLetters.toLowerCase()
  const bigrams = []

  for (let index = 0; index < lower.length - 1; index += 1) {
    const bigram = lower.slice(index, index + 2)
    if (/^[a-z]{2}$/.test(bigram)) {
      bigrams.push(bigram)
    }
  }

  return bigrams
}

function lacksCommonBigrams(tokenLetters) {
  if (tokenLetters.length < BIGRAM_CHECK_MIN_LENGTH) return false

  const bigrams = extractBigrams(tokenLetters)
  if (bigrams.length === 0) return false

  const uniqueCommon = new Set(bigrams.filter((bigram) => COMMON_BIGRAMS.has(bigram)))
  const required = Math.max(3, Math.floor(tokenLetters.length / 4))

  return uniqueCommon.size < required
}

function gibberishToken(token, { location = false } = {}) {
  const tokenLetters = token.replace(/[^a-zA-Z]/g, "")
  if (tokenLetters.length < MIN_TOKEN_LENGTH) return false
  if (tokenLetters === tokenLetters.toUpperCase()) return false

  const tokenVowels = vowelCount(tokenLetters)
  if (tokenVowels === 0) return true

  const vowelRatio = tokenVowels / tokenLetters.length

  if (tokenLetters.length >= LONG_TOKEN_MIN_LENGTH && vowelRatio < LONG_TOKEN_MIN_VOWEL_RATIO) {
    return true
  }

  if (tokenLetters.length >= 6 && CONSONANT_CLUSTER_PATTERN.test(token)) {
    if (location && tokenVowels >= 2) return false

    return true
  }

  if (tokenLetters.length >= 5 &&
      TOKEN_CONSONANT_CLUSTER_PATTERN.test(token) &&
      vowelRatio < 0.35) {
    if (location && tokenVowels >= 2) return false

    return true
  }

  if (lacksCommonBigrams(tokenLetters)) {
    return true
  }

  return false
}

function isLocationAbbreviation(token) {
  const tokenLetters = token.replace(/[^a-zA-Z]/g, "")
  if (tokenLetters.length === 0) return false

  return LOCATION_ABBREVIATIONS.has(tokenLetters.toLowerCase())
}

function gibberishTextWithSkips(text, shouldSkipToken, { location = false } = {}) {
  if (!text || text.trim() === "") return false

  if (REPEATED_CHAR_PATTERN.test(text)) return true
  if (keyboardMash(text)) return true

  const tokens = text.split(TOKEN_SPLIT_PATTERN).filter((token) => token.trim() !== "")
  const tokensToCheck = tokens.length > 0 ? tokens : [text]

  if (tokensToCheck.some((token) => !shouldSkipToken(token) && gibberishToken(token, { location }))) {
    return true
  }

  const letters = text.replace(/[^a-zA-Z]/g, "")
  if (letters.length < 5) return false

  const lettersVowelCount = vowelCount(letters)
  if (lettersVowelCount === 0) return true
  if (!location && lettersVowelCount / letters.length < MIN_VOWEL_RATIO) return true
  if (CONSONANT_CLUSTER_PATTERN.test(text) && !location) return true

  return false
}

export function gibberishLocationText(text) {
  return gibberishTextWithSkips(text, isLocationAbbreviation, { location: true })
}

export function gibberishText(text) {
  return gibberishTextWithSkips(text, () => false)
}
