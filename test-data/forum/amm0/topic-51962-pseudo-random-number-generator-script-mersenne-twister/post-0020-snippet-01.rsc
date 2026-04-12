# Source: https://forum.mikrotik.com/t/pseudo-random-number-generator-script-mersenne-twister/51962/20
# Topic: Pseudo Random Number Generator Script (Mersenne Twister)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# based on https://www.random.org/clients/http/
# from comment here http://forum.mikrotik.com/t/pseudo-random-number-generator-script-mersenne-twister/51962/1
:global RNDORGINT
:set RNDORGINT do={
    # params
    :local lmin [:tonum $min]
    :local lmax [:tonum $max]
    :local lbase [:tonum $base]
    # consts
    :local lnum 1
    :local lformat "plain"
    :local lcol "1"
    :local lrnd "new"
    # defaults
    :if ([:typeof $lmin]!="num") do={:set lmin 0}
    :if ([:typeof $lmax]!="num") do={:set lmax 1000}
    :if ([:typeof $lbase]!="num" ) do={:set lbase 10}
    :if (!([:tostr $lbase]~("2|8|10|16"))) do={:error "Base must be 2, 8, 10, or 16"}
    # setup url
    :local url "https://www.random.org/integers/?"
    :set url "$($url)min=$lmin&max=$lmax&base=$lbase"
    :set url "$($url)&num=$lnum&col=$lcol&format=$lformat&rnd=$lrnd"
    :local headers "Content-Type: text/plain"
    # now get number from random.org using fetch
    :local resp [/tool fetch url=$url http-header-field=$headers output=user as-value]
    :local rndasstr ($resp->"data")
    # return it as string
    :return $rndasstr
}
