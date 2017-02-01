# MiSalud

## Twilio configuration

Write twilio channel information in `config/settings(.local).yml`.
Use ngrok or similar to get a public address to setup twilio webhook.
Run the following with your public address to setup the webhook.

```
$ bundle exec rails c
irb(main):003:0> SmsChannel.new.config_webhook "http://99e8e942.ngrok.io/twilio/sms"
```
