defmodule J1605.Mixfile do
  use Mix.Project

  def project do
    [
      app: :j1605,
      version: "0.2.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      description: description(),
      package: package(),
      deps: deps(),
      name: "J1605",
      source_url: "https://github.com/siegfried/j1605"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [], mod: {J1605, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "This mix is to be used to control J1605 switch hub, which contains 16 switches."
  end

  defp package() do
    [
      name: "j1605",
      files: ~w(lib mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/siegfried/j1605"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
