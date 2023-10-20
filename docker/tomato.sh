#!/bin/sh

NAME="tomato"
VERSION=0.7.3

REPODIR="${REPODIR:-/var/pkg/${NAME}}"
REPOLST="${REPODIR}/${NAME}.pkglist"
REPODB="${NAME}"
KEYSLST="${REPODIR}/${NAME}.gpglist"

PKGDIR="$(echo ~tomato)/.cache/pikaur/pkg"
PKGGLOB=*.pkg.tar.*

MIRRORLIST="$(echo ~tomato)/mirrorlist"
MAKEPKGCONF="$(echo ~tomato)/makepkg.conf"
CONFIGDIR="$(echo ~tomato)/.config/pacman/"

AURFLAGS="${PACFLAGS:- --print-commands --needed --noprogressbar --noconfirm}"
AUR="/usr/bin/pikaur"

# -- Colors
ERROR="\033[0;31m"
HINT="\033[1;33m"
RESET="\033[0m"

# -- Utilities
_echo2(){
	>&2 echo $@
}

_error(){
	if test -t 2;
	then
		_echo2 -n -e ${ERROR}
		_echo2 $*
		_echo2 -n -e ${RESET}
	else
		_echo2 $*
	fi
	exit 1
}

_warn(){
	if test -t 2;
	then
		_echo2 -n -e ${ERROR}
		_echo2 $*
		_echo2 -n -e ${RESET}
	else
		_echo2 $*
	fi
}

_hint(){
	if test -t 2;
	then
		_echo2 -n -e ${HINT}
		_echo2 $*
		_echo2 -n -e ${RESET}
	else
		_echo2 $*
	fi
}

_join(){
	sep=$1; shift
	for arg in $@;
	do
		echo -n ${arg}
		shift;
		break;
	done
	for arg in $@;
	do
		echo -en ${sep}
		echo -n ${arg}
	done
}

_hasstr(){
	test -n "$1" -a -n "$2" &&
	echo $1 | grep -F -e "$2" -q -s
}


_safere(){
	for arg in $@;
	do
		echo "$arg" | sed -E "s/([|(){}.+*\\\\ ]|\\[|\\])/\\\\&/g"
	done
}

_noopts(){
	for arg in $@;
	do
		case $arg in
			# AUR authorized flags
			--aur)
				shift;;
			--noedit)
				shift;;
			--edit)
				shift;;
			-k|--keepbuild)
				shift;;
			--rebuild)
				shift;;
			--mflags=*)
				shift;;
			--dynamic-users)
				shift;;
			--devel)
				shift;;
			--nodiff)
				shift;;
			# PACMAN flags
			--confirm)
				shift;;
			--debug)
				shift;;
			# PIKAUR ignore
			pikaur)
				shift;; # not installable
			-*)
				_error "Not supported flag ${arg}"
				;;
			*)
				echo "$arg";;
		esac
	done
}

_opts(){
	for arg in $@;
	do
		case $arg in
			# AUR authorized flags
			--edit)
				_haseditor && echo "$arg";;
			-*)
				echo "$arg";;
			*)
				shift;;
		esac
	done
}

_aurflags(){
	editmode=0
	for arg in $@;
	do
		case $arg in
			--confirm|--edit)
				editmode=1
				break;;
			*)
				;;
		esac
	done

	for flag in ${AURFLAGS};
	do
		case $flag in
			--noedit|--noconfirm)
				test ${editmode} -eq 0 && echo "$flag";;
			*)
				echo "$flag";;
		esac
	done
}

_rmglob(){
	test ! -d $1 || find "$1" -xdev -type f -name "$2" -delete
}

_copymod(){
	test -n "$1" -a -n "$2"     &&
	chmod --reference="$1" "$2" &&
	chown --reference="$1" "$2"
}

_tomato(){
	user=tomato
	group=$(/bin/id -g -n tomato)
	sudo -u "${user}" -g "${group}" -- $@
}

_aur(){
	_tomato "${AUR}" $@
}

_fixup(){
	# Fixup __init__.py root only read permission
	# as the pikaur will be run by the local user
	# this is valid and required;
	# pikaur jumps to a sudo command by itself after.
	#
	# This a packaging issue found with pikaur 1.4.
	#
	# This command should only be run within the
	# Dockerfile.
	find /usr/lib/python* -name pikaur -type d \
		-exec chmod a+r -- "{}/__init__.py" \;
}

