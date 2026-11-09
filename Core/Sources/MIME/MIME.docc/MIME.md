# ``MIME``

Read and write MIME messages: headers, parts, bodies, and the content metadata that describes them.

## Overview

MIME ([RFC 2045](https://www.rfc-editor.org/rfc/rfc2045)) is the format email messages use to carry text, HTML, and
attachments. This module parses a message into a tree of ``Part`` values and writes it back out.

## Topics

### Messages

- ``Part``
- ``Body``
- ``Header``

### Content metadata

- ``ContentType``
- ``ContentDisposition``
- ``ContentTransferEncoding``
- ``CharacterSet``

### Identifiers

- ``Boundary``
- ``ContentID``

### Dates

- ``RFC822DateFormatter``

### Errors

- ``MIMEError``
