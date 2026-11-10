# ``SMTP``

Send email to an SMTP server: connect, secure the connection, sign in, and deliver a message to each recipient.

## Overview

SMTP ([RFC 5321](https://www.rfc-editor.org/rfc/rfc5321)) is how a mail app hands outgoing email to a server.
``SMTPClient`` connects to one ``Server`` and sends ``Email`` values, whose bodies are MIME `Body` values from the
`MIME` module. Each recipient gets their own session: the client greets the server, upgrades to TLS with `STARTTLS`
when the server uses it, signs in with `AUTH LOGIN`, and transfers the message.

## Topics

### Sending

- ``SMTPClient``
- ``Email``

### Servers

- ``Server``
- ``ConnectionSecurity``

### Errors

- ``SMTPError``
