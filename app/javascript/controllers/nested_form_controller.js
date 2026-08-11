import { Controller } from "@hotwired/stimulus"

// 入手先と配信リンクの行を増やす。増やした行は保存時にまとめて送られる。
export default class extends Controller {
  static targets = ["template", "anchor", "aliasName", "aliasSelect"]
  static values = { token: { type: String, default: "NEW_RECORD" } }

  connect() {
    this.syncAliasOptions()
  }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll(this.tokenValue, new Date().getTime())
    this.anchorTarget.insertAdjacentHTML("beforebegin", html)
    this.syncAliasOptions()
  }

  syncAliasOptions() {
    if (!this.hasAliasSelectTarget) return

    const selected = this.aliasSelectTarget.value
    const options = [new Option(this.aliasSelectTarget.dataset.baseLabel, "")]

    this.aliasNameTargets.forEach((input) => {
      const name = input.value.trim()
      if (name !== "") options.push(new Option(name, input.dataset.selectionKey))
    })

    this.aliasSelectTarget.replaceChildren(...options)
    if (options.some((option) => option.value === selected)) this.aliasSelectTarget.value = selected
  }
}
