defmodule Parameter.MixProject do
  use Mix.Project

  @source_url "https://github.com/phcurado/parameter"
  @version "0.8.0"

  def project do
    [
      app: :parameter,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description:
        "Schema creation, validation with serialization and deserialization for input data",
      source_url: @source_url,
      package: package(),
      # Docs
      name: "Parameter",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.0", optional: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package() do
    [
      maintainers: ["Paulo Curado", "Ayrat Badykov"],
      licenses: ["Apache-2.0"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Parameter",
      logo: "logo.png",
      source_ref: "v#{@version}",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      canonical: "https://hexdocs.pm/parameter",
      source_url: @source_url,
      extras: ["CHANGELOG.md"],
      groups_for_modules: [
        Types: [
          Parameter.Enum,
          Parameter.Parametrizable,
          Parameter.Types.Any,
          Parameter.Types.Atom,
          Parameter.Types.Boolean,
          Parameter.Types.Date,
          Parameter.Types.DateTime,
          Parameter.Types.Decimal,
          Parameter.Types.Float,
          Parameter.Types.Integer,
          Parameter.Types.List,
          Parameter.Types.Map,
          Parameter.Types.NaiveDateTime,
          Parameter.Types.String,
          Parameter.Types.Time
        ]
      ]
    ]
  end
end
