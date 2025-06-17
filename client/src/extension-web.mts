import * as path from "path";
import * as fs from "fs";
import {
  workspace,
  ExtensionContext,
  ConfigurationTarget,
  window,
  UIKind,
  env,
} from "vscode";

import {
  LanguageClient,
  LanguageClientOptions
} from "vscode-languageclient/browser";

//let client: LanguageClient;

console.log("RouterOS LSP loaded")

export function activate(context: ExtensionContext) {
  console.log("RouterOS LSP activate() start")
  
  const serverWorker = new Worker(
    new URL("../../server/out/server-web.js", import.meta.url),
    { type: "module" }
  );
  
  // Options to control the language client
  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      { scheme: "vscode-notebook-cell", language: "routeros" },
      { language: "routeros" },
      { language: "rsc" },
      { scheme: "file", pattern: "**∕*.rsc" },
      { language: "routeroslsp" },
    ],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher("**/.rsc"),
    },
    progressOnInitialization: true
  };
  
  // Create the language client and start the client.
  let client = new LanguageClient(
    "routeroslsp",
    "RouterOS LSP",
    clientOptions,
    serverWorker
  );
  
  console.log("Starting LSP Server...");
  client.start()
  context.subscriptions.push(client);

  applySemanticColorsFromTheme(context)
}

export function deactivate() {
  console.log("RouterOS LSP extension deactivated")
}


async function applySemanticColorsFromTheme(context: ExtensionContext) {
  try {
    // Path to your theme file in extension root
    const themePath = path.join(
      context.extensionPath,
      "vscode-routeroslsp-theme.json"
    );

    // Read the theme file
    const themeContent = fs.readFileSync(themePath, "utf-8");
    const themeData = JSON.parse(themeContent);

    // Extract semantic token colors from theme
    const semanticTokenColors = themeData.semanticTokenColors || {};

    // Get current VS Code configuration
    const config = workspace.getConfiguration();
    const currentCustomizations: any = config.get(
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
    console.error("Error applying semantic colors from theme:", error);
    window.showErrorMessage("Failed to apply semantic colors from theme");
  }
}
