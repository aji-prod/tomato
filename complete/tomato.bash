# Command name completion for Tomato
function _tomato() {
	local cur prev pprev flags commands
	flags=("--tomato-config"
	       "--remove-image"
	       "--rebuild-image"
	       "--help"
	       "-Syu")
	commands=("add"
	          "del"
		  "refresh"
		  "list"
		  "search"
		  "sweep"
		  "version"
		  "help"
		  "usage")
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD - 1]}
	pprev=${COMP_WORDS[COMP_CWORD - 2]}

	case $prev  in
		--tomato-config)
			COMPREPLY=( $(compgen -f -- $cur) )
			return 0
			;;
		list)
			COMPREPLY=( $(compgen -W "all" -- $cur) \
				    $(compgen -W "status" -- $cur) )
			return 0
			;;
		version|-V)
			COMPREPLY=( $(compgen -W "number" -- $cur) )
			return 0
			;;
		usage|help|-h|--help)
			return 0
			;;
		-*)
			# continue
			;;
		*)
			if test ${COMP_CWORD} -gt 1 -a \
				"${pprev}" != "--tomato-config";
			then
				return 0
			fi
			;;
	esac

	case $cur in
		--tomato-config=)
			COMPREPLY=( $(compgen -f -- $cur) )
			return 0
			;;
		-*)
			COMPREPLY=( $(compgen -W "${flags[*]}" -- $cur) )
			return 0
			;;
		*)
			COMPREPLY=( $(compgen -W "${commands[*]}" -- $cur) )
			return 0
			;;
	esac
}
complete -o default -F _tomato tomato
