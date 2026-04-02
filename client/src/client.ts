import type { ExtensionContext } from 'vscode'
import type { LanguageClientOptions } from 'vscode-languageclient'

const languageClientOptions = {
	documentSelector: [
		{ language: 'routeros' },
		{ language: 'rsc' },
		{ scheme: 'vscode-notebook-cell', language: 'routeros' },
		{ scheme: 'file', pattern: '**/*.rsc' },
		{ scheme: 'file', pattern: '**/*.tikbook' },
		{ scheme: 'file', pattern: '**/*.md.rsc' },
		{ scheme: 'rscena', pattern: '**/*.rsc' },
		{ scheme: 'rscena', pattern: '**/*.md.rsc' },
		{ scheme: 'rscena', pattern: '**/*.tikbook' },
		{ language: 'routeroslsp' },
		{ scheme: 'vscode', language: 'routeros' },
	],
	synchronize: {
		// configurationSection: 'routeroslsp',
		// fileEvents: workspace.createFileSystemWatcher("**/.rsc")
	},
	progressOnInitialization: true,
	initializationOptions: {},
}

export function getLanguageClientOptions(): LanguageClientOptions {
	return languageClientOptions
}

export function getPackageInfo(context: ExtensionContext): [string, string] {
	return [context.extension.packageJSON.config.shortid, context.extension.packageJSON.displayName]
}