_editor(){
	# Set the EDITOR for editing the PKGBUILDs
	# from pikaur;
	#
	# The first argument can be written as
	# "package-name:command-name"
	#
	# This command should only be run within the
	# Dockerfile.
	test -n "$1" || return

	package=$( echo $1 | cut -d : -f 1)
	editor=$( echo $1 | cut -d : -s -f 2)
	tomato_editor="$*"
	shift
	commands="$*"
	test -n "$commands" && commands=" ${commands}"

	if test -z "${editor}"
	then
		editor="${package}"
		package=$(basename "${package}")
	fi

	if test -n "${package}" -a -n "${editor}";
	then
		editor="${editor}${commands}"
		_hint "Installing ${package} as EDITOR=\"${editor}\""
		(	_aur -Sy ${AURFLAGS} ${package}               && \
			echo EDITOR=\"${editor}\" >> /etc/environment
		) || (
			_warn "TOMATO_EDITOR=\"${tomato_editor}\" can not be" \
			      "used as EDITOR=\"${editor}\".";
			_warn "To use another \$EDITOR override your "        \
			      "TOMATO_EDITOR= configuration.";
			_warn "${NAME^} will not accept the --edit flag."
		)
	fi

	echo TOMATO_EDITOR=\"${tomato_editor}\" >> /etc/environment
}

_haseditor(){
	if test -z "${EDITOR}"
	then
		_warn "No \$EDITOR is set, the --edit flag will be ignored."
		_warn "Use the TOMATO_EDITOR= configuration key to set one."
		return 1
	else
		return 0
	fi
}

_checkeditor(){
	if test "${TOMATO_EDITOR}" != "${_TOMATO_EDITOR}";
	then
		_hint "The TOMATO_EDITOR=\"${_TOMATO_EDITOR}\" " \
		      "configuration is not yet applied, " \
		      "re-run the command with the --rebuild-image flag." \
		      "The actual configuration is " \
		      "TOMATO_EDITOR=\"${TOMATO_EDITOR}\"."
	fi
}

_volfile(){
	volume="$1"
	target="$2"

	if test -f "${volume}" -a ! -L "${target}";
	then
		ln --symbolic           \
		   --force              \
		   --target="${target}" \
		   "${volume}"
	fi
}

# -- Environment
_mirrorlist(){
	_volfile "${MIRRORLIST}" "/etc/pacman.d/" 
}

_upgrade(){
	_mirrorlist                                   &&
	_aur -Sy   $AURFLAGS                          &&
	_aur -S    $AURFLAGS archlinux-keyring pikaur &&
	_aur -Syuu $AURFLAGS                          &&
	# cleanup pikaur build for futher package registration
	_rmglob "$PKGDIR" "$PKGGLOB"
}

# -- Packages List
_listpkgs(){
	touch -a -- "${REPOLST}"                  &&
	_join '\n' $@                              |
	cat -- ${REPOLST} -                        |
	LC_ALL="C" sort -u --
}

_pinpkgs(){
	touch -a -- "${REPOLST}"                  &&
	_join '\n' $@                              |
	cat -- ${REPOLST} -                        |
	LC_ALL="C" sort -u -- > "${REPOLST}.tmp"  &&
	_copymod "${REPOLST}" "${REPOLST}.tmp"    &&
	mv -f -T -- "${REPOLST}.tmp" "${REPOLST}" &&
	cat -- "${REPOLST}"
}

_unpinpkgs(){
	pkgs=$( _join '|' $(_safere $@) )

	test -f "${REPOLST}"                      &&
	cat     -- "${REPOLST}"                    |
	sed -E "s/^${pkgs}$//"                     |
	awk 'NF' > "${REPOLST}.tmp"               &&
	_copymod "${REPOLST}" "${REPOLST}.tmp"    &&
	mv -f -T -- "${REPOLST}.tmp" "${REPOLST}" &&
	cat -- "${REPOLST}"
}

_knownpkgs(){
	pkgs=$( _join '|' $(_safere $@) )
	cat -- "${REPOLST}" | grep -x -E -- "$pkgs"
}

_unknownpkgs(){
	( _listdb | awk '{print $1 }'; _listpkgs ) |
	LC_ALL="C" sort | LC_ALL="C" uniq -u |
	grep -f "${REPOLST}" -
}

# -- Package Install
_makepkgconf(){
	_volfile "${MAKEPKGCONF}" "${CONFIGDIR}"
}

