import { Controller } from "@hotwired/stimulus"
import {
  TITLE_PATTERN,
  DESCRIPTION_PATTERN,
  LOCATION_PATTERN,
  SQL_LIKE_PATTERN,
  gibberishText,
  gibberishLocationText
} from "utils/readable_text"
import { profanityText, INAPPROPRIATE_LANGUAGE_MESSAGE } from "utils/profanity_filter"

const TITLE_MIN_LENGTH = 3
const TITLE_MAX_LENGTH = 120
const DESCRIPTION_MAX_LENGTH = 2000
const LOCATION_MAX_LENGTH = 200

export default class extends Controller {
  static targets = ["title", "description", "location", "submit", "titleFeedback", "descriptionFeedback", "locationFeedback"]

  connect() {
    this.fieldTouched = new Set()
    this.submitAttempted = false

    this.validateAll()

    ;[this.titleTarget, this.descriptionTarget, this.locationTarget].forEach((field) => {
      const markTouched = () => {
        this.fieldTouched.add(field)
        this.refreshFieldAppearance()
      }

      field.addEventListener("input", () => {
        markTouched()
        this.validateAll()
      })
      field.addEventListener("blur", () => {
        markTouched()
        this.validateAll()
      })
    })

    this.element.addEventListener("submit", (event) => {
      if (!this.formValid()) {
        event.preventDefault()
        this.submitAttempted = true
        this.validateAll()
        this.firstInvalidField()?.focus()
      }
    })
  }

  shouldShowFeedback(field) {
    return this.submitAttempted || this.fieldTouched.has(field)
  }

  refreshFieldAppearance() {
    this.validateTitle()
    this.validateDescription()
    this.validateLocation()
  }

  formValid() {
    return this.titleValid() && this.descriptionValid() && this.locationValid()
  }

  firstInvalidField() {
    if (!this.titleValid()) return this.titleTarget
    if (!this.descriptionValid()) return this.descriptionTarget
    if (!this.locationValid()) return this.locationTarget
    return null
  }

  validateAll() {
    this.validateTitle()
    this.validateDescription()
    this.validateLocation()
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !this.formValid()
    }
  }

  validateTitle() {
    const value = this.titleTarget.value.trim()
    let message = null

    if (value === "") {
      message = "Title is required."
    } else if (value.length < TITLE_MIN_LENGTH) {
      message = `Title must be at least ${TITLE_MIN_LENGTH} characters.`
    } else if (value.length > TITLE_MAX_LENGTH) {
      message = `Title must be ${TITLE_MAX_LENGTH} characters or fewer.`
    } else if (SQL_LIKE_PATTERN.test(value)) {
      message = "Title must be a readable activity name."
    } else if (!/[a-zA-Z]/.test(value)) {
      message = "Title must include at least one letter."
    } else if (!TITLE_PATTERN.test(value)) {
      message = "Title contains unsupported characters."
    } else if (profanityText(value)) {
      message = INAPPROPRIATE_LANGUAGE_MESSAGE
    } else if (gibberishText(value)) {
      message = "Title must be a readable activity name."
    }

    this.setFieldState(this.titleTarget, this.titleFeedbackTarget, message)
    return message === null
  }

  validateDescription() {
    const value = this.descriptionTarget.value.trim()
    let message = null

    if (value.length > DESCRIPTION_MAX_LENGTH) {
      message = `Description must be ${DESCRIPTION_MAX_LENGTH} characters or fewer.`
    } else if (value !== "" && SQL_LIKE_PATTERN.test(value)) {
      message = "Description contains unsupported content."
    } else if (value !== "" && !DESCRIPTION_PATTERN.test(value)) {
      message = "Description contains unsupported characters."
    } else if (value !== "" && profanityText(value)) {
      message = INAPPROPRIATE_LANGUAGE_MESSAGE
    } else if (value !== "" && gibberishText(value)) {
      message = "Description must use readable words and sentences."
    }

    this.setFieldState(this.descriptionTarget, this.descriptionFeedbackTarget, message)
    return message === null
  }

  validateLocation() {
    const value = this.locationTarget.value.trim()
    let message = null

    if (value.length > LOCATION_MAX_LENGTH) {
      message = `Location must be ${LOCATION_MAX_LENGTH} characters or fewer.`
    } else if (value !== "" && SQL_LIKE_PATTERN.test(value)) {
      message = "Location must be a readable place or address."
    } else if (value !== "" && !LOCATION_PATTERN.test(value)) {
      message = "Location contains unsupported characters."
    } else if (value !== "" && profanityText(value)) {
      message = INAPPROPRIATE_LANGUAGE_MESSAGE
    } else if (value !== "" && gibberishLocationText(value)) {
      message = "Location must be a readable place or address."
    }

    this.setFieldState(this.locationTarget, this.locationFeedbackTarget, message)
    return message === null
  }

  titleValid() {
    return this.validateTitle()
  }

  descriptionValid() {
    return this.validateDescription()
  }

  locationValid() {
    return this.validateLocation()
  }

  setFieldState(field, feedbackTarget, message) {
    const showFeedback = this.shouldShowFeedback(field)

    if (message && showFeedback) {
      field.classList.add("is-invalid")
      field.classList.remove("is-valid")
      field.setAttribute("aria-invalid", "true")
      if (feedbackTarget) {
        feedbackTarget.textContent = message
        feedbackTarget.classList.remove("d-none")
      }
    } else if (field.value.trim() !== "" && !message) {
      field.classList.remove("is-invalid")
      field.classList.add("is-valid")
      field.setAttribute("aria-invalid", "false")
      if (feedbackTarget) {
        feedbackTarget.textContent = ""
        feedbackTarget.classList.add("d-none")
      }
    } else {
      field.classList.remove("is-invalid", "is-valid")
      field.setAttribute("aria-invalid", "false")
      if (feedbackTarget) {
        feedbackTarget.textContent = ""
        feedbackTarget.classList.add("d-none")
      }
    }
  }
}
