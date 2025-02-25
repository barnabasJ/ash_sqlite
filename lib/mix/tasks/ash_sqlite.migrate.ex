defmodule Mix.Tasks.AshSqlite.Migrate do
  use Mix.Task

  import AshSqlite.MixHelpers,
    only: [migrations_path: 2]

  @shortdoc "Runs the repository migrations for all repositories in the provided (or congigured) apis"

  @aliases [
    n: :step
  ]

  @switches [
    all: :boolean,
    step: :integer,
    to: :integer,
    quiet: :boolean,
    pool_size: :integer,
    log_sql: :boolean,
    strict_version_order: :boolean,
    apis: :string,
    no_compile: :boolean,
    no_deps_check: :boolean,
    migrations_path: :keep
  ]

  @moduledoc """
  Runs the pending migrations for the given repository.

  Migrations are expected at "priv/YOUR_REPO/migrations" directory
  of the current application, where "YOUR_REPO" is the last segment
  in your repository name. For example, the repository `MyApp.Repo`
  will use "priv/repo/migrations". The repository `Whatever.MyRepo`
  will use "priv/my_repo/migrations".

  This task runs all pending migrations by default. To migrate up to a
  specific version number, supply `--to version_number`. To migrate a
  specific number of times, use `--step n`.

  This is only really useful if your api or apis only use a single repo.
  If you have multiple repos and you want to run a single migration and/or
  migrate/roll them back to different points, you will need to use the
  ecto specific task, `mix ecto.migrate` and provide your repo name.

  If a repository has not yet been started, one will be started outside
  your application supervision tree and shutdown afterwards.

  ## Examples

      mix ash_sqlite.migrate
      mix ash_sqlite.migrate --apis MyApp.Api1,MyApp.Api2

      mix ash_sqlite.migrate -n 3
      mix ash_sqlite.migrate --step 3

      mix ash_sqlite.migrate --to 20080906120000

  ## Command line options

    * `--apis` - the apis who's repos should be migrated

    * `--all` - run all pending migrations

    * `--step`, `-n` - run n number of pending migrations

    * `--to` - run all migrations up to and including version

    * `--quiet` - do not log migration commands

    * `--pool-size` - the pool size if the repository is started only for the task (defaults to 2)

    * `--log-sql` - log the raw sql migrations are running

    * `--strict-version-order` - abort when applying a migration with old timestamp

    * `--no-compile` - does not compile applications before migrating

    * `--no-deps-check` - does not check depedendencies before migrating

    * `--migrations-path` - the path to load the migrations from, defaults to
      `"priv/repo/migrations"`. This option may be given multiple times in which case the migrations
      are loaded from all the given directories and sorted as if they were in the same one.

      Note, if you have migrations paths e.g. `a/` and `b/`, and run
      `mix ecto.migrate --migrations-path a/`, the latest migrations from `a/` will be run (even
      if `b/` contains the overall latest migrations.)
  """

  @impl true
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    repos = AshSqlite.MixHelpers.repos!(opts, args)

    repo_args =
      Enum.flat_map(repos, fn repo ->
        ["-r", to_string(repo)]
      end)

    rest_opts =
      args
      |> AshSqlite.MixHelpers.delete_arg("--apis")
      |> AshSqlite.MixHelpers.delete_arg("--migrations-path")

    for repo <- repos do
      Mix.Task.run(
        "ecto.migrate",
        repo_args ++ rest_opts ++ ["--migrations-path", migrations_path(opts, repo)]
      )

      Mix.Task.reenable("ecto.migrate")
    end
  end
end
