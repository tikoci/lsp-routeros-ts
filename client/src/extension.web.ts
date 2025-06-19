/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { ExtensionContext, Uri } from 'vscode';
import { LanguageClient } from 'vscode-languageclient/browser';
import { packageJsonInfo, applySemanticColorsFromTheme, getLanguageClientOptions } from './client';

let client: LanguageClient;

console.log("RouterOS LSP extension load starting...");

// this method is called when vs code is activated
export async function activate(context: ExtensionContext) {
	console.log("RouterOS LSP activate() starting");

	const serverMain = Uri.joinPath(context.extensionUri, 'server/dist/server.web.js');
	console.info(`RouterOS LSP using server at ${serverMain.toString(true)}`);
	const worker = new Worker(serverMain.toString(true));
	client = new LanguageClient(
		...packageJsonInfo(context),
		getLanguageClientOptions(),
		worker
	);
	console.log("RouterOS LSP about to start()");

	await client.start();
	context.subscriptions.push(client);
	console.log("RouterOS LSP client.start() called");

	applySemanticColorsFromTheme(context);
	console.log("RouterOS LSP applySemanticColorsFromTheme() called");
}

export function deactivate() {
	console.log("RouterOS LSP extension deactivate() invoked");
}

/*
export async function deactivate(): Promise<void> {
	if (client !== undefined) {
		await client.stop();
	}
}
*/