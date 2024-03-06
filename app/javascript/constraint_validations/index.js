import { isFieldElement, readValidationMessages } from "./util"
import CheckboxValidator from "./validators/checkbox_validator"

const defaultOptions = {
  disableSubmitWhenInvalid: false,
  validateOn: ["blur", "input"],
  validators: {
    checkbox: false
  }
}

export default class ConstraintValidations {
  static connect(element = document, options = {}) {
    new this(element, options).connect()
  }

  constructor(element = document, options = {}) {
    this.element = element
    this.options = { ...defaultOptions, ...options }
    this.validators = [
      new CheckboxValidator(this, this.options.validators.checkbox)
    ]
  }

  connect() {
    this.validators.forEach(validator => validator.connect())
    this.element.addEventListener("invalid", this.reportFieldValidity, { capture: true, passive: false })

    for (const eventName of this.options.validateOn) {
      this.element.addEventListener(eventName, this.clearAndReportFieldValidity, { capture: true, passive: true })
    }

    this.element.addEventListener("input", this.toggleSubmitsDisabled)

    this.reportValidationMessages(
      this.element instanceof HTMLFormElement ?
        [this.element] :
        Array.from(this.element.querySelectorAll("form"))
    )
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.reportFieldValidity, { capture: true, passive: false })

    for (const eventName of this.options.validateOn) {
      this.element.removeEventListener(eventName, this.clearAndReportFieldValidity, { capture: true, passive: true })
    }

    this.element.removeEventListener("input", this.toggleSubmitsDisabled)
    this.validators.forEach(validator => validator.disconnect())
  }

  reportFieldValidity = (event) => {
    if (isFieldElement(event.target) && this.reportValidity(event.target)) {
      event.preventDefault()

      focusFirstInvalidField(event.target.form || event.target)
    }
  }

  clearAndReportFieldValidity = ({ target }) => {
    const validator = this.validators.find(validator => validator.willValidate(target))

    if (validator) {
      validator.validate(target)
    } else if (isFieldElement(target)) {
      this.clearValidity(target)
      this.reportValidity(target)
    }
  }

  toggleSubmitsDisabled = ({ target }) => {
    if (isFieldElement(target) && this.willDisableSubmitWhenInvalid(target)) {
      disableSubmitWhenInvalid(target.form)
    }
  }

  reportValidationMessages(forms) {
    const invalidFields = []

    for (const form of forms) {
      for (const element of Array.from(form.elements).filter(isFieldElement)) {
        const serverRenderedInvalid = /true/i.test(element.getAttribute("aria-invalid"))
        const id = element.getAttribute("aria-errormessage")
        const errorMessageElement = document.getElementById(id)
        const validationMessage = errorMessageElement?.textContent

        if (validationMessage) {
          element.setCustomValidity(validationMessage)
        }

        if (validationMessage || serverRenderedInvalid) {
          this.reportValidity(element)
          invalidFields.push(element)
        }

        if (this.willDisableSubmitWhenInvalid(element)) {
          disableSubmitWhenInvalid(form)
        }
      }
    }

    const [firstInvalidField] = invalidFields
    firstInvalidField?.focus()
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
    const id = input.getAttribute("aria-errormessage")
    const validationMessage = getValidationMessage(input)
    const element = document.getElementById(id) || createValidationMessageFragment(input.form)

    if (input.form?.noValidate) {
      return false
    } else if (id && element) {
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

      if (input.form && this.willDisableSubmitWhenInvalid(input)) disableSubmitWhenInvalid(input.form)

      return true
    } else {
      return false
    }
  }
}

function focusFirstInvalidField(element) {
  if (element instanceof HTMLFormElement) {
    return Array.from(element.elements).some(field => focusFirstInvalidField(field))
  } else if (isFieldElement(element) && !element.validity.valid) {
    element.focus()
    element.scrollIntoView()
    return true
  } else {
    return false
  }
}

function disableSubmitWhenInvalid(form) {
  if (!form || form.noValidate) return

  const isValid = Array.from(form.elements).filter(isFieldElement).every(input => input.validity.valid)

  for (const element of form.elements) {
    if (element.type == "submit" && !element.formNoValidate) {
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
