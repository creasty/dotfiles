local S = require('user.snippets')

return {
  S.snip('api-client-general', 'API Client for general', 'b', [[
export class ${1:Name}API extends BaseClient<I$1ServiceClient> {
	constructor(clientAuth?: ClientAuth, forwardedIps?: string[]) {
		super(generalApiHost, $1ServiceClient, clientAuth, forwardedIps);
	}
}]]),
  S.snip('api-client-receipt', 'API Client for receipt', 'b', [[
export class ${1:Name}API extends BaseClient<I$1ServiceClient> {
	constructor(clientAuth?: ClientAuth, forwardedIps?: string[]) {
		super(receiptApiHost, $1ServiceClient, clientAuth, forwardedIps);
	}
}]]),
}
