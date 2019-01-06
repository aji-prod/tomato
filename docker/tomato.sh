#!/bin/sh

NAME="tomato"
VERSION=0.1.0

REPODIR="${REPODIR:-/var/pkg/${NAME}}"
REPOLST="${REPODIR}/${NAME}.pkglist"
REPODB="${NAME}"
KEYSLST="${REPODIR}/${NAME}.gpglist"

PKGDIR="$(echo ~tomato)/.cache/pikaur/pkg"
PKGGLOB=*.pkg.tar.*

AURFLAGS="${PACFLAGS:- --needed --noprogressbar --noconfirm}"
AUR="/usr/bin/pikaur"


# -- Utilities
_error(){
	echo $* 1>&2
	exit 1
}

_hint(){
	echo $* 1>&2
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
				;;
		esac
	done
	echo $@
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

# -- Environment
_upgrade(){
	_aur -Sy   $AURFLAGS        &&
	_aur -S    $AURFLAGS pikaur &&
	_aur -Syuu $AURFLAGS        &&
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

# -- Package Install
_makepkgconf(){
	if test -f "${HOME}/makepkg.conf" -a \
	        ! -L "${XDG_CONFIG_HOME}/pacman/makepkg.conf";
	then
		mkdir -p "${XDG_CONFIG_HOME}/pacman"    &&
		ln --symbolic                            \
		   --force                               \
		   --target="${XDG_CONFIG_HOME}/pacman/" \
		   "${HOME}/makepkg.conf"
	fi
}

_makepkgs(){
	# FIXME tomato doesn't support GPG at all right now,
	#       we can't sign our built images,
	#       and can't check unknown GPK keys;
	#       for now we are ignoring GPG signatures with makepkg.
	_makepkgconf
	_aur -S $AURFLAGS --mflags=--skippgpcheck $@
}

_pushpkgs(){
	ls -1 "$PKGDIR/"$PKGGLOB |
	xargs cp --no-clobber --target-directory="$REPODIR/" --
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

	IFS=$'\n' packages=( $(_listdb) )
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
      00     1       1      1   00    Copyright (C) 2018 'aji'
        00   1       1      0000      Licensed under GPLv3
          0000       1   0000           
              00000000000             ${pacman^}
	                              ${pikaur^}
				      ${repose^}

EOF
}

# -- Main
usage(){
	cat <<EOF
usage: ${NAME} [<options>] <operation> [...]

operations:
  ${NAME} add      <package(s)>  # add a package to the maintained list;
  ${NAME} del      <package(s)>  # remove a package from the maintained list;
  ${NAME} refresh [<package(s)>] # update ${NAME} repository;
  ${NAME} list    [all|status]   # list maintained packages;
  ${NAME} search   <package(s)>  # search an AUR package;
  ${NAME} version [number]       # show version ${VERSION};
  ${NAME} (usage|help)           # this help message.

options:
  ${NAME} --rebuild-image        # build or rebuild the ${NAME} Docker image;
  ${NAME} --remove-image         # remove the ${NAME} Docker image;
  ${NAME} --tomato-config <path> # path to custom ${NAME} config.

  ${NAME^} v${VERSION}
EOF
}

version(){
	case "$1" in
		number)
			echo "${VERSION}";;
		*)
			/usr/bin/uname    -a &&
			/usr/bin/pacman   -V &&
			"${AUR}" -V          &&
			/usr/bin/repose   -V &&
			_version;;
	esac
}

list(){
	case "$1" in
		all)
			_listdb;;
		status)
			_reportdb;;
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
	_updatedb
}

del(){
	pkgs=$(_knownpkgs $@)
	test -z "$pkgs"  ||
	_unpinpkgs $pkgs &&
	_removedb  $pkgs &&
	_hint The packages are no more maintained \
	      but the packages files have not been cleaned up, \
	      call \"$NAME refresh\" to clear caches \
	      and remove unused dependencies.
}

refresh(){
	_noopts $@ || exit $?
	addpkgs=$@
	updpkgs=$(_statusdb update)
	_upgrade                          &&
	_makepkgs $updpkgs $addpkgs       &&
	_pinpkgs  $addpkgs                &&
	_delpkgs                          &&
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
		refresh|-Syu)
			shift; refresh $@
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
		*)
			echo "Operation \"${NAME} $1\" not supported," \
			     "see \"${NAME} help\"."; return 1
			;;
	esac
}

main $@
exit $?
