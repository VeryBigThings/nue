defmodule SnitchApiWeb.UserController do
  use SnitchApiWeb, :controller

  alias Snitch.Data.Schema.User
  alias SnitchApi.Accounts
  alias SnitchApi.Guardian
  alias Snitch.Data.Model.User, as: UserModel

  plug(SnitchApiWeb.Plug.DataToAttributes)
  plug(SnitchApiWeb.Plug.LoadUser)

  action_fallback(SnitchApiWeb.FallbackController)

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json-api", users: users)
  end

  def create(conn, params) do
    with {:ok, %User{} = user} <- Accounts.create_user(params) do
      conn
      |> put_status(200)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("show.json-api", data: user)
    end
  end

  def update(conn, %{"id" => id} = params) do
    user = Guardian.Plug.current_resource(conn)

    with :ok <- user_authorized?(user, id),
         {:ok, user} <- Accounts.update_info(user, params) do
      render(conn, "show.json-api", data: user)
    end
  end

  def change_password(conn, %{"id" => id} = params) do
    user = Guardian.Plug.current_resource(conn)

    with :ok <- user_authorized?(user, id),
         {:ok, user} <- Accounts.change_password(user, params) do
      render(conn, "show.json-api", data: user)
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.token_sign_in(email, password) do
      {:ok, token, _claims} ->
        {:ok, user} = UserModel.get(%{email: email})
        render(conn, "token.json-api", data: token, user: user)

      _ ->
        {:error, :unauthorized}
    end
  end

  def login(_conn, _params), do: {:error, :no_credentials}

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json-api", data: user)
  end

  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_status(204)
    |> render("logout.json-api", data: "logged out")
  end

  def current_user(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "current_user.json-api", data: user)
  end

  def authenticated(conn, _params) do
    user = conn.assigns[:current_user]
    render(conn, "show.json-api", data: user)
  end

  defp user_authorized?(user, id), do: VBT.validate(id == "#{user.id}", :unauthorized)
end
