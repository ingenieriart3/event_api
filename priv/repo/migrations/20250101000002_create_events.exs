defmodule EventApi.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false, size: 200
      add :start_at, :utc_datetime, null: false
      add :end_at, :utc_datetime, null: false
      add :location, :string, null: false
      add :status, :string, null: false, default: "DRAFT"
      add :internal_notes, :text
      add :created_by, :string
      # add :updated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:status])
    create index(:events, [:start_at])
    create index(:events, [:location])
    create index(:events, [:start_at, :end_at])
  end
end
