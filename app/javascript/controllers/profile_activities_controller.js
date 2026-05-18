import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  static values = {
    initialTab: { type: String, default: "created" }
  }

  connect() {
    this.show(this.initialTabValue)
  }

  showCreated() {
    this.show("created")
  }

  showJoined() {
    this.show("joined")
  }

  show(which) {
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== which
    })

    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.panel === which
      tab.setAttribute("aria-selected", isActive)
      tab.classList.toggle("profile-activities-tab-active", isActive)
    })
  }
}
