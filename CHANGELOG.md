# Changelog

## v0.10.x (2023-01-07)

### Enhancements

* [Parameter] Extra option `ignore_nil` for `load/2` and `dump/2` functions.
* [Parameter.Types] New `array` type.
* [Parameter.Schema] Support for nested type on `map` and `array`.
* Improved code test coverage to 100%.

## v0.9.x (2023-01-04)

### Enhancements

* [Parameter.Field] Support for `on_load/2` and `on_dump/2` functions in field definition.

## v0.8.x (2022-12-10)

### Enhancements

* [Parameter.Schema] Supports `compile/1` function for compiling runtime schemas.
* [Parameter] `load/3`, `validate/3` and `dump/3` now support evaluating parameters using runtime schemas.
* [Parameter.Validators] Improved `length/2` validator to support `min` and/or `max` attributes. Before it was only accepting both.

### Bug fixes
* [Parameter] Fix a bug where `load/3` and `validate/3` was evaluating the `validator` option wrongly.
* [Parameter.Field] Validator typespec.
* [Parameter.Enum] Fix evaluation of enum values inside `Enum` macro

## v0.7.x (2022-11-07)

### Enhancements

* [Parameter] New `validate/3` function
* [Parameter] Supports for `load/3` parsing maps with atom keys
* [Parameter.Schema] Supports for `fields_required` module attribute on schema

### Bug fixes

* [Parameter] `dump/3` function to load the value to be dumped
* [Parameter] consider basic types when loading, dumping or validating a schema
* [Parameter.Field] remove compile time verification for custom types

## v0.6.x (2022-11-06)

### Enhancements

  * [Parameter] API changes to support new [parameter_ecto](https://github.com/phcurado/parameter_ecto) library
  * [Parameter] Support for `many` flag on  `load/3` and `dump/3` options
  * [Parameter] Errors when parsing list return as map with `%{index => reason}` now instead of `{:#{index}, reason}` to avoid atom creation
  * [Parameter.Field] Support for `load_default` and `dump_default` options
  * [Parameter.Enum] Deprecated `as` in favour of `key`

### Bug fixes

  * [Parameter.Field] Return `default` value when calling `Parameter.dump/3` with empty value.

## v0.5.x (2022-10-26)

### Enhancements

  * [Parameter] Support for `exclude` option for `load/3` and `dump/3`.
  * [Parameter.Types] Support for `any` type
  * [Parameter.Schema] Support for virtual fields