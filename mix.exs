defmodule Parameter.MixProject do
  use Mix.Project

  @source_url "https://github.com/phcurado/parameter"
  @version "0.1.1"

  def project do
    [
      app: :parameter,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Schema creation, validation with serialization for input data",
      source_url: @source_url,
      package: package(),
      # Docs
      name: "Parameter",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Parameter",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/parameter",
      source_url: @source_url
    ]
  end
end
