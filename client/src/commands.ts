import { ConfigurationTarget, commands, type ExtensionContext, Uri, window, workspace } from 'vscode'
import type { BaseLanguageClient } from 'vscode-languageclient'

const ROUTEROS_SHORTID = 'routeroslsp'

interface ApplySemanticTokenOptions {
	skipWhenOverridesDisabled?: boolean
}

interface SemanticTokenColorCustomizations {
	enabled?: boolean
	rules?: Record<string, unknown>
}

export function initializeCommands(context: ExtensionContext, client: BaseLanguageClient) {
	return [
		commands.registerCommand('routeroslsp.cmd.applySemanticTokenColors', async () => {
			const success = await applySemanticTokenColorsFromFile(context, client)
			if (success) {
				const msg = 'Applied RouterOS syntax coloring to settings'
				client.info(`<client.cmd> [routeroslsp.cmd.applySemanticTokenColors] applied successfully`)
				window.showInformationMessage(msg)
			} else {
				const msg = 'Failed to apply semantic colors to settings'
				client.error(`ERROR <client.cmd> [routeroslsp.cmd.applySemanticTokenColors] ${msg}`)
				window.showWarningMessage(msg)
			}
		}),

		commands.registerCommand('routeroslsp.cmd.settings.show', (query = '@ext:TIKOCI.lsp-routeros-ts') => {
			client.info(`<client.cmd> [routeroslsp.cmd.settings.show] invoked ${query}`)
			commands.executeCommand('workbench.action.openSettings', query)
			client.outputChannel.show()
		}),

		commands.registerCommand('routeroslsp.cmd.outputs.show', () => {
			client.info('<client.cmd> [routeroslsp.cmd.outputs.show] invoked')
			client.outputChannel.show()
		}),

		commands.registerCommand('routeroslsp.cmd.newFile', () => {
			client.debug('<client.cmd> [routeroslsp.cmd.newFile] invoked')
			workspace.openTextDocument({ language: 'routeros', content: '\n\n', encoding: 'utf8' }).then(
				(docs) => window.showTextDocument(docs),
				(error) => client.error(`ERROR <client.cmd> [routeroslsp.cmd.newFile] could not create blank text file: ${error}`),
			)
		}),
	]
}

export async function autoApplySemanticTokenColorsOnStartup(context: ExtensionContext, client: BaseLanguageClient) {
	const config = workspace.getConfiguration()
	const autoApply = config.get<boolean>(`${ROUTEROS_SHORTID}.semanticColors.autoApply`, true)
	if (!autoApply) {
		client.debug('<client.cmd> [semanticColors] auto-apply disabled by settings')
		return
	}

	const applied = await applySemanticTokenColorsFromFile(context, client, { skipWhenOverridesDisabled: true })
	if (applied) {
		client.info('<client.cmd> [semanticColors] startup auto-apply complete')
	}
}

export async function applySemanticTokenColorsFromFile(context: ExtensionContext, client: BaseLanguageClient, options: ApplySemanticTokenOptions = {}) {
	try {
		const config = workspace.getConfiguration()
		const enableOverrides = config.get<boolean>(`${ROUTEROS_SHORTID}.semanticColors.enableOverrideRules`, true)
		if (options.skipWhenOverridesDisabled && !enableOverrides) {
			client.debug('<client.cmd> [semanticColors] override rules disabled by settings')
			return true
		}

		// Path to your theme file in extension root
		const themePath = Uri.joinPath(context.extensionUri, './vscode-routeroslsp-theme.json')

		// Read the theme file
		const themeContent = await workspace.fs.readFile(themePath)
		const themeData = JSON.parse(new TextDecoder().decode(themeContent))

		// Extract semantic token colors from theme
		const semanticTokenColors = themeData.semanticTokenColors || {}

		const currentCustomizations = config.get<SemanticTokenColorCustomizations>('editor.semanticTokenColorCustomizations') ?? ({} as SemanticTokenColorCustomizations)
		const currentRules = currentCustomizations.rules ?? {}
		const routerosRuleKeys = new Set(Object.keys(semanticTokenColors))

		// Merge RouterOS semantic colors with existing rules while preserving unrelated entries.
		const filteredRules = Object.fromEntries(Object.entries(currentRules).filter(([k]) => !routerosRuleKeys.has(k)))
		const updatedRules = {
			...filteredRules,
			...semanticTokenColors,
		}

		// Apply the semantic token colors
		await config.update(
			'editor.semanticTokenColorCustomizations',
			{
				...currentCustomizations,
				rules: updatedRules,
			},
			ConfigurationTarget.Global,
		)

		// Enable semantic highlighting if not already enabled
		const semanticEnabled = config.get('editor.semanticHighlighting.enabled')
		if (!semanticEnabled) {
			await config.update('editor.semanticHighlighting.enabled', true, ConfigurationTarget.Global)
		}
		return true
	} catch (error) {
		client.error('Error applying semantic colors from theme:', error, false)
	}
	return false
}