_makepkgs(){
	# FIXME tomato doesn't support GPG at all right now,
	#       we can't sign our built images,
	#       and can't check unknown GPK keys;
	#       for now we are ignoring GPG signatures with makepkg.
	allbuilt=0
	pkgs=$(_noopts $@)
	opts=$(_opts $@)
	aurflags=$(_aurflags $opts)
	_checkeditor
	_makepkgconf
	for pkg in $pkgs;
	do
		_hint ${NAME^} building $pkg...
		_aur -S $aurflags --mflags=--skippgpcheck $opts $pkg
		ret=$?
		if test 0 -ne $ret
		then
			_warn Unable to build $pkg
			allbuilt=$ret
		fi
	done
	return $allbuilt
}

_pushpkgs(){
	ls -1 "$PKGDIR/"$PKGGLOB |
	xargs cp --no-clobber --target-directory="$REPODIR/" --
}

_cleanpkgs(){
	paccache --remove --keep 1 --quiet --cachedir "${REPODIR}"
}

_delpkgs(){
	_rmglob "$REPODIR" "$PKGGLOB"
}

# -- Database
_updatedb(){
	repose --files             \
	       --gzip              \
	       --root="${REPODIR}" \
	       --pool="${REPODIR}" \
	       "${REPODB}"
}

_removedb(){
	repose --files             \
	       --gzip              \
	       --root="${REPODIR}" \
	       --pool="${REPODIR}" \
	       --drop              \
	       "${REPODB}" -- $@
}

_listdb(){
	test -f "${REPODIR}/${REPODB}.db" &&
	repose --root="${REPODIR}" \
	       --pool="${REPODIR}" \
	       --list              \
	       "${REPODB}"
}

_statusdb(){
	if test -z "$1";
	then
		_hint -n "Checking packages status"
	fi

	IFS=$'\n' packages=( $(_listdb; _unknownpkgs) )
	for package in ${packages[@]};
	do
		IFS=$' ' package=(${package})
		pkgname=${package[0]}
		pkgver=${package[1]}

		aurlog=$(_aur -Si --aur --name-only "${pkgname}")
		aurscm=$(echo ${pkgname}       | grep -o -E -e '-(git|hg|svn|bzr)$')
		aurversion=$(echo ${aurlog}    | grep Version     | awk -F ': ' '{printf $2}')
		auroutofdate=$(echo ${aurlog}  | grep Out-of-date | awk -F ': ' '{printf $2}')
		aurmaintainer=$(echo ${aurlog} | grep Maintainer  | awk -F ': ' '{printf $2}')
		
		pkgstatus="" # Up-to-date
		if test -z "${aurversion}";
		then
			pkgstatus="Removed"
		elif test "${aurmaintainer}" = "None";
		then
			pkgstatus="Orphan"
		elif test "${auroutofdate}" != "None";
		then
			pkgstatus="Out-of-date"
		elif test -n "${aurscm}";
		then
			pkgstatus="Rolling-update"
		elif test -z "${pkgver}"
		then
			pkgstatus="Waiting-update"
		elif test "${aurversion}" != "${pkgver}"
		then
			pkgstatus="Pending-update"
		fi

		if test -n "$1"
		then
			_hasstr "${pkgstatus}" "$1" && echo "${pkgname}"
		else
			_hint -n "."
			echo "${pkgstatus},${pkgname},${pkgver},${aurversion}"
		fi
	done

	if test -z "$1";
	then
		_hint "."
	fi

	return 0 # FIXME: success detection
}

_reportdb(){
	header="Status,Package Name,${NAME^} Version,AUR Version"
	_statusdb | column --table --table-columns "${header}" --separator ','
}

# -- Tomato
_version(){
	pacman=$(/usr/bin/pacman -Q pacman)
	pikaur=$(/usr/bin/pacman -Q pikaur)
	repose=$(/usr/bin/pacman -Q repose)
	cat << EOF

               000000000                
           0000         0000            
        000                 000         
      00                       00       
    000000000             00000000      
   00        00          0        00    
  00           0        0          00   
 00 ......                   ..... 000  
 00.........                ....... 00  
00  ......                    .....  00 
000                                0000 
0 100                           000   0 
0 1  0000                    0000 1   0 
0 1   1  00000000000000000000     1   0 
0 1   1      1       1      1     1   0 
0 1   1      1       1      1     1  00 
 01   1      1       1      1     1 00  
  0   1      1       1      1     100   
   0  1      1       1      1     00    
    001      1       1      1    00   ${NAME^} v${VERSION}
      00     1       1      1   00    Copyright (C) 2018-2023 'aji'
        00   1       1      0000      Licensed under GPLv3
          0000       1   0000           
              00000000000             ${pacman^}
	                              ${pikaur^}
				      ${repose^}

EOF
}

