import { Controller } from "@hotwired/stimulus"

const DEFAULT_MAX_LENGTH = 100
const CITY_PATTERN = /^[a-zA-Z\s.'-]+$/

export default class extends Controller {
  static targets = ["input", "feedback", "hint"]

  static values = {
    maxLength: { type: Number, default: DEFAULT_MAX_LENGTH },
    required: { type: Boolean, default: true },
    popularCities: Array
  }

  connect() {
    this.validate()
    this.inputTarget.addEventListener("input", () => this.validate())
    this.inputTarget.addEventListener("blur", () => this.validate())

    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", (event) => {
        if (!this.validate()) {
          event.preventDefault()
          this.inputTarget.focus()
        }
      })
    }
  }

  validate() {
    const value = this.inputTarget.value.trim()
    const errors = []

    if (this.requiredValue && value === "") {
      errors.push("City is required.")
    }

    if (value.length > this.maxLengthValue) {
      errors.push(`City must be ${this.maxLengthValue} characters or fewer.`)
    }

    if (value !== "" && !CITY_PATTERN.test(value)) {
      errors.push("Use letters, spaces, and common punctuation only (e.g. St. Louis).")
    }

    if (value !== "" && this.popularCitiesValue?.length > 0) {
      const match = this.popularCitiesValue.some(
        (city) => city.toLowerCase() === value.toLowerCase()
      )
      if (!match && this.hasHintTarget) {
        this.hintTarget.textContent = "Tip: pick a suggested city or type your own."
        this.hintTarget.classList.remove("d-none")
      } else if (this.hasHintTarget) {
        this.hintTarget.classList.add("d-none")
      }
    }

    if (errors.length > 0) {
      this.setInvalid(errors[0])
      return false
    }

    this.setValid()
    return true
  }

  setInvalid(message) {
    this.inputTarget.classList.add("is-invalid")
    this.inputTarget.classList.remove("is-valid")
    this.inputTarget.setAttribute("aria-invalid", "true")
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = message
      this.feedbackTarget.classList.remove("d-none")
    }
  }

  setValid() {
    const touched = this.inputTarget.value.trim().length > 0
    this.inputTarget.classList.remove("is-invalid")
    this.inputTarget.setAttribute("aria-invalid", "false")
    if (touched) {
      this.inputTarget.classList.add("is-valid")
    } else {
      this.inputTarget.classList.remove("is-valid")
    }
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = ""
      this.feedbackTarget.classList.add("d-none")
    }
  }
}
