//import * as path from "path";
//import * as fs from "fs";
import {
  workspace,
  ExtensionContext,
  ConfigurationTarget,
  window,
  env,
  UIKind,
  WorkspaceConfiguration,
  Uri
} from "vscode";
import { LanguageClientOptions } from 'vscode-languageclient';

export const packageJsonInfo = (context: ExtensionContext): [string, string] => [context.extension.packageJSON.config.shortid, context.extension.packageJSON.displayName];

export function getVSCodeType() {
  if (env.uiKind === UIKind.Web) {
    // Running in VSCode for Web (e.g., vscode.dev or github.dev)
    console.log("Running in VSCode Web");
  } else {
    // Running in VSCode Desktop
    console.log("Running in VSCode Desktop");
  }

}

export function getLanguageClientOptions(): LanguageClientOptions {
  return {
    documentSelector: [
      { scheme: "vscode-notebook-cell", language: "routeros" },
      { language: "routeros" },
      { language: "rsc" },
      { scheme: "file", pattern: "**∕*.rsc" },
      { language: "routeroslsp" },
    ],
    synchronize: {
      // fileEvents: workspace.createFileSystemWatcher("**/.rsc")
    },
    progressOnInitialization: true,
    initializationOptions: {}
  };
}

export async function applySemanticColorsFromTheme(context: ExtensionContext) {
  try {
    // Path to your theme file in extension root
    const themePath = Uri.joinPath(context.extensionUri, './vscode-routeroslsp-theme.json');

    // Read the theme file
    const themeContent = await workspace.fs.readFile(themePath);
    const themeData = JSON.parse(new TextDecoder().decode(themeContent));

    // Extract semantic token colors from theme
    const semanticTokenColors = themeData.semanticTokenColors || {};

    // Get current VS Code configuration
    const config = workspace.getConfiguration();
    const currentCustomizations: WorkspaceConfiguration = config.get(
      "editor.semanticTokenColorCustomizations"
    );
    const currentRules = currentCustomizations.rules || {};

    // Merge theme semantic colors with existing rules
    const updatedRules = {
      ...currentRules,
      ...semanticTokenColors,
    };

    // Apply the semantic token colors
    await config.update(
      "editor.semanticTokenColorCustomizations",
      {
        ...currentCustomizations,
        rules: updatedRules,
      },
      ConfigurationTarget.Global
    );

    // Enable semantic highlighting if not already enabled
    const semanticEnabled = config.get("editor.semanticHighlighting.enabled");
    if (!semanticEnabled) {
      await config.update(
        "editor.semanticHighlighting.enabled",
        true,
        ConfigurationTarget.Global
      );
    }

    // window.showInformationMessage("Semantic colors applied from theme!");
  } catch (error) {
    console.warn("Error applying semantic colors from theme:", error);
    window.showWarningMessage("Failed to apply semantic colors from theme");
  }
}
