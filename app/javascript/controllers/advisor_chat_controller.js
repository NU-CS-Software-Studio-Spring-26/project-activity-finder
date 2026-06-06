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

      const reply = data.reply?.trim() || this.defaultReply(data)
      this.appendMessage("assistant", reply, data.recommendations, data.draft_activity)
      this.history.push({ role: "assistant", content: reply })
    } catch {
      this.appendMessage("assistant", "I couldn’t reach the server. Check your connection and try again.")
    } finally {
      this.showTyping(false)
      this.isSending = false
      this.sendTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  appendMessage(role, text, recommendations = [], draft = null) {
    const wrapper = document.createElement("div")
    wrapper.className = `advisor-chat-message advisor-chat-message--${role}`

    const bubble = document.createElement("div")
    bubble.className = "advisor-chat-bubble"

    const paragraph = document.createElement("p")
    paragraph.textContent = text
    bubble.appendChild(paragraph)

    if (draft?.url) {
      bubble.appendChild(this.buildDraftCard(draft))
    }

    if (recommendations?.length) {
      const list = document.createElement("div")
      list.className = "advisor-chat-recommendations"
      list.setAttribute("role", "list")
      list.setAttribute("aria-label", "Recommended activities")

      recommendations.forEach((item) => {
        const card = document.createElement("article")
        card.className = "advisor-chat-rec-card"
        card.setAttribute("role", "listitem")

        const metaParts = [ item.category, item.city, item.event_date ].filter(Boolean)
        const meta = metaParts.length
          ? `<p class="advisor-chat-rec-meta">${metaParts.map((part) => this.escapeHtml(part)).join(" · ")}</p>`
          : ""

        card.innerHTML = `
          <div class="advisor-chat-rec-body">
            <h3 class="advisor-chat-rec-title">${this.escapeHtml(item.title)}</h3>
            ${meta}
            <p class="advisor-chat-rec-reason">${this.escapeHtml(item.reason)}</p>
          </div>
          <a class="advisor-chat-rec-btn btn btn-sm" href="${this.escapeHtml(item.url)}">View &amp; join</a>
        `
        list.appendChild(card)
      })

      bubble.appendChild(list)
    }

    wrapper.appendChild(bubble)
    this.messagesTarget.appendChild(wrapper)
    this.scrollToBottom()
  }

  buildDraftCard(draft) {
    const card = document.createElement("article")
    card.className = "advisor-chat-rec-card advisor-chat-draft-card"

    const metaParts = [ draft.category, draft.city, draft.event_date ].filter(Boolean)
    const meta = metaParts.length
      ? `<p class="advisor-chat-rec-meta">${metaParts.map((part) => this.escapeHtml(part)).join(" · ")}</p>`
      : ""

    card.innerHTML = `
      <div class="advisor-chat-rec-body">
        <p class="advisor-chat-rec-kicker">New activity draft</p>
        <h3 class="advisor-chat-rec-title">${this.escapeHtml(draft.title)}</h3>
        ${meta}
        <p class="advisor-chat-rec-reason">Review the details and publish it when you're ready.</p>
      </div>
      <a class="advisor-chat-rec-btn btn btn-sm" href="${this.escapeHtml(draft.url)}">Create this event</a>
    `
    return card
  }

  // Fallback copy when the model returns only a JSON block with no prose.
  defaultReply(data) {
    if (data.draft_activity) return "I've put together a draft — review and publish it below."
    if (data.recommendations?.length) return "Here's what I found for you:"
    return "Sorry, I didn't catch that. Could you tell me a bit more about what you're looking for?"
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
