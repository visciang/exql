# Sample app

    docker run -d --rm --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:alpine

    mix deps.get
    mix release
    _build/dev/rel/example/bin/example start

    docker stop postgres
