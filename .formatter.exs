locals_without_parens = [
  param: 1,
  param: 2,
  field: 2,
  field: 3,
  has_one: 2,
  has_one: 3,
  has_many: 2,
  has_many: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
