import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "fab", "panel", "messages", "form", "input", "send", "typing" ]
  static values = { url: String, open: Boolean }

  connect() {
    this.history = []
    this.boundEscape = this.onEscape.bind(this)
    document.addEventListener("keydown", this.boundEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscape)
  }

  toggle() {
    this.openValue ? this.close() : this.open()
  }

  open() {
    this.openValue = true
    this.panelTarget.hidden = false
    this.panelTarget.classList.add("is-open")
    this.fabTarget.setAttribute("aria-expanded", "true")
    this.fabTarget.classList.add("is-hidden")
    this.inputTarget.focus()
  }

  close() {
    this.openValue = false
    this.panelTarget.classList.remove("is-open")
    this.fabTarget.setAttribute("aria-expanded", "false")
    this.fabTarget.classList.remove("is-hidden")
    window.setTimeout(() => {
      if (!this.openValue) this.panelTarget.hidden = true
    }, 220)
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  resize() {
    const field = this.inputTarget
    field.style.height = "auto"
    field.style.height = `${Math.min(field.scrollHeight, 120)}px`
  }

  async send(event) {
    event.preventDefault()

    const text = this.inputTarget.value.trim()
    if (!text || this.isSending) return

    this.isSending = true
    this.sendTarget.disabled = true

    this.appendMessage("user", text)
    this.history.push({ role: "user", content: text })
    this.inputTarget.value = ""
    this.resize()
    this.showTyping(true)

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ messages: this.history })
      })

      const data = await response.json()

      if (!response.ok) {
        this.appendMessage("assistant", data.error || "Sorry, something went wrong. Please try again.")
        return
      }

      this.appendMessage("assistant", data.reply, data.recommendations)
      this.history.push({ role: "assistant", content: data.reply })
    } catch {
      this.appendMessage("assistant", "I couldn’t reach the server. Check your connection and try again.")
    } finally {
      this.showTyping(false)
      this.isSending = false
      this.sendTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  appendMessage(role, text, recommendations = []) {
    const wrapper = document.createElement("div")
    wrapper.className = `advisor-chat-message advisor-chat-message--${role}`

    const bubble = document.createElement("div")
    bubble.className = "advisor-chat-bubble"

    const paragraph = document.createElement("p")
    paragraph.textContent = text
    bubble.appendChild(paragraph)

    if (recommendations?.length) {
      const list = document.createElement("div")
      list.className = "advisor-chat-recommendations"

      recommendations.forEach((item) => {
        const card = document.createElement("a")
        card.className = "advisor-chat-rec-card"
        card.href = item.url
        card.innerHTML = `
          <span class="advisor-chat-rec-title">${this.escapeHtml(item.title)}</span>
          <span class="advisor-chat-rec-reason">${this.escapeHtml(item.reason)}</span>
          <span class="advisor-chat-rec-cta">View activity →</span>
        `
        list.appendChild(card)
      })

      bubble.appendChild(list)
    }

    wrapper.appendChild(bubble)
    this.messagesTarget.appendChild(wrapper)
    this.scrollToBottom()
  }

  showTyping(visible) {
    this.typingTarget.hidden = !visible
    if (visible) this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  onEscape(event) {
    if (event.key === "Escape" && this.openValue) this.close()
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
  }
}
