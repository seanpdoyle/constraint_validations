import { isAriaInvalid, isFieldElement, readValidationMessages } from "../util"

export default class {
  selector = "input[type=checkbox]"
  ignoringMutations = false

  constructor(constraintValidations, predicate) {
    this.constraintValidations = constraintValidations
    this.mutationObserver = new MutationObserver(this.handleMutation)
    this.enabled = typeof predicate === "function" ?
      predicate :
      (group) => !!predicate
  }

  connect() {
    this.element.addEventListener("invalid", this.handleInvalid, { capture: true, passive: true })
    this.mutationObserver.observe(this.element, {
      attributeFilter: ["required"],
      childList: true,
      subtree: true
    })
    this.reportValidationMessages(this.element.querySelectorAll(this.selector), isAriaInvalid)
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.handleInvalid, { capture: true, passive: true })
    this.mutationObserver.disconnect()
  }

  willValidate(target) {
    return this.willValidateGroup(checkboxGroup(target))
  }

  validate(target) {
    const checkboxesInGroup = checkboxGroup(target).filter(isCheckboxElement)
    const allRequired = checkboxesInGroup.every((checkbox) => isRequired(checkbox))
    const someChecked = checkboxesInGroup.some((checkbox) => checkbox.checked)

    if (allRequired && someChecked) {
      for (const checkbox of checkboxesInGroup) {
        this.constraintValidations.clearValidity(checkbox)
      }
    } else if (allRequired) {
      for (const checkbox of checkboxesInGroup) {
        const validationMessages = readValidationMessages(checkbox)

        checkbox.setCustomValidity(validationMessages.valueMissing)
        this.constraintValidations.reportValidity(checkbox)
      }
    }
  }

  // Private

  handleInvalid = ({ target }) => {
    const checkboxes = new Set

    for (const element of target.form.elements) {
      if (isCheckboxElement(element) && this.willValidate(element)) {
        checkboxes.add(element)
      }
    }

    this.reportValidationMessages(checkboxes)
  }

  handleMutation = (mutationRecords) => {
    if (this.ignoringMutations) return

    for (const { addedNodes, target, type } of mutationRecords) {
      if (type === "attributes") {
        if (target.required) {
          this.swapRequiredWithAriaRequired(target)
        } else {
          target.removeAttribute("aria-required")
        }
      } else if (addedNodes.length) {
        this.reportValidationMessages(addedNodes, isAriaInvalid)
      }
    }
  }

  reportValidationMessages(nodes, willReport = () => true) {
    const requiredCheckboxes = querySelectorAllNodes(this.selector, nodes)

    for (const checkbox of requiredCheckboxes) {
      if (isRequired(checkbox)) {
        const group = checkboxGroup(checkbox)

        if (this.willValidateGroup(group)) {
          for (const checkboxInGroup of group) {
            this.swapRequiredWithAriaRequired(checkboxInGroup)

            if (willReport(checkboxInGroup)) {
              this.validate(checkboxInGroup)
            }
          }
        }
      }
    }
  }

  swapRequiredWithAriaRequired(element) {
    this.ignoringMutations = true
    element.required = false
    element.setAttribute("aria-required", "true")
    setTimeout(() => this.ignoringMutations = false, 0)
  }

  willValidateGroup(group) {
    return group.length > 0 && this.enabled(group)
  }

  get element() {
    return this.constraintValidations.element
  }
}

function checkboxGroup(formControl) {
  const results = new Set
  const { name, form } = formControl

  if (name && form instanceof HTMLFormElement) {
    const group = form.elements.namedItem(name)
    const elements = Symbol.iterator in group ?
      group :
      [group]

    for (const element of elements) {
      if (element.type === "checkbox") {
        results.add(element)
      }
    }

    if (results.size === 1 && results.has(formControl)) {
      results.clear()
    }
  }

  return Array.from(results)
}

function querySelectorAllNodes(selector, nodes, elements = new Set) {
  for (const node of nodes) {
    if (node instanceof Element) {
      if (node.matches(selector)) {
        elements.add(node)
      }

      const childNodes = querySelectorAllNodes(selector, node.children, elements)

      for (const childNode of childNodes) {
        elements.add(childNode)
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
