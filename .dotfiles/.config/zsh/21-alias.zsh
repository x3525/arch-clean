alias cal='LC_TIME=tr_TR.UTF-8 cal'
alias cat='bat --style=plain --paging=never --theme="Solarized (dark)"'
alias diff='diff --color=auto'
alias grep='grep --color=auto --exclude-dir={.git,.venv,venv}'
alias ls='ls --color=auto'
alias rm='trash-put --verbose'
alias test-speaker='speaker-test --channels=2 --test=wav --nloops=1'
alias xc='xsel --clipboard --input'
alias xp='xsel --clipboard --output'

for i ({3..9})
    alias -g ${(l:i::.:)}=${(l:$(((i-1)*3))::../:)}
