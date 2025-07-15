/* ---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *-------------------------------------------------------------------------------------------- */

// @ts-check
'use strict'

// @ts-check
/** @typedef {import('webpack').Configuration} WebpackConfig **/

// eslint-disable-next-line @typescript-eslint/no-require-imports
const path = require('path')

/** @type WebpackConfig */
const browserClientConfig = {
  context: path.join(__dirname, 'client'),
  mode: 'none',
  target: 'webworker', // web extensions run in a webworker context
  entry: {
    'extension.web': './src/extension.web.ts',
  },
  output: {
    filename: '[name].js',
    path: path.join(__dirname, 'client', 'dist'),
    libraryTarget: 'commonjs',
    devtoolModuleFilenameTemplate: '../[resource-path]',
  },
  resolve: {
    mainFields: ['module', 'main'],
    extensions: ['.ts', '.js'], // support ts-files and js-files
    alias: {},
    fallback: {
      util: require.resolve('util/'),
      path: require.resolve('path-browserify'),
    },
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'ts-loader',
          },
        ],
      },
    ],
  },
  externals: {
    vscode: 'commonjs vscode', // ignored because it doesn't exist
  },
  performance: {
    hints: false,
  },
  devtool: 'nosources-source-map',
}

/** @type WebpackConfig */
const browserServerConfig = {
  context: path.join(__dirname, 'server'),
  mode: 'none',
  target: 'webworker', // web extensions run in a webworker context
  entry: {
    'server.web': './src/server.web.ts',
  },
  output: {
    filename: '[name].js',
    path: path.join(__dirname, 'server', 'dist'),
    libraryTarget: 'var',
    library: 'serverExportVar',
    devtoolModuleFilenameTemplate: '../[resource-path]',
  },
  resolve: {
    mainFields: ['browser', 'module', 'main'],
    extensions: ['.ts', '.js'], // support ts-files and js-files
    alias: {},
    fallback: {
      path: false, // require.resolve("path-browserify"),
      util: false, // require.resolve("util/"),
      stream: false, // require.resolve("stream-browserify"),
      https: false, // require.resolve("https-browserify") ,
      http: false, // require.resolve("stream-http"),
      url: false, // require.resolve("url/"),
      buffer: false, // require.resolve("buffer/"),
      // fs: require.resolve("fs/"),
    },
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'ts-loader',
          },
        ],
      },
    ],
  },
  externals: {
    vscode: 'commonjs vscode', // ignored because it doesn't exist
    fs: 'commonjs',
  },
  performance: {
    hints: false,
  },
  devtool: 'nosources-source-map',
}

module.exports = [browserClientConfig, browserServerConfig]
