# Changelog

## v0.6.x (2022-11-02)

### Enhancements

  * [Parameter] API changes to support new [parameter_ecto](https://github.com/phcurado/parameter_ecto) library
  * [Parameter] Support for `many` flag on  `load/3` and `dump/3` options
  * [Parameter] Errors when parsing list return as `{index, reason}` now instead of `{:#{index}, reason}` to avoid atom creation
  * [Parameter.Enum] Deprecated `as` in favour of `key`

## v0.5.x (2022-10-26)

### Enhancements

  * [Parameter] Support for `exclude` option for `load/3` and `dump/3`.
  * [Parameter.Types] Support for `any` type
  * [Parameter.Schema] Support for virtual fields