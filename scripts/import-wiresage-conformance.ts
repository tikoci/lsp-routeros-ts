/** Network entry point; shared import/index helpers stay offline. */
import { resolve } from 'node:path'
import { conformanceFiles, writeConformanceCollection, WIRESAGE_COLLECTION, WIRESAGE_RAW_BASE, WIRESAGE_REVISION } from './wiresage-conformance'

async function download(path: string): Promise<Uint8Array> {
	const response = await fetch(`${WIRESAGE_RAW_BASE}/${path}`, { signal: AbortSignal.timeout(30_000) })
	if (!response.ok) throw new Error(`Upstream HTTP ${response.status}: ${path}`)
	return new Uint8Array(await response.arrayBuffer())
}

const [cases, license] = await Promise.all([download('tests/conformance/cases.json'), download('LICENSE')])
const files = conformanceFiles(cases, license)
writeConformanceCollection(resolve(import.meta.dir, '../test-data', WIRESAGE_COLLECTION), files)
console.log(`Imported ${files.size - 3} byte-exact cases from ${WIRESAGE_REVISION}`)
