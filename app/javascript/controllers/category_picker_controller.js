import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "custom", "customWrap", "output"]
  static values = { presets: Array }

  connect() {
    this.initializeFromOutput()
    this.sync()
  }

  initializeFromOutput() {
    const current = this.outputTarget.value.trim()

    if (current && this.presetsValue.includes(current)) {
      this.selectTarget.value = current
    } else if (current) {
      this.selectTarget.value = this.customOptionValue
      this.customTarget.value = current
    }
  }

  toggle() {
    this.sync()
  }

  sync() {
    const usingCustom = this.selectTarget.value === this.customOptionValue

    this.customWrapTarget.classList.toggle("d-none", !usingCustom)

    if (usingCustom) {
      this.outputTarget.value = this.customTarget.value.trim()
      this.customTarget.required = true
    } else {
      this.outputTarget.value = this.selectTarget.value
      this.customTarget.required = false
    }
  }

  beforeSubmit(event) {
    this.sync()

    if (!this.outputTarget.value) {
      event.preventDefault()

      if (this.selectTarget.value === this.customOptionValue) {
        this.customTarget.focus()
      } else {
        this.selectTarget.focus()
      }
    }
  }

  get customOptionValue() {
    return this.selectTarget.dataset.customValue
  }
}
