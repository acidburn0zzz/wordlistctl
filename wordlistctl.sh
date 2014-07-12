#!/bin/sh
################################################################################
#                                                                              #
# wordlistctl.sh - fetch and install wordlists                                 #
#                                                                              #
# FILE                                                                         #
# wordlistctl.sh                                                               #
#                                                                              #
# DATE                                                                         #
# 2013-12-07                                                                   #
#                                                                              #
# DESCRIPTION                                                                  #
# This script can fetch and install wordlists from various sites.              #
#                                                                              #
# AUTHORS                                                                      #
# teitelmanevan@gmail.com                                                      #
# noptrix@nullsecurity.net                                                     #
# nrz@nullsecurity.net                                                         #
#                                                                              #
################################################################################
# TODO: download by name
# TODO: mix

# wordlistctl.sh version
VERSION="wordlistctl v0.1"

# verbose mode - default: quiet
VERBOSE="/dev/null"

# debug mode - default: off
DEBUG="/dev/null"

# wordlist base directory
LIST_DIR="/usr/share/wordlists"

LIST_FILE="$LIST_DIR/wordlists.lst"

# user agent string for curl
USERAGENT="wordlistctl/$VERSION"

# default wordlist list
#    name|size (human readable)|url
URL_FILE="/usr/share/wordlistctl/wordlists.lst"

# use colors
COLORS=true

# clean up downloaded archives after extraction
CLEAN=true

# print line in blue
blue()
{
    msg="$*"

    if $COLORS ; then
        echo "`tput setaf 4``tput bold`${msg}`tput sgr0`"
    else
        echo "$msg"
    fi
}

# print line in yellow
yellow()
{
    msg=$*

    if $COLORS ; then
        echo "`tput setaf 3``tput bold`$msg`tput sgr0`"
    else
        echo "$msg"
    fi
}

# print line in green
green()
{
    msg=$*

    if $COLORS ; then
        echo "`tput setaf 2``tput bold`$msg`tput sgr0`"
    else
        echo "$msg"
    fi
}

# print line in red
red()
{
    msg=$*

    if $COLORS ; then
        echo "`tput setaf 1``tput bold`$msg`tput sgr0`"
    else
        echo "$msg"
    fi
}

# print warning
warn()
{
    red "[!] WARNING: $*"
}

# print error and exit
err()
{
    red "[-] ERROR: $*"
    exit 1
}

# get an entry from a list
get_entry()
{
    grep -v '^#' | sed -n "${1}p"
}

entry_get_name()
{
    cut -d'|' -f1
}

entry_get_size()
{
    cut -d'|' -f2
}

entry_get_url()
{
    cut -d'|' -f3
}

# list wordlists
list()
{
    blue "[*] available wordlists"
    echo -e 'ID\tNAME\tSIZE\tURL'
    get_entry '1,$' < $LIST_FILE | sed 's/|/\t/g' | nl -w1
}

# download wordlist archives from chosen sites
fetch()
{
    local url=`get_entry $1 < $LIST_FILE | entry_get_url`
    local name=`get_entry $1 < $LIST_FILE | entry_get_name`
    local dir=$LIST_DIR/$name
    blue "downloading and extracting package $name to $dir..."
    (
    mkdir -p "$dir"
    cd "$dir"
    if ! curl -A "$USERAGENT" -s "$url" 2> /dev/null ; then
        err 'download failed.'
    fi |
    case "$url" in
        *.tar.gz|*.tgz) tar xz ;;
        *.tar.xz) tar xJ ;;
        *.tar.bz2|*.tbz2) tar xj ;;
        *.tar) tar x ;;
        *.zip) bsdtar -xvf- ;;
    esac 2> /dev/null
    # TODO: rar
    # TODO: test zip
    # TODO: 7zip
    )

    # remove container directories
    while [ `ls "$dir" | wc -l` -eq 1 ] ; do
        mv "$dir"/*/* "$dir"
        rmdir "$dir"/* 2> /dev/null
    done
}

# usage and help
usage()
{
    echo "usage:"
    echo ""
    echo "  wordlistctl.sh -f <arg> | <misc>"
    echo ""
    echo "options:"
    echo ""
    echo "  -f <num>    - download and extract a wordlist package"
    echo "                ? to list wordlists"
    echo "  -o <dir>    - wordlist directory (default: /usr/share/wordlists)"
    echo "  -l <file>   - wordlist list"
    echo "                (default: $LIST_FILE)"
    echo "  -n          - turn off colors"
    echo "  -v          - verbose mode (default: off)"
    echo "  -d          - debug mode (default: off)"
    echo ""
    echo "misc:"
    echo ""
    echo "  -V      - print version and exit"
    echo "  -h      - print this help and exit"

    exit
}

# leet banner, very important
banner()
{
    yellow "--==[ wordlistctl by {paraxor,noptrix,nrz}@blackarch.org ]==--"
}

# check argument count
check_argc()
{
    if [ $# -lt 1 ] ; then
        err "-H for help and usage"
    fi
}

# check if required arguments were selected
check_args()
{
    blue "[*] checking arguments" > $VERBOSE 2>&1

    if [ -z "$job" ] ; then
        usage
    fi

    if [ "$job" = fetch ] && [ ! -f "$LIST_FILE" ] ; then
        err "could not find url file ($LIST_FILE)"
    fi
}

# parse command line options
get_opts()
{
    while getopts f:u:s:w:lo:b:L:cnvdVh flags ; do
        case $flags in
            f)
                package=$OPTARG
                job=fetch
                ;;
            l)
                job=list
                ;;
            o)
                LIST_DIR=$OPTARG
                ;;
            L)
                LIST_FILE=$OPTARG
                ;;
            n)
                COLORS=0
                ;;
            v)
                VERBOSE="/dev/stdout"
                ;;
            d)
                DEBUG="/dev/stdout"
                ;;
            V)
                echo "$VERSION"
                exit
                ;;
            h)
                usage
                ;;
            *)
                err "WTF?! mount /dev/brain"
                ;;
        esac
    done
}

main()
{
    check_argc "$@"
    get_opts "$@"
    banner
    check_args "$@"

    case "$job" in
        fetch)
            fetch "$package"
            clean
            ;;
        list)
            list
            ;;
        *)
            err "WTF?! mount /dev/brain"
            ;;
    esac

    blue "[*] game over"
}

main "$@"
