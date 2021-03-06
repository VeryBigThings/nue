defmodule Snitch.Data.Model.User do
  @moduledoc """
  User API
  """
  use Snitch.Data.Model
  alias Snitch.Data.Schema.User, as: UserSchema
  import Ecto.Query

  @type update_info_params :: %{
          optional(:first_name) => String.t(),
          optional(:last_name) => String.t()
        }

  @type change_password_params :: %{
          optional(:password) => String.t(),
          optional(:password_confirmation) => String.t()
        }

  @spec create(map) :: {:ok, UserSchema.t()} | {:error, Ecto.Changeset.t()}
  def create(query_fields) do
    QH.create(UserSchema, query_fields, Repo)
  end

  @spec update(map, UserSchema.t()) :: {:ok, UserSchema.t()} | {:error, Ecto.Changeset.t()}
  def update(query_fields, instance) do
    QH.update(UserSchema, query_fields, instance, Repo)
  end

  @spec update_info(UserSchema.t(), update_info_params()) ::
          {:ok, UserSchema.t()} | {:error, Ecto.Changeset.t()}
  def update_info(user, params) do
    user
    |> UserSchema.update_info_changeset(params)
    |> Repo.update()
  end

  @spec change_password(UserSchema.t(), change_password_params()) ::
          {:ok, UserSchema.t()} | {:error, Ecto.Changeset.t()}
  def change_password(user, params) do
    user
    |> UserSchema.change_password_changeset(params)
    |> Repo.update()
  end

  @spec delete(non_neg_integer) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete(id) do
    with {:ok, %UserSchema{} = user} <- get(id),
         changeset <- UserSchema.delete_changeset(user) do
      Repo.update(changeset)
    else
      _ ->
        {:error, "error deleting user"}
    end
  end

  @spec get(map | non_neg_integer) :: {:ok, UserSchema.t()} | {:error, atom}
  def get(query_fields_or_primary_key) do
    QH.get(UserSchema, query_fields_or_primary_key, Repo)
  end

  @spec get_all() :: [UserSchema.t()]
  def get_all, do: from(u in UserSchema, where: is_nil(u.deleted_at)) |> Repo.all()

  @spec get_username(UserSchema.t()) :: String.t()
  def get_username(user) do
    if is_nil(user), do: nil, else: user.first_name <> " " <> user.last_name
  end
end
