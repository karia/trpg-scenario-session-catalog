import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit({ target }) {
    const names = Array.from(target.list.options, option => option.value)
    if (names.includes(target.value)) this.element.requestSubmit()
  }
}
