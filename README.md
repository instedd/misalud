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

## Twilio configuration

Write twilio channel information in `config/settings(.local).yml`.
Use ngrok or similar to get a public address to setup twilio webhook.
Run the following with your public address to setup the webhook.

```
$ bundle exec rails c
irb(main):003:0> SmsChannel.new.config_webhook "http://PUBLIC_ADDRESS/twilio/sms"
```

## Verboice configuration

Write verboice project information in `config/settings(.local).yml`.

In verboice project settings set the "Status callback" to `http://PUBLIC_ADDRESS/services/status-callback`.

In verboice external services use the manifest at `http://PUBLIC_ADDRESS/verboice.xml`.

## Resourcemap configuration

Write resourcemap collection information in `config/settings(.local).yml`.


