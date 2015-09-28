defmodule Default.Stage.LoginScreen do
  import Moongate.Stage

  meta %{}
  pools []
  takes :proceed, :check_authenticated

  def joined(_) do
  end

  defp check_authenticated(event, {}) do
    auth = is_authenticated?(event)

    if auth do
      depart event
      join event, :test_level
    end
  end
end
