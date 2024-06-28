#!/bin/sh
//bin/true; exec deno run -A "$0" "$@"
import {
  antiDuplicationPolicy,
  hellthreadPolicy,
  rateLimitPolicy,
  pipeline,
  readStdin,
  writeStdout,
} from 'https://gitlab.com/soapbox-pub/strfry-policies/-/raw/develop/mod.ts';

for await (const msg of readStdin()) {
  const result = await pipeline(msg, [
    [hellthreadPolicy, { limit: 100 }],
    [antiDuplicationPolicy, { ttl: 60000, minLength: 50 }],
    [rateLimitPolicy, { whitelist: ['127.0.0.1', '192.168.1.136', '192.168.1.1', '10.0.0.0','10.10.40.16', '10.115.40.33', '10.45.30.94', '10.80.30.35', '10.50.40.81', '10.20.30.22'] }],
  ]);

  writeStdout(result);
}