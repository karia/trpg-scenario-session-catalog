import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  start(event) {
    const submitter = event.detail.formSubmission.submitter
    if (!submitter) return

    submitter.dataset.originalLabel = submitter.value || submitter.textContent
    if (submitter.tagName === "INPUT") submitter.value = "送信中…"
    else submitter.textContent = "送信中…"
    submitter.disabled = true
    this.messageTarget.textContent = "送信しています"
  }

  finish(event) {
    const submitter = event.detail.formSubmission.submitter
    if (submitter?.dataset.originalLabel) {
      if (submitter.tagName === "INPUT") submitter.value = submitter.dataset.originalLabel
      else submitter.textContent = submitter.dataset.originalLabel
      submitter.disabled = false
      delete submitter.dataset.originalLabel
    }
    this.messageTarget.textContent = event.detail.success ? "送信が完了しました" : "送信できませんでした"
  }
}
