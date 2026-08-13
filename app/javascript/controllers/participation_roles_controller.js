import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scenario", "role"]
  static values = { defaults: Object, labels: Object }

  connect() {
    this.observer = new MutationObserver(() => this.update())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.update()
  }

  disconnect() {
    this.observer.disconnect()
  }

  update() {
    const labels = this.labelsValue[this.scenarioTarget.value] || this.defaultsValue

    this.roleTargets.forEach((select) => {
      Object.entries(labels).forEach(([role, label]) => {
        const option = select.querySelector(`option[value="${role}"]`)
        if (option) option.textContent = label
      })
    })
  }
}
