defmodule ESME.Mixfile do
  use Mix.Project

  def project do
    [
      app: :esme,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ESME.Application, []}
    ]
  end

  defp deps do
    [
      {:smppex, "~> 3.0"}
    ]
  end
end
