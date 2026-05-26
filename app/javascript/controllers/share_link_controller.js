import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  copy() {
    const url = this.inputTarget.value
    navigator.clipboard.writeText(url).then(() => {
      const btn = this.buttonTarget
      const original = btn.textContent
      btn.textContent = "Copied!"
      btn.classList.add("btn-success")
      btn.classList.remove("btn-outline-secondary")
      setTimeout(() => {
        btn.textContent = original
        btn.classList.remove("btn-success")
        btn.classList.add("btn-outline-secondary")
      }, 2000)
    }).catch(() => {
      this.inputTarget.select()
      document.execCommand("copy")
    })
  }
}