# -- Main
usage(){
	____=$(printf "%${#NAME}s" "")
	cat <<EOF
usage: ${NAME} [<options>] <operation> [...]

operations:
  ${NAME} add      <package(s)>  # add a package to the maintained list;
  ${NAME} del      <package(s)>  # remove a package from the maintained list;
  ${NAME} refresh [<package(s)>] # update ${NAME} repository;
  ${NAME} sweep                  # rebuild ${NAME} repository,
  ${____}                        # will remove non building or non existing 
  ${____}                        # packages;
  ${NAME} list    [all|status|split]
  ${____}                        # list maintained packages;
  ${NAME} search   <package(s)>  # search an AUR package;
  ${NAME} version [all|number]   # show version ${VERSION};
  ${NAME} (usage|help)           # this help message.

  ${NAME} -Syu                   # or any other short variant (-Syuu, -Suy,
  ${____}                        # ...), will update the ${NAME} repository,
  ${____}                        # and the host system.

options:
  ${NAME} --rebuild-image        # build or rebuild the ${NAME} Docker image;
  ${NAME} --default-mirrors      # use the default mirrors of the base Docker
  ${____}                        # image, when building or rebuilding the
  ${____}                        # ${NAME} Docker image;
  ${NAME} --remove-image         # remove the ${NAME} Docker image;
  ${NAME} --tomato-config <path> # path to custom ${NAME} config;
  ${NAME} --edit                 # prompt to edit PKGBUILDs or build files;
  ${NAME} --remote-update        # update ${NAME} from the remote pre-built
  ${____}                        # package.


  ${NAME^} v${VERSION}
EOF
}

version(){
	case "$1" in
		number)
			echo "${VERSION}";;
		all)
			/usr/bin/uname    -a &&
			/usr/bin/pacman   -V &&
			_aur              -V &&
			/usr/bin/repose   -V &&
			_version;;
		*)
			_version;;
	esac
}

list(){
	case "$1" in
		all)
			_listdb;;
		status)
			_reportdb;;
		split)
			_unknownpkgs;;
		"")
			_listpkgs;;
		*)
			_statusdb "$1";;
	esac
}

search(){
	_aur -Ss --aur -- $@
}

add(){
	pkgs=$(_noopts $@) || exit $?
	_upgrade           &&
	_makepkgs $@       &&
	_pinpkgs  $pkgs    &&
	_pushpkgs          &&
	_cleanpkgs         &&
	_updatedb
}

del(){
	pkgs=$(_knownpkgs $@)
	test -z "$pkgs"  ||
	_unpinpkgs $pkgs &&
	_removedb  $pkgs &&
	_hint The packages are no more maintained \
	      but the packages files have not been cleaned up, \
	      call \"$NAME sweep\" to clear caches, \
	      remove unused dependencies and leftover packages.
}

refresh(){
	pkgs=$(_noopts $@) || exit $?
	opts=$(_opts $@)
	updt=$(_statusdb update)
	if test -z "$pkgs";
	then
		pkgs=$updt
	else
		pkgs=$(_join '\n' $@ | LC_ALL="C" sort | LC_ALL="C" uniq -d)
	fi
	_upgrade                          &&
	(_makepkgs $opts $pkgs  || true)  &&
	(_pushpkgs 2> /dev/null || true)  &&
	_cleanpkgs                        &&
	_updatedb
}

sweep(){
	pkgs=$(_listpkgs)
	opts=$(_opts $@)
	_upgrade                          &&
	_delpkgs                          &&
	(_makepkgs $opts $pkgs  || true)  &&
	(_pushpkgs 2> /dev/null || true)  &&
	_updatedb
}

main(){
	case $1 in
		list|-Q)
			shift; list $@
			;;
		search|-Ss)
			shift; search $@
			;;
		add|-S)
			shift; add $@
			;;
		del|-R)
			shift; del $@
			;;
		refresh|-S*y*u|-S*u*y)
			shift; refresh $@
			;;
		sweep)
			shift; sweep $@
			;;
		version|-V)
			version $2
			;;
		usage|help|-h|--help)
			usage
			;;
		exec) # not documented
			shift; _tomato $@
			;;
		fixup) # not documented
			shift; _fixup $@
			;;
		editor) # not documented
			shift; _editor $@
			;;
		status) # not documented - shortcut for `list status`
			list $@
			;;
		*)
			echo "Operation \"${NAME} $1\" not supported," \
			     "see \"${NAME} help\"."; return 1
			;;
	esac
}

main $@
exit $?
