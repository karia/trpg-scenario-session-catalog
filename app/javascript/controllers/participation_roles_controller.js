import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scenario", "role"]
  static values = { defaults: Object, labels: Object }

  connect() {
    this.update()
  }

  update() {
    this.roleTargets.forEach((select) => this.updateSelect(select))
  }

  updateSelect(select) {
    const labels = this.labelsValue[this.scenarioTarget.value] || this.defaultsValue

    Object.entries(labels).forEach(([role, label]) => {
      const option = select.querySelector(`option[value="${role}"]`)
      if (option) option.textContent = label
    })
  }
}
