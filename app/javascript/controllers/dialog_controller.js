import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "initialFocus"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.dialogTarget.showModal()
  }

  open() {
    this.dialogTarget.showModal()
    if (this.hasInitialFocusTarget) this.initialFocusTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  dragStart({ touches }) {
    if (matchMedia("(min-width: 40rem)").matches) return

    this.startY = touches[0].clientY
    this.dialogTarget.style.transition = "none"
  }

  drag({ touches }) {
    if (this.startY === undefined) return

    const distance = Math.max(0, touches[0].clientY - this.startY)
    this.dialogTarget.style.translate = `0 ${distance}px`
  }

  dragEnd({ changedTouches }) {
    if (this.startY === undefined) return

    const distance = changedTouches[0].clientY - this.startY
    this.startY = undefined
    this.dialogTarget.style.transition = ""
    this.dialogTarget.style.translate = ""
    if (distance > 80) this.close()
  }
}
