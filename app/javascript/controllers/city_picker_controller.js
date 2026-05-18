import { Controller } from "@hotwired/stimulus"

const CITY_MAX_LENGTH = 100
const CITY_PATTERN = /^[a-zA-Z\s.'-]+$/

/**
 * Custom city menu (no Bootstrap Dropdown JS) — avoids Turbo/Popper lifecycle bugs
 * where the toggle stops responding after submit.
 */
export default class extends Controller {
  static targets = ["form", "cityInput", "label", "searchInput", "list", "toggle", "menu", "dropdownRoot", "searchFeedback"]

  static values = {
    popularCities: Array,
    initialCity: String
  }

  connect() {
    this.isMenuOpen = false
    this.openMenuFrame = null
    this.boundDocClick = this.onDocumentClick.bind(this)
    this.boundEscape = this.onEscape.bind(this)

    this.selectedCity = (this.initialCityValue || "").trim()
    this.syncHiddenInput()
    this.renderLabel()
    this.renderPopularList()
    this.closeMenuOnly()

    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener("input", () => this.validateSearchInput())
      this.searchInputTarget.addEventListener("blur", () => this.validateSearchInput())
    }
  }

  disconnect() {
    this.closeMenuOnly()
  }

  toggleMenu(event) {
    event.preventDefault()
    event.stopPropagation()
    if (!this.hasMenuTarget || !this.hasToggleTarget) return

    if (this.isMenuOpen) {
      this.closeMenuOnly()
      return
    }
    this.openMenu()
  }

  openMenu() {
    this.isMenuOpen = true
    this.menuTarget.classList.add("show")
    this.toggleTarget.setAttribute("aria-expanded", "true")

    // Defer so the opening click does not bubble to the new listener in the same tick
    this.openMenuFrame = requestAnimationFrame(() => {
      this.openMenuFrame = null
      document.addEventListener("click", this.boundDocClick, false)
      document.addEventListener("keydown", this.boundEscape, true)
    })
  }

  closeMenuOnly() {
    if (this.openMenuFrame != null) {
      cancelAnimationFrame(this.openMenuFrame)
      this.openMenuFrame = null
    }

    document.removeEventListener("click", this.boundDocClick, false)
    document.removeEventListener("keydown", this.boundEscape, true)

    this.isMenuOpen = false

    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("show")
    }
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }

  onDocumentClick(event) {
    if (!this.isMenuOpen) return
    if (this.hasDropdownRootTarget && this.dropdownRootTarget.contains(event.target)) {
      return
    }
    this.closeMenuOnly()
  }

  onEscape(event) {
    if (!this.isMenuOpen) return
    if (event.key !== "Escape") return
    event.preventDefault()
    event.stopPropagation()
    this.closeMenuOnly()
    this.toggleTarget?.focus()
  }

  syncHiddenInput() {
    if (!this.hasCityInputTarget) return
    this.cityInputTarget.value = this.selectedCity
  }

  renderLabel() {
    if (!this.hasLabelTarget) return
    this.labelTarget.textContent = this.selectedCity || "All cities"
  }

  filterList() {
    this.renderPopularList()
  }

  renderPopularList() {
    if (!this.hasListTarget) return

    const q = this.hasSearchInputTarget ? this.searchInputTarget.value.trim().toLowerCase() : ""
    const cities = (this.popularCitiesValue || []).filter((city) =>
      q === "" ? true : city.toLowerCase().includes(q)
    )

    this.listTarget.innerHTML = ""

    const allBtn = document.createElement("button")
    allBtn.type = "button"
    allBtn.className = "dropdown-item city-picker-city-item"
    allBtn.textContent = "All cities"
    allBtn.addEventListener("click", () => this.clearFilter())
    this.listTarget.appendChild(allBtn)

    if (cities.length === 0) {
      return
    }

    cities.forEach((city) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "dropdown-item city-picker-city-item"
      btn.textContent = city
      btn.addEventListener("click", () => this.pickCity(city))
      this.listTarget.appendChild(btn)
    })
  }

  clearFilter() {
    this.selectedCity = ""
    this.syncHiddenInput()
    this.renderLabel()
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
    }
    this.closeMenuOnly()
    this.renderPopularList()
    this.formTarget.requestSubmit()
  }

  pickCity(city) {
    const trimmed = (city || "").trim()
    if (!trimmed) return

    this.selectedCity = trimmed
    this.syncHiddenInput()
    this.renderLabel()
    this.closeMenuOnly()
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
    }
    this.renderPopularList()
    this.formTarget.requestSubmit()
  }

  applySearch(event) {
    if (event?.preventDefault) event.preventDefault()
    if (!this.hasSearchInputTarget) return
    const q = this.searchInputTarget.value.trim()
    if (!q) {
      this.showSearchError("Enter a city name.")
      this.searchInputTarget.focus()
      return
    }
    if (!this.validateSearchInput()) {
      this.searchInputTarget.focus()
      return
    }
    this.pickCity(q)
  }

  validateSearchInput() {
    if (!this.hasSearchInputTarget) return true
    const q = this.searchInputTarget.value.trim()
    if (q === "") {
      this.clearSearchError()
      return true
    }

    if (q.length > CITY_MAX_LENGTH) {
      this.showSearchError(`City must be ${CITY_MAX_LENGTH} characters or fewer.`)
      return false
    }

    if (!CITY_PATTERN.test(q)) {
      this.showSearchError("Use letters, spaces, and common punctuation only.")
      return false
    }

    this.clearSearchError()
    return true
  }

  showSearchError(message) {
    if (!this.hasSearchInputTarget) return
    this.searchInputTarget.classList.add("is-invalid")
    this.searchInputTarget.setAttribute("aria-invalid", "true")
    if (this.hasSearchFeedbackTarget) {
      this.searchFeedbackTarget.textContent = message
      this.searchFeedbackTarget.classList.remove("d-none")
    }
  }

  clearSearchError() {
    if (!this.hasSearchInputTarget) return
    this.searchInputTarget.classList.remove("is-invalid")
    this.searchInputTarget.setAttribute("aria-invalid", "false")
    if (this.hasSearchFeedbackTarget) {
      this.searchFeedbackTarget.textContent = ""
      this.searchFeedbackTarget.classList.add("d-none")
    }
  }
}
