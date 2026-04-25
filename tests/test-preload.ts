/**
 * Bun test preload — silences log output during tests.
 * Replaces ConnectionLogger.console with a no-op so test output is clean.
 */
import { ConnectionLogger } from '../server/src/shared'

const noop = () => {}
ConnectionLogger.console = {
	log: noop,
	info: noop,
	warn: noop,
	error: noop,
	debug: noop,
}
