import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) this.dialogTarget.showModal()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  dragStart({ touches }) {
    this.startY = touches[0].clientY
    this.dialogTarget.style.transition = "none"
  }

  drag({ touches }) {
    const distance = Math.max(0, touches[0].clientY - this.startY)
    this.dialogTarget.style.translate = `0 ${distance}px`
  }

  dragEnd({ changedTouches }) {
    const distance = changedTouches[0].clientY - this.startY
    this.dialogTarget.style.transition = ""
    this.dialogTarget.style.translate = ""
    if (distance > 80) this.close()
  }
}
