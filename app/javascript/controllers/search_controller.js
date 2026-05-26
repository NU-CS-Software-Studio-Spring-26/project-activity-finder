import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "card", "emptyState", "clearButton", "inputClearButton", "form"]

  connect() {
    this.filter()
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visibleCount = 0

    this.cardTargets.forEach((card) => {
      const title = card.dataset.activityTitle || ""
      const isMatch = query === "" || title.includes(query)
      card.classList.toggle("d-none", !isMatch)

      if (isMatch) visibleCount += 1
    })

    this.emptyStateTarget.classList.toggle("d-none", visibleCount > 0)
    this.clearButtonTarget.disabled = query === ""
    this.inputClearButtonTarget.classList.toggle("d-none", query === "")
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()

    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }

    this.inputTarget.focus()
  }
}
