#!/bin/sh

NAME="tomato"
VERSION=0.1.0

REPODIR="${REPODIR:-/var/pkg/${NAME}}"
REPOLST="${REPODIR}/${NAME}.pkglist"
REPODB="${NAME}"
KEYSLST="${REPODIR}/${NAME}.gpglist"

PKGDIR="$HOME/.cache/pikaur/pkg"
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

# -- Environment
_upgrade(){
	"$AUR" -Sy   $AURFLAGS        &&
	"$AUR" -S    $AURFLAGS pikaur &&
	"$AUR" -Syuu $AURFLAGS        &&
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
	mv -f -T -- "${REPOLST}.tmp" "${REPOLST}" &&
	cat -- "${REPOLST}"
}

_unpinpkgs(){
	pkgs=$( _join '|' $(_safere $@) )

	test -f "${REPOLST}"        &&
	cat     -- "${REPOLST}"      |
	sed -E "s/^${pkgs}$//"       |
	awk 'NF' > "${REPOLST}.tmp" &&
	mv -f -T -- "${REPOLST}.tmp" "${REPOLST}" &&
	cat -- "${REPOLST}"
}

_knownpkgs(){
	pkgs=$( _join '|' $(_safere $@) )
	cat -- "${REPOLST}" | grep -x -E "$pkgs"
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
	"${AUR}" -S $AURFLAGS --mflags=--skippgpcheck $@
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
	       "${REPODB}" $@
}

_listdb(){
	repose --root="${REPODIR}" \
	       --pool="${REPODIR}" \
	       --list              \
	       "${REPODB}"
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
  ${NAME} list    [all]          # list maintained packages;
  ${NAME} search   <package(s)>  # search an AUR package;
  ${NAME} version                # show version v${VERSION};
  ${NAME} (usage|help)           # this help message.

options:
  ${NAME} --rebuild-image        # build or rebuild the ${NAME} Docker image;
  ${NAME} --tomato-config <path> # path to custom ${NAME} config.

  ${NAME^} v${VERSION}
EOF
}

version(){
	/usr/bin/uname    -a &&
	/usr/bin/pacman   -V &&
	"${AUR}" -V          &&
	/usr/bin/repose   -V &&
	_version
}

list(){
	test "x$1" = "xall" && _listdb || _listpkgs
}

search(){
	"${AUR}" -Ss --aur -- $@
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
	pkgs=$(_listpkgs $@)
	_upgrade           &&
	_makepkgs $pkgs    &&
	_pinpkgs  $pkgs    &&
	_delpkgs           &&
	_pushpkgs          &&
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
			version
			;;
		usage|help|-h|--help)
			usage
			;;
		exec) # not documented
			shift; $@
			;;
		*)
			echo "Operation \"${NAME} $1\" not supported," \
			     "see \"${NAME} help\"."; return 1
			;;
	esac
}

main $@
exit $?
