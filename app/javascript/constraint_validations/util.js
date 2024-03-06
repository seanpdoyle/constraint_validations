export function isFieldElement(element) {
  return !element.disabled && "validity" in element && element.willValidate
}

export function readValidationMessages(input) {
  try {
    return JSON.parse(input.getAttribute("data-validation-messages")) || {}
  } catch(_) {
    return {}
  }
}
