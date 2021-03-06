defmodule Moongate.Macros.Worlds do
  defmacro __using__(_) do
    if Mix.env() == :test do
      world = "test"
    else
      world = Application.get_env(:moongate, :world) || "default"
    end
    camel_world = Mix.Utils.camelize(world)

    quote do
      defp world_module do
        Module.safe_concat(unquote(camel_world), "Game")
      end

      defp world_directory, do: world_directory(nil)
      defp world_directory(key) do
        world = unquote(world)

        case key do
          :http ->
            "worlds/#{world}/http"
          _ ->
            "worlds/#{world}"
        end
      end
    end
  end
end
