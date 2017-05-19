# MiSalud

[![CircleCI](https://circleci.com/gh/instedd/misalud.svg?style=svg)](https://circleci.com/gh/instedd/misalud)

MiSalud pilot project for Doctors of the World NYC.

## Development setup

Instructions for setting up a development environment.

1. Install ruby 2.4.0. If using rbenv, run:
    ```bash
    $ rbenv install 2.4.0
    $ rbenv shell 2.4.0
    $ gem install bundler
    ```

2. Install project dependencies
    ```bash
    $ bundle install --path=.bundle
    ```

3. Create MySQL database
    ```bash
    $ bundle exec rake db:setup
    ```

4. Optionally create fake data
    ```bash
    $ bundle exec rake data:fake
    ```

5. Start the server and open a browser at `localhost:3000`
    ```bash
    $ bundle exec rails server
    ```

### Development (Docker)

The `docker-compose.yml` includes a postgres db and a app container with a rails environment.
The `surveys:worker` / `rspec` can be run manually from it.

```bash
$ docker-compose up
$ docker exec -it misalud_app_1 bash
root@96be4add9815:/# cd /src
root@96be4add9815:/src# rspec
```

## Twilio configuration

Write twilio channel information in `config/settings(.local).yml`.
Use ngrok or similar to get a public address to setup twilio webhook.
Run the following with your public address to setup the webhook.

```
$ bundle exec rails c
irb(main):003:0> SmsChannel.new.config_webhook "https://API_USER:API_PASS@PUBLIC_ADDRESS/twilio/sms"
```

## Verboice configuration

Write verboice project information in `config/settings(.local).yml`.

In verboice project settings set the "Status callback" to `https://API_USER:API_PASS@PUBLIC_ADDRESS/services/status-callback`.

In verboice external services use the manifest at `https://PUBLIC_ADDRESS/verboice.xml`.

## Resourcemap configuration

Write resourcemap collection information in `config/settings(.local).yml`.

## Background jobs

The following will run a worker every 30 seconds for background tasks.

```bash
$ bundle exec rake surveys:worker
```

## Authentication

In `config/settings(.local).yml` there are `basic_auth` and `api_basic_auth` entries. Each of them with `username` and `password` to restric access to the web interface and to secure api endpoints (For verboices and twilio the same `api_basic_auth` is used).

## Deployment

A Docker image at https://hub.docker.com/r/instedd/misalud/ is available. Configurations in `setting.yml` can be overridden using environment variables. Eg: `basic_auth.username` with `SETTINGS__BASIC_AUTH__USERNAME`.

