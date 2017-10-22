defmodule NNex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nnex,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NNex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :uuid, "~> 1.1" },
      # {:amnesia, github: "meh/amnesia", tag: :master}
    ]
  end
end
