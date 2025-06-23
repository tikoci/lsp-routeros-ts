import {
	CompletionItem,
	CompletionItemKind,
	CompletionParams,
	Connection,
	Diagnostic,
	DiagnosticSeverity,
	DocumentDiagnosticParams,
	DocumentDiagnosticReportKind,
	DocumentSymbol,
	DocumentSymbolParams,
	Hover,
	InitializeParams,
	InitializeResult,
	InsertTextFormat,
	PublishDiagnosticsParams,
	SemanticTokens, SemanticTokensBuilder,
	SemanticTokensParams,
	ServerCapabilities,
	SymbolInformation,
	SymbolKind,
	TextDocumentPositionParams,
	TextDocuments,
	TextDocumentSyncKind,
	type DocumentDiagnosticReport
} from 'vscode-languageserver';
import { DocumentUri, Position, Range, TextDocument } from 'vscode-languageserver-textdocument';
import { RouterOSDevice } from './routeros';
import { type CompletionInspectResponseItem } from './types';

export let connection: Connection;

// MARK: settings

interface LspSettings {
	maxNumberOfProblems: number;
	baseUrl: string; // Base URL for the RouterOS API
	username: string;
	password: string;
	hotlock: boolean;
}

// MARK: highlight provider

type HighlightToken = string;
type HighlightTokenRange = HighlightTokenRangeItem[];
interface HighlightTokenRangeItem { token: HighlightToken, range: Range }
class HighlightTokens {
	#tokens: HighlightToken[];
	#document: TextDocument;
	#tokenRanges: HighlightTokenRange;
	#startOffset = 0;
	get document() { return this.#document; }
	get tokens() { return this.#tokens; }
	get tokenRanges() { return this.#tokenRanges; }

	constructor(tokens: HighlightToken[], document: TextDocument, range?: Range) {
		this.#tokens = tokens;
		this.#document = document;
		this.#tokenRanges = this.#getHighlightTokenRange();
		if (range) { this.#startOffset = document.offsetAt(range?.start); }
	}

	atPosition(position: Position): HighlightTokenRangeItem | undefined {
		//this.tokenRange(this.atPosition(position));
		if (this.#document.offsetAt(position) >= this.#tokens.length) {
			return undefined;
		}
		let foundRange: HighlightTokenRangeItem | undefined = undefined;
		this.tokenRanges.forEach(tokenRange => {
			if (LspDocument.positionInRange(position, tokenRange.range)) {
				foundRange = tokenRange;
				return;
			}
		});
		if (foundRange === undefined) {
			console.log(position);
			console.log(this.tokenRanges);
			throw new Error("HighlightTokens:rangePosition - provided position found no tokens");
		}
		return foundRange;
	}

	#getHighlightTokenRange(): HighlightTokenRange {
		const result: HighlightTokenRange = [];
		let i = 0; // + this.#startOffset;
		while (i < this.#tokens.length) {
			let end = i;
			while (end + 1 < this.#tokens.length && this.#tokens[end + 1] === this.#tokens[i]) {
				end++;
			}
			const item = {
				token: this.#tokens[i],
				range: { start: this.#document.positionAt(i + this.#startOffset), end: this.#document.positionAt(end + this.#startOffset) }
			};
			i = end + 1; // Move to the next distinct value
			result.push(item);
		}
		return result;
	}

	// MARK: define token types
	static ErrorTokenTypes = [
		"variable-undefined",
		"error",
		"obj-inactive",
		"syntax-obsolete",
		"syntax-old",
		"ambiguous",
	];

	static TokenTypes = [
		"none",
		"dir",
		"cmd",
		"arg",
		"varname-local",
		"variable-parameter",
		"variable-local",
		"syntax-val",
		"varname",
		"syntax-meta",
		"escaped",
		"variable-global",
		"comment",
		"obj-inactive",
		"syntax-obsolete",
		"variable-undefined",
		"ambiguous",
		"syntax-old",
		"error",
		"varname-global",
		"syntax-noterm",
	];
}


// MARK: LspDocument

class LspDocument {
	#document: TextDocument;
	#settings: LspSettings;
	#higlightTokens: Promise<HighlightTokens>;
	#router: RouterOSDevice;
	get uri() { return this.#document.uri; }
	get settings() { return this.#settings; }
	get higlightTokens() { return this.#higlightTokens; }
	get document() { return this.#document; }

	offsetAt(position: Position) { return this.#document.offsetAt(position); }
	positionAt(offset: number) { return this.#document.positionAt(offset); }

	constructor(document: TextDocument, settings: LspSettings) {
		this.#document = document;
		this.#settings = settings;
		this.#router = new RouterOSDevice(settings);
		this.#higlightTokens = this.#fetchHighlightTokens();
	}

	static async create(document: TextDocument, controller: LspController) {
		const settings = await controller.connection.workspace.getConfiguration({ section: controller.shortid, scopeUri: document.uri });
		const cachedDoc = await controller.documents.get(document.uri);
		if (cachedDoc) { return new LspDocument(cachedDoc, settings); }
		else { throw new Error("no cache doc"); }
	}

	async completion(position: Position) {
		return this.#router.inspectCompletion(
			this.#document.getText().substring(0, this.#document.offsetAt(position))
		);

		/*await this.#axios.post<CompletionInspectResponseItem[]>(
			'/console/inspect', {
			request: 'completion',
			input: )
		}).then(resp => resp.data);*/
	}

	// MARK: diagnostics provider

	// TODO: should take diagnostic "type", refactor HighlightTokens = mess
	async diagnostics(): Promise<Diagnostic[]> {
		const tokens = await this.higlightTokens;
		const tokenRanges = tokens.tokenRanges;
		const errors = tokenRanges
			.filter(tokenRange => HighlightTokens.ErrorTokenTypes.includes(tokenRange.token))
			.map(tokenRange => {
				return {
					severity: DiagnosticSeverity.Error,
					range: tokenRange.range,
					message: `Script error from highlight '${tokenRange.token}'`,
					code: `token:${tokenRange.token}`,
					source: "routeroslsp",
				};
			});
		if (errors.length > 0) {
			const lastError = errors[errors.length - 1];
			const nextPosition = this.positionAt(this.offsetAt(lastError.range.end) + 2);
			const endPostition = this.positionAt(tokens.tokens.length);
			if (nextPosition.line >= endPostition.line) { return errors; }
			return [...errors, {
				severity: DiagnosticSeverity.Warning,
				range: { start: nextPosition, end: endPostition },
				message: `Potential issues due to prior highlight error`,
				code: `token:unchecked}`,
				source: "routeroslsp",
			}];
		}

		return [];
	}

	async #fetchHighlightTokens(range?: Range): Promise<HighlightTokens> {
		let text = this.#document.getText();
		if (range) { text = text.substring(this.#document.offsetAt(range.start)); }
		const highlightInspectResponse = await this.#router.inspectHighligh(text);
		const parsedToken = highlightInspectResponse[0].highlight.split(',');
		return new HighlightTokens(parsedToken, this.#document, range);
	}

	static positionInRange(pos: Position, range: Range): boolean {
		const compare = (a: Position, b: Position): number => {
			if (a.line < b.line) { return -1; };
			if (a.line > b.line) { return 1; };
			if (a.character < b.character) { return -1; };
			if (a.character > b.character) { return 1; };
			return 0;
		};
		return compare(pos, range.start) >= 0 && compare(pos, range.end) <= 0;
	}
}

// MARK: LspController

export class LspController {
	#connection;
	#documents;
	#lspDocuments = new Map<string, LspDocument>();
	get connection() { return this.#connection; }
	get documents() { return this.#documents; }
	get lspDocuments() { return this.#lspDocuments; }
	shortid = "routeroslsp";
	hasConfigurationCapability = false;
	hasWorkspaceFolderCapability = false;
	hasDiagnosticRelatedInformationCapability = false;

	constructor(connection: Connection) {
		this.#connection = connection;
		this.#documents = new TextDocuments(TextDocument);
		this.#documents.onDidOpen(async e => this.#lspDocuments.set(e.document.uri, await LspDocument.create(e.document, this)));
		this.#documents.onDidChangeContent(async e => this.#lspDocuments.set(e.document.uri, await LspDocument.create(e.document, this)));
		this.#documents.onDidClose(e => this.#lspDocuments.delete(e.document.uri));
		this.#connection.onDidChangeConfiguration(_ => this.#lspDocuments.clear());
		this.#documents.listen(connection);
		// hover
		connection.onHover(this.onHoverHandler(this));
		// "Problems" (diagnostics)
		connection.languages.diagnostics.on(this.handleDiagnostics(this));
		// completion
		connection.onCompletion(this.onCompletionHandler(this));
		connection.onCompletionResolve(this.onConmpletionResolveHandler(this));
		// semantic tokens
		connection.onRequest("textDocument/semanticTokens/full", this.generateSemanticTokens(this));
		// symbols (variabls)
		connection.onDocumentSymbol(this.onDocumentSymbols(this));

		connection.onInitialize((params): InitializeResult => {
			let serverCapabilities = LspController.getServerCapabilities(params);
			if (LspController.hasCapability('workspaceFolders', params)) {
				serverCapabilities = { ...serverCapabilities, ...{ workspace: { workspaceFolders: { supported: true } } } };
			};
			return { capabilities: serverCapabilities };
		});
	}

	async getLspDocument(uri: DocumentUri, refresh = false): Promise<LspDocument> {
		let lspdocument;
		if (!refresh) {
			lspdocument = this.#lspDocuments.get(uri);
			if (lspdocument) {
				return lspdocument;
			}
		} else {
			this.#lspDocuments.delete(uri);
		}
		// if not, force loading from document cache
		const document = this.#documents.get(uri);
		if (document) {
			lspdocument = await LspDocument.create(document, this);
			this.#lspDocuments.set(uri, lspdocument);
			return lspdocument;
		}
		throw new Error(`getLspDocument() failed to get a LspDocument`);
	}

	static start(connection: Connection) {
		return new LspController(connection);
	}

	static hasCapability(capacity: string, params: InitializeParams): boolean {
		const clientCapabilities = params.capabilities;
		switch (capacity) {
			case "configuration": return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.configuration);
			case "workspaceFolders": return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.workspaceFolders);
			case "diagnosticsRelatedInformation": return !!(
				clientCapabilities.textDocument &&
				clientCapabilities.textDocument.publishDiagnostics &&
				clientCapabilities.textDocument.publishDiagnostics.relatedInformation
			);
			default:
				return false;
		}
	}

	// MARK: define server caps

	static getServerCapabilities(parmas: InitializeParams): ServerCapabilities {
		return {
			textDocumentSync: TextDocumentSyncKind.Full,
			semanticTokensProvider: {
				legend: {
					tokenTypes: HighlightTokens.TokenTypes,
					tokenModifiers: [], // optional
				},
				full: { delta: false },
				range: false,
				documentSelector: [
					{ language: "routeros" },
					{ language: "rsc" },
					{ scheme: "file", pattern: "**∕*.rsc" },
					{ language: "routeroslsp" },
				],
			},
			completionProvider: {
				resolveProvider: true,
				triggerCharacters: [":", "=", "/", " ", "$"],
			},
			diagnosticProvider: {
				interFileDependencies: false,
				workspaceDiagnostics: false,
			},
			hoverProvider: true,
			workspace: {
				workspaceFolders: {
					supported: LspController.hasCapability('workspaceFolders', parmas)
				}
			},
			documentSymbolProvider: true
		};
	}

	sendDiagnostics = (diagnostics: PublishDiagnosticsParams) => this.connection.sendDiagnostics(diagnostics);

	// MARK: handle hover

	onHoverHandler = (controller: LspController) => async (params: TextDocumentPositionParams): Promise<Hover | undefined> => {
		//	const pos = params.position;
		//	const doc = contoller.documents.get(params.textDocument.uri);
		//	const offset = doc.offsetAt(pos);
		const lspdoc = controller.lspDocuments.get(params.textDocument.uri);
		if (lspdoc) {
			const highlightTokens = await lspdoc.higlightTokens;
			const highlightToken = highlightTokens.atPosition(params.position);
			if (highlightToken) {
				const hoverInfo = `\`${highlightToken.token}\` highlight <small>from ${lspdoc.offsetAt(highlightToken.range.start)} to ${lspdoc.offsetAt(highlightToken.range.end)}</small>`;
				return {
					contents: {
						kind: "markdown",
						value: hoverInfo,
					},
					range: highlightToken.range
				};
			} else { return undefined; }
		} else {
			throw new Error("onHoverHandler failed, no document");
		}
	};

	// MARK: handle diagnostics

	handleDiagnostics = (controller: LspController) => async (params: DocumentDiagnosticParams) => {
		const document = await controller.getLspDocument(params.textDocument.uri, true);
		if (document) {
			const diags = await document.diagnostics();
			if (!diags) { throw new Error("bad document in handleDiagnostics()"); }
			return {
				kind: DocumentDiagnosticReportKind.Full,
				items: diags,
			} satisfies DocumentDiagnosticReport;
		} else {
			throw new Error("handleDiagnostics failed, no document");
		}

	};

	// MARK: handle completion

	onConmpletionResolveHandler = (_: LspController) => (item: CompletionItem): CompletionItem => {
		return item;
	};

	onCompletionHandler = (controller: LspController) => async (params: CompletionParams) => {
		controller.connection.console.log(
			`=> onCompletion() fired for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`
		);

		const document = controller.lspDocuments.get(params.textDocument.uri);
		if (!document) {
			controller.connection.console.warn(
				`connection.onCompletion('${params.textDocument.uri}'), cannot return any completion.`
			);
			return [];
		}
		const results: CompletionItem[] = [];
		const completions = await document.completion(params.position);
		if (completions) {
			completions.forEach((item: CompletionInspectResponseItem, index: number) => {
				let kind : CompletionItemKind;
				switch(item.style) {
					case "dir": 
						kind = CompletionItemKind.Folder;
						break;
					case "cmd":
						kind = CompletionItemKind.Method;
						break;
					case "arg":
						kind = CompletionItemKind.Property;
						break;
					case "syntax-meta":
						kind = CompletionItemKind.Operator;
						break;
					case "variable-global":
						kind = CompletionItemKind.Variable;
						break;
					case "variable-local":
						kind = CompletionItemKind.Constant;
						break;
					default:
						kind = CompletionItemKind.Text;
				}
				if (item.show === "true" && item.completion) {
					results.push({
						label: item.completion,
						// TODO: should map 'kind' to proper tokenType - harder than it might seem since it's prospective
						kind: kind,
						data: index,
						insertText: item.completion,
						insertTextFormat: InsertTextFormat.PlainText,
						detail: `${item.text}`,
						//documentation: `pref ${item.preference} offset ${item.offset} style ${item.style}`
					});
				}
			});
			return results;
		} else {
			return results;
		}
	};

	// MARK: handle semantic tokens

	generateSemanticTokens = (controller: LspController) => async (params: SemanticTokensParams): Promise<SemanticTokens | null> => {
		const document = controller.lspDocuments.get(params.textDocument.uri);
		if (!document) {
			throw new Error(`generateSemanticTokens() got no document`);
		}
		const builder = new SemanticTokensBuilder();
		const higlightTokens = await document.higlightTokens;
		if (!higlightTokens || higlightTokens.tokens.length === 0) {
			controller.connection.console.error(
				`generateSemanticTokens() no higlightTokens found: ${document.uri}`
			);
		} else {
			const tokenRanges = higlightTokens.tokenRanges;
			controller.connection.console.log(
				`semanticTokens.on() processing: #tokens ${higlightTokens.tokens.length} #ranges ${tokenRanges.length}`
			);
			tokenRanges.forEach((tokenRange) => {
				if (tokenRange.token !== "none") {
					const pos = tokenRange.range.start;
					builder.push(
						pos.line,
						pos.character,
						document.document.offsetAt(tokenRange.range.end) - document.document.offsetAt(tokenRange.range.start) + 1,
						HighlightTokens.TokenTypes.indexOf(tokenRange.token),
						0
					);
				}
			});
		}
		return builder.build();
	};

	// MARK: handle symbols

	onDocumentSymbols = (controller: LspController) => async (params: DocumentSymbolParams): Promise<SymbolInformation[] | DocumentSymbol[] | undefined | null> => {
		const lspdoc = await controller.getLspDocument(params.textDocument.uri);
		const highlightTokens = await lspdoc.higlightTokens;
		const tokenRanges = highlightTokens.tokenRanges;
		//const symbols : DocumentSymbol[] = [];
		const symbolsVariableTree: DocumentSymbol[] = [];
		tokenRanges.filter(t => ['variable-global', 'variable-local'].includes(t.token)).forEach(f => {
			// fix end range
			// TODO: end range is one char short, maybe just here, also could be newlines, or, logic error (range inclusivity)
			const range = f.range;
			const vartype = f.token.split("-")[1];
			range.end.character = range.end.character + 1;
			const name = lspdoc.document.getText(range);
			const docsym = {
				kind: vartype === 'global' ? SymbolKind.Variable : SymbolKind.Constant,
				name: name,
				range: range,
				selectionRange: range,
				detail: `:${vartype} on line ${range.start.line}`,
				children: []
			};
			const existing = symbolsVariableTree.filter((i) => i.name == name);
			if (existing.length === 1 && docsym.kind === existing[0].kind) {
				if (existing[0].children) {
					existing[0].children.push(docsym);
				} else { 
					existing[0].children = [docsym]; 
				};
				const replaceIndex = symbolsVariableTree.findIndex(i => i.name == name);
				symbolsVariableTree[replaceIndex] = existing[0];
			} else {
				symbolsVariableTree.push(docsym);
			}
		});
		

		return [...symbolsVariableTree];
	};
};







//const controller = LspController.start({} as Connection);

/*


	onDocumentDidDidClose((change: TextDocumentChangeEvent<TextDocument>) => {
		connection.console.log(
			`=> onDidClose() fired for ${change.document.uri}`
		);
		documentSettings.delete(change.document.uri);
		inspectHighlightCache.delete(change.document.uri);
	});

onDocumentDidChangeContent(async (change) => {
	connection.console.log(
		`=> onDidChangeContent(${change.document.uri}) updating... `
	);
	inspectHighlightCache.delete(change.document.uri);
	/*
	
	*/
/*
getDocumentInspectHighlights(change.document);
//connection.languages.diagnostics.refresh()
connection.languages.semanticTokens.refresh();
});

onDocumentDidOpen(async (change: TextDocumentChangeEvent<TextDocument>) => {
connection.console.log(
	`=> onDidOpen() fired for ${change.document.uri}`
);
inspectHighlightCache.delete(change.document.uri);
/*connection.sendDiagnostics({
  uri: change.document.uri,
  diagnostics: await validateTextDocument(change.document),
});*//*
//connection.languages.diagnostics.refresh()
connection.languages.semanticTokens.refresh();
});
*/
