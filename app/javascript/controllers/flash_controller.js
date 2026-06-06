import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 3000 }
  }

  connect() {
    this.timeouts = []

    this.element.querySelectorAll(".alert").forEach((alertEl) => {
      const timeout = setTimeout(() => this.dismiss(alertEl), this.delayValue)
      this.timeouts.push(timeout)
    })
  }

  disconnect() {
    this.timeouts.forEach(clearTimeout)
  }

  dismiss(alertEl) {
    if (!alertEl.isConnected) return

    if (window.bootstrap?.Alert) {
      window.bootstrap.Alert.getOrCreateInstance(alertEl).close()
    } else {
      alertEl.remove()
    }
  }
}
