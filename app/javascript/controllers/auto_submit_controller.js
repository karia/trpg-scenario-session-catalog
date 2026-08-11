import { Controller } from "@hotwired/stimulus"

// プルダウンを選んだ時点で送る。JS が無い場合は noscript のボタンで送る。
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
