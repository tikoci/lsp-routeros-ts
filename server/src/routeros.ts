
import { ChildInspectResponseItem, CompletionInspectResponseItem, HighlightInspectResponseItem, SyntaxInspectResponseItem } from './types';
import axios from 'axios';

export interface RouterOSInitialization {
	baseUrl: string;
	username: string;
	password: string;
}

export class RouterOSDevice {
	version = "unknown";
	#settings;
	constructor(settings: RouterOSInitialization) {
		this.#settings = settings;
	}
	get connectionDetails() { return this.#settings; }
	get config() { return this.version; }
	get httpClient() {
		const client = axios.create({
			baseURL: `${this.#settings.baseUrl}/rest`,
			timeout: 10000,
			headers: { 'Content-Type': 'application/json' },
			withCredentials: true,
			auth: {
				username: this.#settings.username,
				password: this.#settings.password
			}
		});
		client.interceptors.response.use(
			response => response, // Pass through if the response is successful
			error => {
				if (error.response?.status === 401) {
					console.error('Unauthorized (401): Please log in.');
				} else if (error.response?.status === 500) {
					console.error('Server error (500): Try again later.');
				} else {
					console.error('An error occurred:', error.message);
				}
				return Promise.reject(error); // Propagate the error
			}
		);
		return client;
	}
	async _inspect<T>(request :string, input :string, path? :string) {
		return await this.httpClient.post<T[]>(
			'/console/inspect', {
			request: request,
			input: input,
			path: path
		}).then(resp => resp.data);
	} 
	inspectHighligh = (input :string, path? :string) => {
		return this._inspect<HighlightInspectResponseItem>('highlight', input.replace(/([\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])/g, '-'), path);
	};
	inspectSyntax = (input :string, path? :string) => {
		return this._inspect<SyntaxInspectResponseItem>('syntax', input, path);
	};
	inspectCompletion = (input :string, path? :string) => {
		return this._inspect<CompletionInspectResponseItem>('completion', input, path);
	};
	inspectChild = (input :string, path? :string) => {
		return this._inspect<ChildInspectResponseItem>('child', input, path);
	};
}

export class RouterOSScriptParser {
	source  = "";
	device : RouterOSDevice; 
	constructor(source :string, device :RouterOSDevice) {
		this.source = source;
		this.device = device;
	}
}