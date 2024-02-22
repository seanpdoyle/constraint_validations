export function readValidationMessages(input) {
  try {
    return JSON.parse(input.getAttribute("data-validation-messages")) || {}
  } catch(_) {
    return {}
  }
}
