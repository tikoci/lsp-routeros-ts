// import { isAxiosError, AxiosError } from 'axios'
import { commands, ConfigurationTarget, ExtensionContext, Uri, window, workspace, WorkspaceConfiguration } from 'vscode'
import { type BaseLanguageClient } from 'vscode-languageclient'

export function initializeCommands(context: ExtensionContext, client: BaseLanguageClient) {
  return [

    commands.registerCommand('routeroslsp.cmd.applySemanticTokenColors', async () => {
      const success = await applySemanticTokenColorsFromFile(context, client)
      if (success) {
        const msg = 'Applied RouterOS syntax coloring to settings'
        client.info(`<client.cmd> [routeroslsp.cmd.applySemanticTokenColors] applied successfully`)
        window.showInformationMessage(msg)
      }
      else {
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
        docs => window.showTextDocument(docs),
        error => client.error(`ERROR <client.cmd> [routeroslsp.cmd.newFile] could not create blank text file: ${error}`),
      )
    }),
  ]
}

export async function applySemanticTokenColorsFromFile(context: ExtensionContext, client: BaseLanguageClient) {
  try {
    // Path to your theme file in extension root
    const themePath = Uri.joinPath(context.extensionUri, './vscode-routeroslsp-theme.json')

    // Read the theme file
    const themeContent = await workspace.fs.readFile(themePath)
    const themeData = JSON.parse(new TextDecoder().decode(themeContent))

    // Extract semantic token colors from theme
    const semanticTokenColors = themeData.semanticTokenColors || {}

    // Get current VS Code configuration
    const config = workspace.getConfiguration()
    const currentCustomizations: WorkspaceConfiguration = config.get(
      'editor.semanticTokenColorCustomizations',
    )
    const currentRules = currentCustomizations.rules || {}

    // Merge theme semantic colors with existing rules
    const updatedRules = {
      ...currentRules,
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
      await config.update(
        'editor.semanticHighlighting.enabled',
        true,
        ConfigurationTarget.Global,
      )
    }
    return true
  }
  catch (error) {
    client.error('Error applying semantic colors from theme:', error, false)
  }
  return false
}
