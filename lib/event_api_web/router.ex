# # defmodule EventApiWeb.Router do
# #   use EventApiWeb, :router

# #   pipeline :api do
# #     plug :accepts, ["json"]
# #     plug :put_secure_browser_headers
# #   end

# #   # Public routes - no authentication required
# #   scope "/api/v1/public", EventApiWeb do
# #     pipe_through :api

# #     get "/events", PublicController, :index
# #     get "/events/:id/summary", PublicController, :summary
# #     get "/events/:id/summary/stream", PublicController, :stream_summary
# #   end

# #   # Protected routes - require authentication
# #   scope "/api/v1", EventApiWeb do
# #     pipe_through :api

# #     resources "/events", EventController, except: [:new, :edit, :show, :delete, :update]
# #   end

# #   # Health check
# #   scope "/", EventApiWeb do
# #     pipe_through :api

# #     get "/health", HealthController, :check
# #   end

# #   # Enable LiveDashboard in development
# #   if Application.compile_env(:event_api, :dev_routes) do
# #     import Phoenix.LiveDashboard.Router

# #     scope "/dev" do
# #       pipe_through [:fetch_session, :protect_from_forgery]

# #       live_dashboard "/dashboard", metrics: EventApiWeb.Telemetry
# #     end
# #   end
# # end

# defmodule EventApiWeb.Router do
#   use EventApiWeb, :router

#   pipeline :api do
#     plug :accepts, ["json"]
#     plug :put_secure_browser_headers
#   end

#   # Public routes - no authentication required
#   scope "/api/v1/public", EventApiWeb do
#     pipe_through :api

#     get "/events", PublicController, :index
#     get "/events/:id/summary", PublicController, :summary
#     get "/events/:id/summary/stream", PublicController, :stream_summary
#   end

#   # Protected routes - require authentication
#   scope "/api/v1", EventApiWeb do
#     pipe_through :api

#     # resources genera PUT para update, pero queremos PATCH también
#     resources "/events", EventController, except: [:new, :edit, :show, :delete]

#     # Ruta PATCH explícita para update
#     patch "/events/:id", EventController, :update
#   end

#   # Health check
#   scope "/", EventApiWeb do
#     pipe_through :api

#     get "/health", HealthController, :check
#   end

#   # Enable LiveDashboard in development
#   if Application.compile_env(:event_api, :dev_routes) do
#     import Phoenix.LiveDashboard.Router

#     scope "/dev" do
#       pipe_through [:fetch_session, :protect_from_forgery]

#       live_dashboard "/dashboard", metrics: EventApiWeb.Telemetry
#     end
#   end
# end

defmodule EventApiWeb.Router do
  use EventApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers
  end

  # Public routes - no authentication required
  scope "/api/v1/public", EventApiWeb do
    pipe_through :api

    get "/events", PublicController, :index
    get "/events/:id/summary", PublicController, :summary
    get "/events/:id/summary/stream", PublicController, :stream_summary
  end

  # Protected routes - require authentication
  scope "/api/v1", EventApiWeb do
    pipe_through :api

    # Rutas manuales para mayor control
    get "/events", EventController, :index
    post "/events", EventController, :create
    patch "/events/:id", EventController, :update
    put "/events/:id", EventController, :update  # Opcional: soportar ambos
  end

  # Health check
  scope "/", EventApiWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:event_api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: EventApiWeb.Telemetry
    end
  end
end
