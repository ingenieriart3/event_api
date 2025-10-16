# defmodule EventApiWeb.HealthController do
#   use EventApiWeb, :controller

#   def check(conn, _params) do
#     json(conn, %{
#       status: "healthy",
#       timestamp: DateTime.utc_now(),
#       version: "1.0.0"
#     })
#   end
# end

defmodule EventApiWeb.HealthController do
  use EventApiWeb, :controller

  def check(conn, _params) do
    json(conn, %{
      status: "healthy",
      timestamp: DateTime.utc_now(),
      version: "1.0.0"
    })
  end
end
