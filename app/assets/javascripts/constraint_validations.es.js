function isFieldElement(element) {
  return !element.disabled && "validity" in element && element.willValidate
}

function isAriaInvalid(element) {
  return element.getAttribute("aria-invalid") === "true"
}

function readValidationMessages(input) {
  try {
    return JSON.parse(input.getAttribute("data-validation-messages")) || {}
  } catch(_) {
    return {}
  }
}

class CheckboxValidator {
  selector = "input[type=checkbox]"
  ignoringMutations = false

  constructor(constraintValidations, predicate) {
    this.constraintValidations = constraintValidations;
    this.mutationObserver = new MutationObserver(this.handleMutation);
    this.enabled = typeof predicate === "function" ?
      predicate :
      (group) => !!predicate;
  }

  connect() {
    this.element.addEventListener("invalid", this.handleInvalid, { capture: true, passive: true });
    this.mutationObserver.observe(this.element, {
      attributeFilter: ["required"],
      childList: true,
      subtree: true
    });
    this.reportValidationMessages(this.element.querySelectorAll(this.selector), isAriaInvalid);
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.handleInvalid, { capture: true, passive: true });
    this.mutationObserver.disconnect();
  }

  willValidate(target) {
    return this.willValidateGroup(checkboxGroup(target))
  }

  validate(target) {
    const checkboxesInGroup = checkboxGroup(target).filter(isCheckboxElement);
    const allRequired = checkboxesInGroup.every((checkbox) => isRequired(checkbox));
    const someChecked = checkboxesInGroup.some((checkbox) => checkbox.checked);

    if (allRequired && someChecked) {
      for (const checkbox of checkboxesInGroup) {
        this.constraintValidations.clearValidity(checkbox);
      }
    } else if (allRequired) {
      for (const checkbox of checkboxesInGroup) {
        const validationMessages = readValidationMessages(checkbox);

        checkbox.setCustomValidity(validationMessages.valueMissing);
        this.constraintValidations.reportValidity(checkbox);
      }
    }
  }

  // Private

  handleInvalid = ({ target }) => {
    const checkboxes = new Set;

    for (const element of target.form.elements) {
      if (isCheckboxElement(element) && this.willValidate(element)) {
        checkboxes.add(element);
      }
    }

    this.reportValidationMessages(checkboxes);
  }

  handleMutation = (mutationRecords) => {
    if (this.ignoringMutations) return

    for (const { addedNodes, target, type } of mutationRecords) {
      if (type === "attributes") {
        if (target.required) {
          this.swapRequiredWithAriaRequired(target);
        } else {
          target.removeAttribute("aria-required");
        }
      } else if (addedNodes.length) {
        this.reportValidationMessages(addedNodes, isAriaInvalid);
      }
    }
  }

  reportValidationMessages(nodes, willReport = () => true) {
    const requiredCheckboxes = querySelectorAllNodes(this.selector, nodes);

    for (const checkbox of requiredCheckboxes) {
      if (isRequired(checkbox)) {
        const group = checkboxGroup(checkbox);

        if (this.willValidateGroup(group)) {
          for (const checkboxInGroup of group) {
            this.swapRequiredWithAriaRequired(checkboxInGroup);

            if (willReport(checkboxInGroup)) {
              this.validate(checkboxInGroup);
            }
          }
        }
      }
    }
  }

  swapRequiredWithAriaRequired(element) {
    this.ignoringMutations = true;
    element.required = false;
    element.setAttribute("aria-required", "true");
    setTimeout(() => this.ignoringMutations = false, 0);
  }

  willValidateGroup(group) {
    return group.length > 0 && this.enabled(group)
  }

  get element() {
    return this.constraintValidations.element
  }
}

function checkboxGroup(formControl) {
  const results = new Set;
  const { name, form } = formControl;

  if (name && form instanceof HTMLFormElement) {
    const group = form.elements.namedItem(name);
    const elements = Symbol.iterator in group ?
      group :
      [group];

    for (const element of elements) {
      if (element.type === "checkbox") {
        results.add(element);
      }
    }

    if (results.size === 1 && results.has(formControl)) {
      results.clear();
    }
  }

  return Array.from(results)
}

function querySelectorAllNodes(selector, nodes, elements = new Set) {
  for (const node of nodes) {
    if (node instanceof Element) {
      if (node.matches(selector)) {
        elements.add(node);
      }

      const childNodes = querySelectorAllNodes(selector, node.children, elements);

      for (const childNode of childNodes) {
        elements.add(childNode);
      }
    }
  }

  return Array.from(elements)
}

function isCheckboxElement(element) {
  return isFieldElement(element) && element.type === "checkbox"
}

function isRequired(element) {
  return element.required || element.getAttribute("aria-required") === "true"
}

const defaultOptions = {
  disableSubmitWhenInvalid: false,
  validateOn: ["blur", "input"],
  validators: {
    checkbox: false
  }
};

