import { Controller } from "@hotwired/stimulus"

// 行を掴んで並べ替える。掴んだ手を離した時点で保存し、結果を toast:show の購読者に知らせる。
export default class extends Controller {
  static targets = ["row"]
  static values = { url: String }

  start(event) {
    this.dragged = event.currentTarget
    this.dragged.classList.add("opacity-40")
    event.dataTransfer.effectAllowed = "move"
    // Firefox はデータを載せないとドラッグを始めない。
    event.dataTransfer.setData("text/plain", "")
  }

  over(event) {
    event.preventDefault()
    const row = event.currentTarget
    if (!this.dragged || row === this.dragged) return

    const box = row.getBoundingClientRect()
    const below = event.clientY > box.top + box.height / 2
    row.insertAdjacentElement(below ? "afterend" : "beforebegin", this.dragged)
  }

  drop(event) {
    event.preventDefault()
  }

  finish() {
    if (!this.dragged) return

    this.dragged.classList.remove("opacity-40")
    this.dragged = null
    this.save()
  }

  async save() {
    const body = new FormData()
    this.rowTargets.forEach((row) => body.append("scenario_ids[]", row.dataset.sortableIdParam))

    let saved = false
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content },
        body
      })
      saved = response.ok
    } catch {
      saved = false
    }

    this.dispatch("saved", { detail: { message: saved ? "保存しました" : "保存できませんでした" } })
  }
}
