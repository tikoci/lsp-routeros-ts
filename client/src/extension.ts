import * as path from "path";
import {
  workspace,
  ExtensionContext,
  ConfigurationTarget,
  window,
  UIKind,
  env,
} from "vscode";
import fs = require("fs");

import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  applySemanticColorsFromTheme(context);

  let serverJSFile = "server.js" 
  if (env.uiKind === UIKind.Web) {
    // Running in VSCode for Web (e.g., vscode.dev or github.dev)
    console.log("Running in VSCode Web");
    serverJSFile = "server-web.js"
  } else {
    // Running in VSCode Desktop
    console.log("Running in VSCode Desktop");
  }
  
  const serverModule = context.asAbsolutePath(
    path.join("server", "out", serverJSFile)
  );

  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
    },
  };

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
    progressOnInitialization: true,
  };

  // Create the language client and start the client.
  client = new LanguageClient(
    "routeroslsp",
    "RouterOS LSP",
    serverOptions,
    clientOptions
  );

  // Start the client. This will also launch the server
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
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
