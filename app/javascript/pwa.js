let serviceWorkerRegistered = false

function registerServiceWorker() {
  if (serviceWorkerRegistered || !("serviceWorker" in navigator)) return

  serviceWorkerRegistered = true
  navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {
    serviceWorkerRegistered = false
  })
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", registerServiceWorker)
} else {
  registerServiceWorker()
}
