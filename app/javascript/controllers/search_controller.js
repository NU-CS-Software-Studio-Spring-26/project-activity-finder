import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "clearButton", "inputClearButton"]

  connect() {
    this.submitTimeout = null
    this.debounceMs = 200
    this.boundSearchSubmitEnd = this.onSearchSubmitEnd.bind(this)
    this.updateButtons()

    if (this.hasFormTarget) {
      this.formTarget.addEventListener("turbo:submit-end", this.boundSearchSubmitEnd)
    }
  }

  disconnect() {
    clearTimeout(this.submitTimeout)
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener("turbo:submit-end", this.boundSearchSubmitEnd)
    }
  }

  filter() {
    const query = this.inputTarget.value.trim()
    this.updateButtons()

    if (!this.hasFormTarget) return

    // Debounce form submission so we still search on every
    // keystroke, but avoid firing a request per character typed.
    clearTimeout(this.submitTimeout)
    const scheduledQuery = query
    this.submitTimeout = setTimeout(() => {
      // Only submit if the input hasn't changed since we scheduled.
      if (this.inputTarget.value.trim() !== scheduledQuery) return
      this.formTarget.requestSubmit()
    }, this.debounceMs)
  }

  clear() {
    this.inputTarget.value = ""
    this.updateButtons()

    if (this.hasFormTarget) {
      // Always reset to a clean search when clearing.
      const pageInput = this.formTarget.querySelector('input[name="page"]')
      if (pageInput) pageInput.value = "1"
      this.formTarget.requestSubmit()
    }

    this.inputTarget.focus()
  }

  updateButtons() {
    const query = this.inputTarget.value.trim()

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.disabled = query === ""
    }
    if (this.hasInputClearButtonTarget) {
      this.inputClearButtonTarget.classList.toggle("d-none", query === "")
    }
  }

  onSearchSubmitEnd(event) {
    if (event.detail?.success === false) return
    this.restoreInputFocus()
  }

  restoreInputFocus() {
    const query = this.inputTarget.value

    this.inputTarget.focus({ preventScroll: true })
    const cursorPosition = query.length
    this.inputTarget.setSelectionRange(cursorPosition, cursorPosition)
  }
}
