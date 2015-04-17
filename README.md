# OpenAperture RouterManager

The OpenAperture Router Manager is the service used to add/update/remove the host and route entries that the OpenAperture Router uses. To start the server, perform the normal elixir project setup steps:

    mix do deps.get, deps.compile

You'll need to make sure a postgresql server is accessible, and create a database for the application to use. See config/config.exs and config/dev.exs for details on default configuration or environmental variables used for customization. Once the database server is in place, run

    mix ecto.create
    mix ecto.migrate

To create the database and set up the necessary tables. Now you can start the OpenAperture Router Manager with

    mix phoenix.server

Which will run the manager on http://localhost:4000.

Navigate to http://localhost:4000/hosts to begin adding host and route records.