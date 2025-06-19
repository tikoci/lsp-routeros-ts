//import * as path from "path";
//import * as fs from "fs";
import {
  ExtensionContext,
} from "vscode";

import {
  LanguageClient,
  TransportKind,
} from "vscode-languageclient/node";
import { packageJsonInfo, applySemanticColorsFromTheme, getLanguageClientOptions } from './client';

let client: LanguageClient;

console.info("RouterOS LSP extension load starting");

export function activate(context: ExtensionContext) {
  console.log("RouterOS LSP activate() starting");

  const serverModule = context.asAbsolutePath('./server/dist/server.js');

  client = new LanguageClient(
    ...packageJsonInfo(context),
    {
      run: { module: serverModule, transport: TransportKind.ipc },
      debug: {
        module: serverModule,
        transport: TransportKind.ipc,
      },
    },
    getLanguageClientOptions()
  );

  // Start the client. This will also launch the server
  client.start();
  context.subscriptions.push(client);
  console.log("RouterOS LSP client.start() called");

  applySemanticColorsFromTheme(context);
}

export function deactivate() {
  console.log("RouterOS LSP extension deactivate() invoked");
}