class ConstraintValidations {
  static connect(element = document, options = {}) {
    new this(element, options).connect();
  }

  constructor(element = document, options = {}) {
    this.element = element;
    this.options = { ...defaultOptions, ...options };
    this.validators = [
      new CheckboxValidator(this, this.options.validators.checkbox)
    ];
  }

  connect() {
    this.validators.forEach(validator => validator.connect());
    this.element.addEventListener("invalid", this.reportFieldValidity, { capture: true, passive: false });

    for (const eventName of this.options.validateOn) {
      this.element.addEventListener(eventName, this.clearAndReportFieldValidity, { capture: true, passive: true });
    }

    this.element.addEventListener("input", this.toggleSubmitsDisabled);

    this.reportValidationMessages(
      this.element instanceof HTMLFormElement ?
        [this.element] :
        this.element.querySelectorAll("form")
    );
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.reportFieldValidity, { capture: true, passive: false });

    for (const eventName of this.options.validateOn) {
      this.element.removeEventListener(eventName, this.clearAndReportFieldValidity, { capture: true, passive: true });
    }

    this.element.removeEventListener("input", this.toggleSubmitsDisabled);
    this.validators.forEach(validator => validator.disconnect());
  }

  reportFieldValidity = (event) => {
    if (isFieldElement(event.target) && this.reportValidity(event.target)) {
      event.preventDefault();

      focusFirstInvalidField(event.target.form || event.target);
    }
  }

  clearAndReportFieldValidity = ({ target }) => {
    if (isFieldElement(target)) {
      this.clearValidity(target);

      for (const validator of this.validators) {
        if (validator.willValidate(target)) {
          validator.validate(target);
        }
      }

      this.reportValidity(target);
    }
  }

  toggleSubmitsDisabled = ({ target }) => {
    if (isFieldElement(target) && this.willDisableSubmitWhenInvalid(target)) {
      disableSubmitWhenInvalid(target.form);
    }
  }

  reportValidationMessages(forms) {
    const invalidFields = [];

    for (const form of forms) {
      for (const element of Array.from(form.elements).filter(isFieldElement)) {
        const serverRenderedInvalid = isAriaInvalid(element);
        const id = element.getAttribute("aria-errormessage");
        const errorMessageElement = document.getElementById(id);
        const validationMessage = errorMessageElement?.textContent;

        if (validationMessage) {
          element.setCustomValidity(validationMessage);
        }

        if (validationMessage || serverRenderedInvalid) {
          this.reportValidity(element);
          invalidFields.push(element);
        }

        if (this.willDisableSubmitWhenInvalid(element)) {
          disableSubmitWhenInvalid(form);
        }
      }
    }

    const [firstInvalidField] = invalidFields;
    firstInvalidField?.focus();
  }

  willDisableSubmitWhenInvalid(target) {
    return typeof this.options.disableSubmitWhenInvalid === "function" ?
      this.options.disableSubmitWhenInvalid(target) :
      !!this.options.disableSubmitWhenInvalid
  }

  clearValidity(input) {
    input.setCustomValidity("");

    this.reportValidity(input);
  }

  reportValidity(input) {
    const id = input.getAttribute("aria-errormessage");
    const validationMessage = getValidationMessage(input);
    const element = document.getElementById(id) || createValidationMessageFragment(input.form);

    if (input.form?.noValidate) {
      return false
    } else if (id && element) {
      element.id = id;
      element.innerHTML = validationMessage;

      if (validationMessage) {
        input.setCustomValidity(validationMessage);
        input.setAttribute("aria-describedby", id);
        input.setAttribute("aria-invalid", "true");
      } else {
        input.removeAttribute("aria-describedby");
        input.removeAttribute("aria-invalid");
      }

      if (!element.parentElement) {
        input.insertAdjacentElement("afterend", element);
      }

      if (input.form && this.willDisableSubmitWhenInvalid(input)) disableSubmitWhenInvalid(input.form);

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
    element.focus();
    element.scrollIntoView();
    return true
  } else {
    return false
  }
}

function disableSubmitWhenInvalid(form) {
  if (!form || form.noValidate) return

  const isValid = Array.from(form.elements).filter(isFieldElement).every(input => input.validity.valid);

  for (const element of form.elements) {
    if (element.type == "submit" && !element.formNoValidate) {
      element.disabled = !isValid;
    }
  }
}

function createValidationMessageFragment(form) {
  if (form) {
    const template = form.querySelector("[data-validation-message-template]");

    return template?.content.children[0].cloneNode()
  }
}

function getValidationMessage(input) {
  const validationMessages = Object.entries(readValidationMessages(input));

  const [ _, validationMessage ] = validationMessages.find(([ key ]) => input.validity[key]) || [ null, null ];

  return validationMessage || input.validationMessage
}

export default ConstraintValidations;
//# sourceMappingURL=constraint_validations.es.js.map
