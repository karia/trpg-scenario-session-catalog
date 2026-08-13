import { Controller } from "@hotwired/stimulus"

// 入手先と配信リンクの行を増やす。増やした行は保存時にまとめて送られる。
export default class extends Controller {
  static targets = ["template", "anchor", "aliasRow", "aliasSelect"]
  static values = { token: { type: String, default: "NEW_RECORD" } }

  connect() {
    this.syncAliasOptions()
  }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll(this.tokenValue, new Date().getTime())
    this.anchorTarget.insertAdjacentHTML("beforebegin", html)
    this.syncAliasOptions()
    this.dispatch("added")
  }

  syncAliasOptions() {
    if (!this.hasAliasSelectTarget) return

    const selected = this.aliasSelectTarget.value
    const options = [new Option(this.aliasSelectTarget.dataset.baseLabel, "")]

    this.aliasRowTargets.forEach((row) => {
      const name = row.querySelector("[data-alias-name]")
      const visible = row.querySelector("[data-alias-visible]")
      const destroy = row.querySelector("[data-alias-destroy]")

      if (name.value.trim() !== "" && visible.checked && !destroy.checked) {
        options.push(new Option(name.value.trim(), name.dataset.selectionKey))
      }
    })

    this.aliasSelectTarget.replaceChildren(...options)
    if (options.some((option) => option.value === selected)) this.aliasSelectTarget.value = selected
  }
}
