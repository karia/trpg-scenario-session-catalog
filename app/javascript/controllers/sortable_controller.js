import { Controller } from "@hotwired/stimulus"

// 行を掴んで並べ替える。落とした時点で保存し、結果を toast へ渡す。
export default class extends Controller {
  static targets = ["row"]
  static values = { url: String, savedMessage: String, failedMessage: String }

  start(event) {
    this.dragged = event.currentTarget
    this.dropped = false
    // dragover のたびに DOM を動かすため、取り消されたときに戻せるよう掴む前の並びを控える。
    this.snapshot = [...this.rowTargets]
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
    this.dropped = true
  }

  finish() {
    if (!this.dragged) return

    this.dragged.classList.remove("opacity-40")
    this.dragged = null

    // Esc や表の外で離した場合は成立していない。動かした見た目だけ戻す。
    if (!this.dropped) return this.restore(this.snapshot)

    this.save(this.snapshot)
  }

  async save(snapshot) {
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

    // 保存できなかった並びを画面に残すと、サーバが持っていない順序を見せ続けることになる。
    if (!saved) this.restore(snapshot)

    this.dispatch("saved", { detail: { message: saved ? this.savedMessageValue : this.failedMessageValue } })
  }

  restore(rows) {
    rows.forEach((row) => this.element.appendChild(row))
  }
}
