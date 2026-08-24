import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preserveOpenState(event) {
    const replacement = event.detail.newFrame.querySelector(`[data-filter-panel-key="${this.element.dataset.filterPanelKey}"]`)

    if (replacement) replacement.open = this.element.open
  }
}
