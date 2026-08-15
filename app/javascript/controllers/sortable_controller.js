import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["row"]
  static values = { url: String, savedMessage: String, failedMessage: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      draggable: "[data-sortable-target='row']",
      handle: ".sortable-handle",
      ghostClass: "opacity-40",
      onStart: () => { this.snapshot = [...this.rowTargets] },
      onEnd: (event) => {
        if (event.oldIndex !== event.newIndex) this.save(this.snapshot)
      }
    })
  }

  disconnect() {
    this.sortable.destroy()
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

    if (!saved) this.restore(snapshot)

    this.dispatch("saved", { detail: { message: saved ? this.savedMessageValue : this.failedMessageValue } })
  }

  restore(rows) {
    rows.forEach((row) => this.element.appendChild(row))
  }
}
