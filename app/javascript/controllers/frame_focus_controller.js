import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remember() {
    const active = document.activeElement
    this.focusedId = active?.closest("[data-return-focus]")?.dataset.returnFocus || active?.id
  }

  restore() {
    if (this.focusedId) document.getElementById(this.focusedId)?.focus()
    this.focusedId = null
  }
}
