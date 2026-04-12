# Source: https://forum.mikrotik.com/t/new-rndnum-command-doesnt-work-guessing-it-should-generate-a-random-number/151589/1
# Topic: New ":rndnum" command doesn't work (& guessing it should generate a random number)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{:local results {""}; :for from=1 to=100 counter=x do={:set ($results->$x) [:rndnum from=$x to=100]}; :put $results;}
;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;41;42;43;44;45;46;47;48;49;50;51
;52;53;54;55;56;57;58;59;60;61;62;63;64;65;66;67;68;69;70;71;72;73;74;75;76;77;78;79;80;81;82;83;84;85;86;87;88;89;90;91;92;93;94;95;96;97;98;99
;100
