locals_without_parens = [
  param: 2,
  param: 3,
  has_one: 2,
  has_one: 3,
  have_many: 2,
  have_many: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
