class ConstraintValidations {
  static connect(element = document, options = {}) {
    new this(element, options).connect()
  }

  constructor(element = document, options = {}) {
    this.element = element
    this.options = options
  }

  connect() {
    this.element.addEventListener("invalid", this.reportFieldValidity, { capture: true, passive: false })
    this.element.addEventListener("blur", this.clearAndReportFieldValidity, { capture: true, passive: true })
    this.element.addEventListener("input", this.toggleSubmitsDisabled)

    this.reportValidationMessages()
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.reportFieldValidity)
    this.element.removeEventListener("blur", this.clearAndReportFieldValidity)
    this.element.removeEventListener("input", this.toggleSubmitsDisabled)
  }

  reportFieldValidity = (event) => {
    if (isFieldElement(event.target)) {
      this.reportValidity(event.target)

      event.preventDefault()
    }
  }

  clearAndReportFieldValidity = ({ target }) => {
    if (isFieldElement(target)) {
      this.clearValidity(target)
      this.reportValidity(target)
    }
  }

  toggleSubmitsDisabled = ({ target }) => {
    if (isFieldElement(target) && this.willDisableSubmitWhenInvalid(target)) {
      disableSubmitWhenInvalid(target.form)
    }
  }

  reportValidationMessages() {
    for (const invalidElement of this.element.querySelectorAll("[aria-errormessage]")) {
      const id = invalidElement.getAttribute("aria-errormessage")
      const validationMessage = document.getElementById(id)

      if (validationMessage) {
        invalidElement.setCustomValidity(validationMessage.textContent)
      }
    }
  }

  willDisableSubmitWhenInvalid(target) {
    return typeof this.options.disableSubmitWhenInvalid === "function" ?
      this.options.disableSubmitWhenInvalid(target) :
      !!this.options.disableSubmitWhenInvalid
  }

  clearValidity(input) {
    input.setCustomValidity("")

    this.reportValidity(input)
  }

  reportValidity(input) {
    if (input.form?.noValidate) return

    const id = input.getAttribute("aria-errormessage")
    const validationMessage = getValidationMessage(input)
    const element = document.getElementById(id) || createValidationMessageFragment(input.form)

    if (id && element) {
      element.id = id
      element.innerHTML = validationMessage

      if (validationMessage) {
        input.setCustomValidity(validationMessage)
        input.setAttribute("aria-describedby", id)
        input.setAttribute("aria-invalid", "true")
      } else {
        input.removeAttribute("aria-describedby")
        input.removeAttribute("aria-invalid")
      }

      if (!element.parentElement) {
        input.insertAdjacentElement("afterend", element)
      }
    }

    if (input.form && this.willDisableSubmitWhenInvalid(input)) disableSubmitWhenInvalid(input.form)
  }
}

function disableSubmitWhenInvalid(form) {
  if (!form || form.noValidate) return

  const isValid = Array.from(form.elements).filter(isFieldElement).every(input => input.validity.valid)

  for (const element of form.elements) {
    if (element.type == "submit") {
      element.disabled = !isValid
    }
  }
}

function createValidationMessageFragment(form) {
  if (form) {
    const template = form.querySelector("[data-validation-message-template]")

    return template?.content.children[0].cloneNode()
  }
}

function getValidationMessage(input) {
  const validationMessages = Object.entries(readValidationMessages(input))

  const [ _, validationMessage ] = validationMessages.find(([ key ]) => input.validity[key]) || [ null, null ]

  return validationMessage || input.validationMessage
}

function readValidationMessages(input) {
  try {
    return JSON.parse(input.getAttribute("data-validation-messages")) || {}
  } catch(_) {
    return {}
  }
}

function isFieldElement(element) {
  return [ HTMLButtonElement, HTMLInputElement, HTMLObjectElement, HTMLOutputElement, HTMLSelectElement, HTMLTextAreaElement ].some(field => element instanceof field)
}
