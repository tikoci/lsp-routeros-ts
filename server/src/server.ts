import * as https from 'node:https'
import { createConnection, ProposedFeatures } from 'vscode-languageserver/node'
import { LspController } from './controller'
import { RouterRestClient } from './routeros'

const nodeHttpsAgents = new Map<boolean, https.Agent>([[true, https.globalAgent]])

// Keep certificate handling configurable: secure validation when enabled,
// self-signed RouterOS support when the user explicitly disables checks.
RouterRestClient.nodeHttpsAgentFactory = (checkCertificates) => {
	const rejectUnauthorized = Boolean(checkCertificates)
	let agent = nodeHttpsAgents.get(rejectUnauthorized)
	if (!agent) {
		agent = new https.Agent({ rejectUnauthorized })
		nodeHttpsAgents.set(rejectUnauthorized, agent)
	}
	return agent
}

const connection = createConnection(ProposedFeatures.all)
connection.console.info('RouterOS LSP server connection to client created')

LspController.start(connection)
connection.console.info('RouterOS LSP server startup completed')

connection.listen()
connection.console.info('RouterOS LSP server is listening')
