import { Controller } from "@hotwired/stimulus"

// 入手先と配信リンクの行を増やす。増やした行は保存時にまとめて送られる。
export default class extends Controller {
  static targets = ["template", "anchor"]
  static values = { token: { type: String, default: "NEW_RECORD" } }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll(this.tokenValue, new Date().getTime())
    this.anchorTarget.insertAdjacentHTML("beforebegin", html)
  }
}
