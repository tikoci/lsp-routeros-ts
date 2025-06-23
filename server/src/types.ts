
export interface InspectRequest {
	input?: string | undefined;
	path?: string | string[] | undefined;
	request: string;
	// not useful but present
	'.proplist'?: string | string[] | undefined | null;
	'.query'?: string[] | undefined | null;
	'as-value'?: boolean | string | undefined | null;
	'without-paging'?: boolean | string | undefined | null;
}

export type InspectResponse = HighlightInspectResponseItem[] | SyntaxInspectResponseItem[] | CompletionInspectResponseItem[] | ChildInspectResponseItem[];

export interface HighlightInspectResponseItem {
	highlight: string,
	type: string
}

export interface SyntaxInspectResponseItem {
	nested: number | string | undefined,
	nonorm: boolean | string | undefined,
	symbol: string | undefined,
	'symbol-type': string | undefined,
	text: string | undefined,
	type: string
}

export interface CompletionInspectResponseItem {
	completion: string | undefined,
	offset: number | string | undefined,
	preference: number | string | undefined,
	show: boolean | string | undefined,
	style: number | string | undefined,
	text: string | undefined,
	type: string
}

export interface ChildInspectResponseItem {
	name: string,
	'node-type': string,
	type: string
}
