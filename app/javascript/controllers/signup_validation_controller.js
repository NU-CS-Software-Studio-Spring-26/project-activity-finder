import { Controller } from "@hotwired/stimulus"

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const MIN_PASSWORD_LENGTH = 5
const EMAIL_CHECK_DELAY_MS = 400

export default class extends Controller {
  static targets = [
    "name",
    "email",
    "password",
    "confirmation",
    "submit",
    "nameFeedback",
    "emailFeedback",
    "emailHint",
    "passwordFeedback",
    "confirmationFeedback"
  ]

  static values = {
    checkEmailUrl: String
  }

  connect() {
    this.emailAvailability = null
    this.emailCheckTimer = null
    this.emailCheckAbort = null

    this.validateAll()

    this.nameTarget.addEventListener("input", () => this.validateAll())
    this.nameTarget.addEventListener("blur", () => this.validateAll())

    this.emailTarget.addEventListener("input", () => {
      this.emailAvailability = null
      this.scheduleEmailAvailabilityCheck()
      this.validateAll()
    })
    this.emailTarget.addEventListener("blur", () => {
      this.checkEmailAvailability()
      this.validateAll()
    })

    this.passwordTarget.addEventListener("input", () => this.validateAll())
    this.passwordTarget.addEventListener("blur", () => this.validateAll())
    this.confirmationTarget.addEventListener("input", () => this.validateAll())
    this.confirmationTarget.addEventListener("blur", () => this.validateAll())

    this.element.addEventListener("submit", (event) => {
      if (!this.formValid()) {
        event.preventDefault()
        this.validateAll()
        if (!this.emailAvailabilityChecked()) {
          this.checkEmailAvailability()
        }
        this.firstInvalidField()?.focus()
      }
    })
  }

  disconnect() {
    clearTimeout(this.emailCheckTimer)
    this.emailCheckAbort?.abort()
  }

  fieldTargets() {
    return [this.nameTarget, this.emailTarget, this.passwordTarget, this.confirmationTarget]
  }

  emailAvailabilityChecked() {
    return this.emailAvailability === true
  }

  emailAvailabilityPending() {
    return this.emailAvailability === "checking" || this.emailAvailability === null
  }

  formValid() {
    return (
      this.validateName() &&
      this.validateEmail() &&
      this.validatePassword() &&
      this.validateConfirmation() &&
      this.emailAvailabilityChecked()
    )
  }

