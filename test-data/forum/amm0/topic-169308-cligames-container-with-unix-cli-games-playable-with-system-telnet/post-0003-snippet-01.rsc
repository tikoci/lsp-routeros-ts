# Source: https://forum.mikrotik.com/t/cligames-container-with-unix-cli-games-playable-with-system-telnet/169308/3
# Topic: CLIGAMES - container with UNIX CLI games & playable with /system/telnet
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

FROM alpine

# since games use ncurses libary for colors/control, a TERM must be set 
ENV TERM xterm
ENV HOSTNAME WOPR
# note: this may need to change on a running container depending on terminal

# add hostname & packages, specifically add "bsd-games"
RUN apk update \
 && apk add --no-cache busybox-extras gawk mandoc mandoc-apropos ncurses \
 && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing bsd-games bsd-games-doc nbsdgames nbsdgames-doc 

# add users that map various games in bsd-games games 
RUN adduser -D joshua && echo -e "\n\n" | passwd joshua \
  && for game in `apk info -L bsd-games | awk -F "/" '/bin/ {print $3}'`; do adduser -D $game -s /usr/bin/$game && echo -e "\n\n" | passwd $game; done \
  && for game in `apk info -L nbsdgames | awk -F "/" '/bin/ {print $3}'`; do adduser -D $game -s /usr/bin/$game && echo -e "\n\n" | passwd $game; done

# create "help" alias to man & add command for "list-games"
RUN echo 'PS1="WOPR > "' >> /etc/profile \
    && echo 'alias help=man' >> /etc/profile \
    && echo 'alias list=list-games' >> /etc/profile \
    && echo "#!/bin/sh" > /usr/bin/list-games \
    && echo "/usr/bin/apropos -s 6 ." >> /usr/bin/list-games \ 
    && echo "" >> /usr/bin/list-games \ 
    && echo "echo \"Use 'help <game_name>' to see additional information about a game\"" >> /usr/bin/list-games \ 
    && echo "echo \"Use 'list' to see the list of games\"" >> /usr/bin/list-games \ 
    && echo "" >> /usr/bin/list-games \ 
    && chmod +x /usr/bin/list-games

# update the "message-of-the-day" shown at login
RUN echo "" > /etc/motd \
  && echo "GREETINGS PROFESSOR FALCON!" >> /etc/motd \
  && echo "DO YOU WANT TO PLAY A GAME?" >> /etc/motd \
  && echo "" >> /etc/motd \
  && /usr/bin/apropos -s 6 . >> /etc/motd \
  && echo "Use 'help <game_name>' to see additional information about a game" >> /etc/motd \ 
  && echo "Use 'list' to see the list of games" >> /etc/motd \ 
  && echo "" >> /etc/motd

# listen for telnet to make games "network aware"
CMD /usr/sbin/telnetd -p 23 -b 0.0.0.0 -l /bin/login -F
