import { Controller } from "@hotwired/stimulus"
import "leaflet"

const LEAFLET_ASSET_BASE = "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist"
const Leaflet = window.L || globalThis.L

export default class extends Controller {
  static targets = ["map"]
  static values = {
    lat: Number,
    lon: Number
  }

  connect() {
    this.configureLeafletIcons()
    this.renderMap()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  configureLeafletIcons() {
    if (!Leaflet || !Leaflet.Icon || !Leaflet.Icon.Default) return

    delete Leaflet.Icon.Default.prototype._getIconUrl
    Leaflet.Icon.Default.mergeOptions({
      iconRetinaUrl: `${LEAFLET_ASSET_BASE}/images/marker-icon-2x.png`,
      iconUrl: `${LEAFLET_ASSET_BASE}/images/marker-icon.png`,
      shadowUrl: `${LEAFLET_ASSET_BASE}/images/marker-shadow.png`
    })
  }

  renderMap() {
    const lat = this.latValue
    const lon = this.lonValue

    this.map = Leaflet.map(this.mapTarget, {
      scrollWheelZoom: true
    }).setView([lat, lon], 15)

    Leaflet.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    Leaflet.marker([lat, lon]).addTo(this.map)

    requestAnimationFrame(() => this.map.invalidateSize())
  }
}