  validateAll() {
    this.validateName()
    this.validateEmail()
    this.validatePassword()
    this.validateConfirmation()
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !this.formValid()
    }
  }

  scheduleEmailAvailabilityCheck() {
    clearTimeout(this.emailCheckTimer)
    const value = this.emailTarget.value.trim()

    if (!EMAIL_PATTERN.test(value)) {
      this.clearEmailHint()
      return
    }

    this.emailCheckTimer = setTimeout(() => this.checkEmailAvailability(), EMAIL_CHECK_DELAY_MS)
  }

  async checkEmailAvailability() {
    if (!this.hasCheckEmailUrlValue) return

    const value = this.emailTarget.value.trim()
    if (!EMAIL_PATTERN.test(value)) {
      this.emailAvailability = null
      this.clearEmailHint()
      return
    }

    this.emailCheckAbort?.abort()
    this.emailCheckAbort = new AbortController()
    this.emailAvailability = "checking"
    this.showEmailHint("Checking if this email is available…")
    this.validateAll()

    try {
      const url = new URL(this.checkEmailUrlValue, window.location.origin)
      url.searchParams.set("email", value)

      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
        signal: this.emailCheckAbort.signal
      })

      if (!response.ok) {
        this.emailAvailability = null
        this.clearEmailHint()
        this.validateAll()
        return
      }

      const data = await response.json()
      if (this.emailTarget.value.trim() !== value) return

      this.emailAvailability = data.available === true
      this.clearEmailHint()
      this.validateAll()
    } catch (error) {
      if (error.name === "AbortError") return
      this.emailAvailability = null
      this.clearEmailHint()
      this.validateAll()
    }
  }

  validateName() {
    const value = this.nameTarget.value.trim()
    if (value === "") {
      return this.setInvalid(this.nameTarget, this.nameFeedbackTarget, "Name is required.")
    }
    return this.setValid(this.nameTarget, this.nameFeedbackTarget)
  }

  validateEmail() {
    const value = this.emailTarget.value.trim()
    if (value === "") {
      this.emailAvailability = null
      this.clearEmailHint()
      return this.setInvalid(this.emailTarget, this.emailFeedbackTarget, "Email is required.")
    }
    if (!EMAIL_PATTERN.test(value)) {
      this.emailAvailability = null
      this.clearEmailHint()
      return this.setInvalid(this.emailTarget, this.emailFeedbackTarget, "Enter a valid email address.")
    }

    if (this.emailAvailability === "checking") {
      this.emailTarget.classList.remove("is-valid", "is-invalid")
      this.emailTarget.setAttribute("aria-invalid", "false")
      if (this.hasEmailFeedbackTarget) {
        this.emailFeedbackTarget.textContent = ""
        this.emailFeedbackTarget.classList.add("d-none")
      }
      return false
    }

    if (this.emailAvailability === false) {
      return this.setInvalid(
        this.emailTarget,
        this.emailFeedbackTarget,
        "This email is already registered. Try logging in instead."
      )
    }

    if (this.emailAvailability === true) {
      return this.setValid(this.emailTarget, this.emailFeedbackTarget)
    }

    this.emailTarget.classList.remove("is-valid", "is-invalid")
    this.emailTarget.setAttribute("aria-invalid", "false")
    if (this.hasEmailFeedbackTarget) {
      this.emailFeedbackTarget.textContent = ""
      this.emailFeedbackTarget.classList.add("d-none")
    }
    return false
  }

  validatePassword() {
    const value = this.passwordTarget.value
    if (value.length < MIN_PASSWORD_LENGTH) {
      this.setInvalid(
        this.passwordTarget,
        this.passwordFeedbackTarget,
        `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`
      )
      return false
    }
    this.setValid(this.passwordTarget, this.passwordFeedbackTarget)
    if (this.confirmationTarget.value.length > 0) {
      this.validateConfirmation()
    }
    return true
  }

  validateConfirmation() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value
    if (confirmation === "") {
      return this.setInvalid(this.confirmationTarget, this.confirmationFeedbackTarget, "Please confirm your password.")
    }
    if (password !== confirmation) {
      return this.setInvalid(this.confirmationTarget, this.confirmationFeedbackTarget, "Passwords must match.")
    }
    return this.setValid(this.confirmationTarget, this.confirmationFeedbackTarget)
  }

  showEmailHint(message) {
    if (!this.hasEmailHintTarget) return
    this.emailHintTarget.textContent = message
    this.emailHintTarget.classList.remove("d-none")
  }

  clearEmailHint() {
    if (!this.hasEmailHintTarget) return
    this.emailHintTarget.textContent = ""
    this.emailHintTarget.classList.add("d-none")
  }

  setInvalid(field, feedback, message) {
    field.classList.add("is-invalid")
    field.classList.remove("is-valid")
    field.setAttribute("aria-invalid", "true")
    if (feedback) {
      feedback.textContent = message
      feedback.classList.remove("d-none")
    }
    return false
  }

  setValid(field, feedback) {
    const touched = field.value.length > 0
    field.classList.remove("is-invalid")
    field.setAttribute("aria-invalid", "false")
    if (touched) {
      field.classList.add("is-valid")
    } else {
      field.classList.remove("is-valid")
    }
    if (feedback) {
      feedback.textContent = ""
      feedback.classList.add("d-none")
    }
    return true
  }

  firstInvalidField() {
    return this.fieldTargets().find((field) => field.classList.contains("is-invalid"))
  }
}
