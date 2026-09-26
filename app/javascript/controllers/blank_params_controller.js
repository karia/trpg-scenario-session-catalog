import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  strip({ formData }) {
    for (const [name, value] of [...formData]) {
      if (value === "") formData.delete(name)
    }
  }
}
