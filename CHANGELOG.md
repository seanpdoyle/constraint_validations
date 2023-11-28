# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

*   Add support for Collection `<select>` helpers

    *Sean Doyle*

*   Merge attributes into `@html_options` when available (for example, building
    `<select>` elements)

    *Sean Doyle*

*   Omit `[aria-*]`- and `[data-*]`-prefixed attributes from `[type="hidden"]`
    fields

    *Sean Doyle*

*   Drop intended support for Action Text until the engine itself adds test
    coverage.

    *Sean Doyle*

*   Eager-load classes in `CI=true` environments to guard against Zeitwerk
    auto-loading issues.

    *Sean Doyle*

*   Extend built-in Action View and Action Text classes with their
    fully-qualified class names instead of re-opening their modules or classes.

    *Sean Doyle*

*   (Re-)Validate on both `blur` and `input` events. Re-configure those values
    with the `validatesOn:` configuration key.

    *Sean Doyle*

*   Replace `application/validation_messages` JSON template with a configuration
    option.

    *Sean Doyle*

*   When a field is determined to be invalid during a client-side submission
    validation, focus the first field that is invalid. When multiple fields are
    invalid, do not focus fields after the first. When validating on `blur` events,
    **do not** focus, since focus is moving manually on behalf of the user.

    *Sean Doyle*

*   Skip `invalid` event intercepts when both `<template data-validation-message-template>` elements and `[aria-errormessage]` elements are omitted from the `<form>`

    *Sean Doyle*

*   Resolve issues with generating nested `fields` and `fields_for` identifiers.

    *Sean Doyle*
