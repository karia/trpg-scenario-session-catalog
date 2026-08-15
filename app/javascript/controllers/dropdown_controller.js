import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "menu" ]

  toggle() {
    this.menuTarget.hidden = !this.menuTarget.hidden
    this.buttonTarget.setAttribute("aria-expanded", String(!this.menuTarget.hidden))
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }
}
