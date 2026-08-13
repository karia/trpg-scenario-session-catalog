import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const errors = [...document.querySelectorAll("[data-error-attribute][id]")]
    this.element.querySelectorAll("a[data-error-attribute]").forEach((link) => {
      const attribute = link.dataset.errorAttribute.split(".").pop()
      const error = errors.find((candidate) => candidate.dataset.errorAttribute === attribute)
      if (error) link.href = `#${error.id.replace(/_error$/, "")}`
    })
    this.element.focus()
  }
}
