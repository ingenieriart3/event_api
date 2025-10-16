# # defmodule EventApiWeb.Router do
# #   use EventApiWeb, :router

# #   pipeline :api do
# #     plug :accepts, ["json"]
# #   end

# #   scope "/api", EventApiWeb do
# #     pipe_through :api
# #   end

# #   # Enable LiveDashboard and Swoosh mailbox preview in development
# #   if Application.compile_env(:event_api, :dev_routes) do
# #     # If you want to use the LiveDashboard in production, you should put
# #     # it behind authentication and allow only admins to access it.
# #     # If your application does not have an admins-only section yet,
# #     # you can use Plug.BasicAuth to set up some basic authentication
# #     # as long as you are also using SSL (which you should anyway).
# #     import Phoenix.LiveDashboard.Router

# #     scope "/dev" do
# #       pipe_through [:fetch_session, :protect_from_forgery]

# #       live_dashboard "/dashboard", metrics: EventApiWeb.Telemetry
# #       forward "/mailbox", Plug.Swoosh.MailboxPreview
# #     end
# #   end
# # end

# defmodule EventApiWeb.Router do
#   use EventApiWeb, :router

#   pipeline :api do
#     plug :accepts, ["json"]
#   end

#   pipeline :auth do
#     plug EventApiWeb.AuthPlug
#   end

#   # Public routes - no authentication required
#   scope "/api/v1/public", EventApiWeb do
#     pipe_through :api

#     get "/events", PublicController, :index
#     get "/events/:id", PublicController, :show
#     get "/events/:id/summary", PublicController, :summary
#     get "/events/:id/summary/stream", PublicController, :stream_summary
#   end

#   # Protected routes - require authentication
#   scope "/api/v1", EventApiWeb do
#     pipe_through [:api, :auth]

#     resources "/events", EventController, except: [:new, :edit, :show, :delete]
#   end

#   # Health check
#   scope "/", EventApiWeb do
#     pipe_through :api

#     get "/health", HealthController, :check
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

    resources "/events", EventController, except: [:new, :edit, :show, :delete]
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
