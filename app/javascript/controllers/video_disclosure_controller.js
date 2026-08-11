import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "openButton"]

  open() {
    this.contentTarget.hidden = false
    this.openButtonTarget.hidden = true
    this.openButtonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.contentTarget.hidden = true
    this.openButtonTarget.hidden = false
    this.openButtonTarget.setAttribute("aria-expanded", "false")
    this.openButtonTarget.focus()
  }
}
