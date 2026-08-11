import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "openButton", "closeButton"]

  open() {
    this.contentTarget.hidden = false
    this.openButtonTarget.hidden = true
    this.openButtonTarget.setAttribute("aria-expanded", "true")
    this.closeButtonTarget.focus()
  }

  close() {
    this.reset()
    this.openButtonTarget.focus()
  }

  reset() {
    this.contentTarget.hidden = true
    this.openButtonTarget.hidden = false
    this.openButtonTarget.setAttribute("aria-expanded", "false")
  }
}
