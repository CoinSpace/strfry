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
    [rateLimitPolicy, { whitelist: ['127.0.0.1', '192.168.1.136', '192.168.1.1',
       'servicediscovery-fcvgj8f4sc54.us-east-2-purplerelay.internal', 'servicediscovery-jcxbzsyteqcw.ap-northeast-1-purplerelay.internal', 
       'servicediscovery-eyt5cvcn0kne.eu-central-1-purplerelay.internal', 'servicediscovery-y6tvlqmfuez7.af-south-1-purplerelay.internal', 
       'servicediscovery-5u8kfcwtbmvm.sa-east-1-purplerelay.internal', 'servicediscovery-7fzr2wjxa4jr.us-east-1-purplerelay.internal'] }],
  ]);

  writeStdout(result);
}