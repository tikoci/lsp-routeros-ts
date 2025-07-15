// import * as path from "path";
// import * as fs from "fs";
import {
  ExtensionContext,
  env,
  UIKind,
} from 'vscode'
import { LanguageClientOptions } from 'vscode-languageclient'

export const packageJsonInfo = (context: ExtensionContext): [string, string] => [context.extension.packageJSON.config.shortid, context.extension.packageJSON.displayName]

export function getVSCodeType() {
  if (env.uiKind === UIKind.Web) {
    // Running in VSCode for Web (e.g., vscode.dev or github.dev)
    console.log('Running in VSCode Web')
  }
  else {
    // Running in VSCode Desktop
    console.log('Running in VSCode Desktop')
  }
}

export function getLanguageClientOptions(): LanguageClientOptions {
  return {
    documentSelector: [
      { scheme: 'vscode-notebook-cell', language: 'routeros' },
      { language: 'routeros' },
      { language: 'rsc' },
      { scheme: 'file', pattern: '**∕*.rsc' },
      { scheme: 'file', pattern: '**∕*.tikbook' },
      { scheme: 'file', pattern: '**∕*.md.rsc' },
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
}
