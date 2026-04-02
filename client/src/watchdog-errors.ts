/**
 * Pure error-mapping functions extracted from watchdog.ts for testability.
 * No VSCode dependencies — safe to import from tests.
 */

export interface ErrorInfo {
	code?: string
	message?: string
	name?: string
	status?: number
}

/**
 * Safely extract error-like fields from whatever the server returned.
 * The server should return a RouterOSClientError {code, message, status?},
 * but could return undefined/null if getIdentity resolved with no data,
 * or an unknown shape if JSON-RPC deserialization produced something unexpected.
 */
export function toErrorInfo(value: unknown): ErrorInfo {
	if (value == null) {
		return { code: 'UNKNOWN', message: 'No response from RouterOS (identity was empty)' }
	}
	if (typeof value === 'object') {
		const obj = value as Record<string, unknown>
		return {
			code: typeof obj.code === 'string' ? obj.code : typeof obj.code === 'number' ? String(obj.code) : undefined,
			message: typeof obj.message === 'string' ? obj.message : undefined,
			name: typeof obj.name === 'string' ? obj.name : undefined,
			status: typeof obj.status === 'number' ? obj.status : undefined,
		}
	}
	return { message: String(value) }
}

/**
 * Map a RouterOS error into a user-facing message string.
 * This is the same logic as LspClientWatchdog.getTextFromError but extracted
 * as a pure function for testing.
 */
export function getTextFromError(error: ErrorInfo, displayConnectionUrl: string | null, isUsingClientCredentials: boolean): string {
	let errText = 'Router LSP not working: '
	if (isUsingClientCredentials) {
		errText = 'RouterOS LSP not working using TikBook credentials: '
	}
	if (error.code && error.message) {
		switch (error.code) {
			case 'ECONNABORTED': {
				errText += `No response, check Base Url '${displayConnectionUrl}' (${error.code} ${error.message})`
				break
			}
			case 'HOSTDOWN': {
				errText += `${error.code}, check Base Url '${displayConnectionUrl}' (${error.message})`
				break
			}
			case 'ECONNREFUSED': {
				errText += `Perhaps wrong port number or firewall blocking, check Base Url '${displayConnectionUrl}' (${error.message})`
				break
			}
			case 'ERR_TLS_CERT_ALTNAME_INVALID': {
				errText += `Perhaps disable 'Check Certificates' in Settings. (${error.message})`
				break
			}
			case 'ERR_BAD_REQUEST': {
				if (error.status) {
					switch (error.status) {
						case 401: {
							errText += `Username or password are wrong using ${displayConnectionUrl} (HTTP status ${error.status})`
							break
						}
						case 404: {
							errText += `Either hostname is wrong or an additional path is bad. ${displayConnectionUrl} (HTTP status ${error.status})`
							break
						}
						default:
							errText += `${error.message} ${displayConnectionUrl} (HTTP status ${error.status})`
							break
					}
				} else {
					errText += `${error.message} (${error.code})`
				}
				break
			}
			default:
				errText += `${error.message} (${error.code})`
		}
	} else if (error.message) {
		errText += `${error.message} ${error.name ? `(${error.name})` : ''}`
	} else {
		errText += error.toString()
	}
	return errText
}
