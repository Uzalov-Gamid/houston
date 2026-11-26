# Shared terminal palette; sourced after the existing user settings.
set -g fish_color_normal e3dccb
set -g fish_color_command e3dccb --bold
set -g fish_color_keyword 98c4ba --bold
set -g fish_color_param 98c4ba
set -g fish_color_quote b5b07a
set -g fish_color_redirection 98c4ba --bold
set -g fish_color_end 98c4ba
set -g fish_color_error e4836a --bold
set -g fish_color_operator 98c4ba
set -g fish_color_escape e5c15a
set -g fish_color_comment a9998b
set -g fish_color_autosuggestion a9998b
set -g fish_color_selection --background=334741 f1ead8
set -g fish_color_search_match --background=334741 f1ead8
set -g fish_pager_color_prefix 98c4ba --bold
set -g fish_pager_color_completion e3dccb
set -g fish_pager_color_description a9998b
set -g fish_pager_color_selected_background --background=334741
# One palette for cd completion, cdi, history and file search.
set -gx FZF_DEFAULT_OPTS '--color=bg:-1,fg:#d6c8ab,bg+:#334741,fg+:#f1ead8,gutter:-1,hl:#98c4ba,hl+:#cfe3d6,pointer:#98c4ba,marker:#b5b07a,prompt:#98c4ba,info:#a9998b,spinner:#98c4ba,header:#a9998b,border:#59473e,separator:#59473e,scrollbar:#8a7567,query:#e3dccb --pointer=▎ --marker=✓'
