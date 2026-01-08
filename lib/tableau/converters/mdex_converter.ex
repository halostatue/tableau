defmodule Tableau.MDExConverter do
  @moduledoc """
  Converter to parse markdown content with `MDEx` with support for MDEx plugins.
  """

  @doc """
  Convert markdown content to HTML using `MDEx.to_html!/2`.

  Will use the globally configured options, but you can also pass it overrides.
  """
  def markdown(content, overrides \\ []) do
    {:ok, config} = Tableau.Config.get()

    {plugins, mdex_config} =
      config.markdown[:mdex]
      |> Keyword.merge(overrides)
      |> Keyword.pop(:plugins, [])

    render!(content, mdex_config, plugins)
  end

  def convert(_filepath, _front_matter, body, %{site: %{config: config}}) do
    {plugins, mdex_config} = Keyword.pop(config.markdown[:mdex], :plugins, [])
    render!(body, mdex_config, plugins)
  end

  defp render!(content, mdex_config, plugins) do
    mdex_config
    |> Keyword.put(:markdown, content)
    |> MDEx.new()
    |> attach_plugins(plugins)
    |> MDEx.to_html!()
  end

  defp attach_plugins(mdex, plugins) do
    Enum.reduce(plugins, mdex, fn mod, mdex ->
      Code.ensure_loaded!(mod)
      mod.attach(mdex)
    end)
  end
end
