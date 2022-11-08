# Changelog

## v0.7.x (2022-11-07)

### Enhancements

* [Parameter] New `validate/3` function
* [Parameter.Schema] Supports for `fields_required` module attribute on schema

### Bug fixes

* [Parameter] `dump/3` function to load the value to be dumped

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