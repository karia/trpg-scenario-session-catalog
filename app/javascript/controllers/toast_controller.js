import { Controller } from "@hotwired/stimulus"

// 知らせを数秒だけ出して消す。要素は空のまま置き続ける。読み上げは live region が DOM に居ないと働かない。
export default class extends Controller {
  static values = { duration: { type: Number, default: 3000 } }

  show({ detail }) {
    this.element.replaceChildren(this.bubble(detail.message))

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.clear(), this.durationValue)
  }

  clear() {
    this.element.replaceChildren()
  }

  // Turbo は離脱時に DOM のスナップショットを取る。出したまま離れると戻ったときに残る。
  disconnect() {
    clearTimeout(this.timer)
    this.clear()
  }

  bubble(message) {
    const element = document.createElement("div")
    element.className = "border border-rule bg-ink px-4 py-3 text-sm text-paper shadow-lg"
    element.textContent = message
    return element
  }
}
