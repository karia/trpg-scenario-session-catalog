import { Controller } from "@hotwired/stimulus"

// 知らせを数秒だけ出して消す。
export default class extends Controller {
  static values = { duration: { type: Number, default: 3000 } }

  show({ detail }) {
    this.element.textContent = detail.message
    this.element.classList.remove("hidden")

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.classList.add("hidden"), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
